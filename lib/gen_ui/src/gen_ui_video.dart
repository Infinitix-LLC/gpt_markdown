import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'gen_ui_shells.dart';
import 'gen_ui_values.dart';

/// `video`: an inline network video with play/pause and a scrub bar.
///
/// Initialisation is asynchronous and can fail (bad URL, unsupported codec,
/// no platform implementation), so the widget always shows *something*: a
/// spinner while loading and a message tile on failure, never a silent gap in
/// the middle of an answer.
class GenVideo extends StatefulWidget {
  const GenVideo({super.key, required this.attributes});

  final Map<String, dynamic> attributes;

  @override
  State<GenVideo> createState() => _GenVideoState();
}

class _GenVideoState extends State<GenVideo> {
  VideoPlayerController? _controller;
  Future<void>? _initialization;
  String? _error;

  String? get _url =>
      genUiString(widget.attributes['url'] ?? widget.attributes['src']);

  @override
  void initState() {
    super.initState();
    _createController();
  }

  @override
  void didUpdateWidget(covariant GenVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.attributes != widget.attributes) {
      _disposeController();
      _createController();
    }
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  void _createController() {
    final url = _url;
    final uri = url == null ? null : Uri.tryParse(url);
    if (uri == null) {
      _error = 'No video URL';
      return;
    }

    _error = null;
    final controller = VideoPlayerController.networkUrl(uri);
    _controller = controller;
    _initialization = controller
        .initialize()
        .then((_) {
          if (!mounted) return;
          controller.setLooping(genUiBool(widget.attributes['loop']) ?? false);
          if (genUiBool(widget.attributes['autoplay']) ?? false) {
            controller.play();
          }
          setState(() {});
        })
        .catchError((Object error) {
          if (!mounted) return;
          setState(() => _error = 'Video could not be loaded');
        });
  }

  void _disposeController() {
    _controller?.dispose();
    _controller = null;
    _initialization = null;
  }

  @override
  Widget build(BuildContext context) {
    final title = genUiString(widget.attributes['title']);
    final height = genUiDouble(widget.attributes['height']);

    if (_error != null) {
      return _VideoNotice(message: _error!, title: title, height: height);
    }

    final controller = _controller!;
    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done ||
            !controller.value.isInitialized) {
          return _VideoNotice(
            title: title,
            height: height,
            child: const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final player = Stack(
          alignment: Alignment.bottomCenter,
          children: [
            VideoPlayer(controller),
            VideoProgressIndicator(controller, allowScrubbing: true),
            Center(child: _PlayPauseButton(controller: controller)),
          ],
        );

        return _VideoFrame(
          title: title,
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: player,
          ),
        );
      },
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  const _PlayPauseButton({required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return IconButton.filledTonal(
          onPressed:
              () => value.isPlaying ? controller.pause() : controller.play(),
          icon: Icon(
            value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          ),
        );
      },
    );
  }
}

class _VideoFrame extends StatelessWidget {
  const _VideoFrame({required this.child, this.title});

  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null && title!.isNotEmpty) ...[
                Text(title!, style: theme.textTheme.titleMedium),
                const SizedBox(height: 16),
              ],
              ClipRRect(borderRadius: BorderRadius.circular(12), child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoNotice extends StatelessWidget {
  const _VideoNotice({this.message, this.title, this.height, this.child});

  final String? message;
  final String? title;
  final double? height;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _VideoFrame(
      title: title,
      child: SizedBox(
        height: height ?? 160,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
          ),
          child:
              child ??
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.videocam_off_outlined,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(message ?? '', style: genUiMutedStyle(theme)),
                  ],
                ),
              ),
        ),
      ),
    );
  }
}
