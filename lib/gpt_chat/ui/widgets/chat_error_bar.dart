import 'package:flutter/material.dart';

import 'chat_scope.dart';

/// Dismissible banner for the last failure, with a retry shortcut.
class ChatErrorBar extends StatelessWidget {
  const ChatErrorBar({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            Icon(Icons.error_outline, size: 18, color: scheme.onErrorContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: scheme.onErrorContainer),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: ChatScope.of(context).chat.retryLast,
              child: const Text('Retry'),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: ChatScope.of(context).chat.clearError,
              tooltip: 'Dismiss',
            ),
          ],
        ),
      ),
    );
  }
}
