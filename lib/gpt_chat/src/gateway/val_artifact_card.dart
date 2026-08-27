import 'package:flutter/material.dart';

import 'models/val_artifact.dart';
import 'artifact_status_line.dart';
import 'artifact_scope.dart';
import 'val_scene_player.dart';

/// Inline card for a `genui{...}` animation tag. Registers the artifact on
/// first build, then follows it to ready.
class ValArtifactCard extends StatefulWidget {
  const ValArtifactCard({super.key, required this.initial});

  /// Artifact as announced in the reply — id, name, frame, status and token.
  final ValArtifact initial;

  @override
  State<ValArtifactCard> createState() => _ValArtifactCardState();
}

class _ValArtifactCardState extends State<ValArtifactCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ArtifactScope.of(context).store.track(widget.initial);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scope = ArtifactScope.of(context);

    return ListenableBuilder(
      listenable: scope.store,
      builder: (context, _) {
        final artifact = scope.store.byId(widget.initial.id) ?? widget.initial;
        return _Card(artifact: artifact, builder: scope.builder);
      },
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.artifact, this.builder});

  final ValArtifact artifact;
  final ValArtifactBuilder? builder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // A Material ancestor is required: the card is rendered inside a text span.
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.movie_outlined,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      artifact.name,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (artifact.isReady)
                builder?.call(context, artifact) ??
                    _ReadyPoster(artifact: artifact)
              else ...[
                AspectRatio(
                  aspectRatio: artifact.frame.aspectRatio,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ArtifactStatusLine(status: artifact.status),
                if (artifact.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      artifact.error!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The default ready state: a poster that plays the scene when tapped.
///
/// A host can still replace this entirely with `ArtifactScope.builder` — to
/// present the scene its own way, or to keep it out of a build that should not
/// carry a player.
class _ReadyPoster extends StatelessWidget {
  const _ReadyPoster({required this.artifact});

  final ValArtifact artifact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: artifact.frame.aspectRatio,
          child: Material(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => showValScene(context, artifact),
              child: Center(
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    size: 30,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          // The narration is what the scene is about, so the first line of it
          // makes a better caption than the word "Animation".
          artifact.narrations.isEmpty
              ? 'Tap to play'
              : artifact.narrations.first.text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Narration plus source, for a host that wants the scene's content without a
/// player. Not used by default; kept because it is the only way to see what a
/// scene says without playing it.
// ignore: unused_element
class _ReadyPreview extends StatelessWidget {
  const _ReadyPreview({required this.artifact});

  final ValArtifact artifact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final narration in artifact.narrations)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(narration.text, style: theme.textTheme.bodySmall),
          ),
        if (artifact.script != null) ...[
          const SizedBox(height: 6),
          Text('VAL script', style: theme.textTheme.labelMedium),
          const SizedBox(height: 4),
          // Kept non-interactive: the card lives inside a text span, where
          // tappable children conflict with the paragraph's semantics.
          Container(
            width: double.infinity,
            height: 160,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              child: Text(
                artifact.script!,
                style: const TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
