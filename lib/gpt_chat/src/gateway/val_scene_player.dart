import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
// The render model carries its own plain-data geometry and palette. Hiding
// those lets Flutter's own Size / Color / Offset / Rect win in widget code,
// while the playback types — the controller, the stream events, paintInto —
// still come through.
import 'package:val_player/val_player.dart'
    hide Color, Colors, Offset, Radius, Rect, Size;

import 'models/val_artifact.dart';
import 'val_stream_client.dart';

/// Plays a ready VAL artifact.
///
/// Painting starts as soon as the first frame arrives rather than after the
/// whole animation has rendered — the render stream *is* the playback, so a
/// scene begins moving while its later frames are still being produced.
///
/// Rendering only. Nothing here decides *whether* an artifact is ready;
/// [ValArtifactCard] owns that, and hands over once the gateway says so.
class ValScenePlayer extends StatefulWidget {
  const ValScenePlayer({
    super.key,
    required this.artifactId,
    this.frame,
    this.background,
    this.onError,
    this.onReady,
  });

  final String artifactId;

  /// Aspect the scene was generated for. Passed through to the renderer so it
  /// composes for the shape it will be shown in.
  final String? frame;

  final Color? background;
  final void Function(String kind, String message)? onError;

  /// Hands back the controller and its audio player.
  ///
  /// Both, not just the controller: pausing the controller freezes the visual
  /// clock and nothing else, so a caller that wants a real pause has to stop
  /// the voice-over itself.
  final void Function(TimelinePlayerController controller, AudioPlayer audio)?
  onReady;

  @override
  State<ValScenePlayer> createState() => _ValScenePlayerState();
}

class _ValScenePlayerState extends State<ValScenePlayer>
    with SingleTickerProviderStateMixin {
  late final TimelinePlayerController _controller;

  // Owned here rather than left to the controller, so a caller can pause the
  // narration with the picture.
  final AudioPlayer _audio = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _controller = TimelinePlayerController.stream(
      events: streamValArtifact(
        artifactId: widget.artifactId,
        frame: widget.frame,
      ),
      vsync: this,
      narrationAudio: DefaultNarrationAudio(_audio),
      autoplay: true,
    )..onError = widget.onError;
    widget.onReady?.call(_controller, _audio);
  }

  @override
  void dispose() {
    _controller.dispose();
    _audio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pixelRatio = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0;
    return ClipRect(
      child: CustomPaint(
        size: Size.infinite,
        painter: _ScenePainter(_controller, pixelRatio, widget.background),
      ),
    );
  }
}

class _ScenePainter extends CustomPainter {
  // Repainting off the controller's own notifier rather than off widget
  // rebuilds: frames arrive faster than setState should be called.
  _ScenePainter(this.controller, this.pixelRatio, this.background)
    : super(repaint: controller.display);

  final TimelinePlayerController controller;
  final double pixelRatio;
  final Color? background;

  @override
  void paint(Canvas canvas, Size size) {
    final frame = controller.currentFrame;
    if (frame == null) {
      final fill = background;
      if (fill != null) {
        canvas.drawRect(Offset.zero & size, Paint()..color = fill);
      }
      return;
    }
    paintInto(
      canvas,
      Offset.zero & size,
      frame,
      referenceCanvasSize: controller.referenceCanvasSize,
      pixelRatio: pixelRatio,
      background: background,
    );
  }

  @override
  bool shouldRepaint(covariant _ScenePainter oldDelegate) => true;
}

/// Opens [artifact] in a sheet and plays it.
///
/// A sheet rather than inline: the card lives inside a text span, where a
/// tappable, animating child fights the paragraph it sits in. Full width also
/// gives the scene room it never has in a chat bubble.
Future<void> showValScene(BuildContext context, ValArtifact artifact) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (_) => ValSceneSheet(artifact: artifact),
  );
}

/// The sheet [showValScene] opens. Public so a host can present it its own way.
class ValSceneSheet extends StatefulWidget {
  const ValSceneSheet({super.key, required this.artifact});

  final ValArtifact artifact;

  @override
  State<ValSceneSheet> createState() => _ValSceneSheetState();
}

class _ValSceneSheetState extends State<ValSceneSheet> {
  static const _canvas = Color(0xFF0E0E12);

  // Bumping this rebuilds the player from scratch, which is what a replay is:
  // the render stream is not seekable, so playing again means asking for it
  // again.
  int _run = 0;
  String? _error;
  TimelinePlayerController? _controller;
  AudioPlayer? _audio;
  bool _paused = false;

  void _replay() {
    setState(() {
      _error = null;
      _paused = false;
      _controller = null;
      _audio = null;
      _run++;
    });
  }

  void _toggle() {
    final controller = _controller;
    if (controller == null) {
      return;
    }
    setState(() {
      if (_paused) {
        controller.play();
        _audio?.resume();
      } else {
        controller.pause();
        // pause() stops the clock, not the voice-over.
        _audio?.pause();
      }
      _paused = !_paused;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final media = MediaQuery.of(context);
    final failed = _error != null;

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.9),
        child: Container(
          decoration: BoxDecoration(
            color: colors.surfaceContainer,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: colors.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
          ),
          padding: EdgeInsets.fromLTRB(16, 12, 16, 20 + media.padding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      widget.artifact.name,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Balances the close button so the title stays centred.
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 12),
              Flexible(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: widget.artifact.frame.aspectRatio,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: DecoratedBox(
                        decoration: const BoxDecoration(color: _canvas),
                        child:
                            failed
                                ? const _SceneFailed()
                                : ValScenePlayer(
                                  key: ValueKey<int>(_run),
                                  artifactId: widget.artifact.id,
                                  frame: widget.artifact.frame.wireName,
                                  background: _canvas,
                                  onError: (_, message) {
                                    if (mounted) {
                                      setState(() => _error = message);
                                    }
                                  },
                                  onReady: (controller, audio) {
                                    _controller = controller;
                                    _audio = audio;
                                  },
                                ),
                      ),
                    ),
                  ),
                ),
              ),
              if (failed) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.error,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!failed)
                    IconButton.filledTonal(
                      icon: Icon(
                        _paused
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded,
                      ),
                      tooltip: _paused ? 'Play' : 'Pause',
                      onPressed: _toggle,
                    ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.replay_rounded),
                    tooltip: 'Replay',
                    onPressed: _replay,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SceneFailed extends StatelessWidget {
  const _SceneFailed();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.error_outline_rounded,
        color: Theme.of(context).colorScheme.error,
      ),
    );
  }
}
