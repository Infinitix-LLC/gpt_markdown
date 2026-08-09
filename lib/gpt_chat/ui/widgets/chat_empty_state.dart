import 'package:flutter/material.dart';

/// Placeholder shown before the first message.
class ChatEmptyState extends StatelessWidget {
  const ChatEmptyState({super.key, this.title = 'Ask anything', this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.forum_outlined, size: 44, color: theme.colorScheme.outline),
          const SizedBox(height: 12),
          Text(title, style: theme.textTheme.titleMedium),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}
