import 'package:flutter/material.dart';

import 'models/val_artifact.dart';

/// Progress row shown while an animation is generated (20–60s).
class ArtifactStatusLine extends StatelessWidget {
  const ArtifactStatusLine({super.key, required this.status});

  final ArtifactStatus status;

  static const _labels = {
    ArtifactStatus.queued: 'Queued',
    ArtifactStatus.running: 'Generating animation',
    ArtifactStatus.generating: 'Generating animation',
    ArtifactStatus.narrating: 'Recording narration',
    ArtifactStatus.ready: 'Ready',
    ArtifactStatus.failed: 'Failed',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFailed = status == ArtifactStatus.failed;

    return Row(
      children: [
        SizedBox(
          width: 14,
          height: 14,
          child:
              isFailed
                  ? Icon(
                    Icons.error_outline,
                    size: 14,
                    color: theme.colorScheme.error,
                  )
                  : const CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 8),
        Text(_labels[status]!, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
