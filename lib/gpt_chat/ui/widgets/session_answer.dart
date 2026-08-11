import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

import '../../data/models/chat_message.dart';
import 'chat_scope.dart';
import 'session_layout.dart';
import 'typing_dots.dart';

/// The assistant's message: markdown, gen-UI widgets, and the failure notice.
class SessionAnswer extends StatelessWidget {
  const SessionAnswer({
    super.key,
    required this.message,
    this.isLast = false,
  });

  final ChatMessage message;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final scope = ChatScope.of(context);

    // A requested reply with nothing in it yet: show the indicator rather than
    // an empty block, so the send visibly did something.
    if (message.content.isEmpty && message.isStreaming) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Align(alignment: Alignment.centerLeft, child: TypingDots()),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message.content.isNotEmpty)
            GptMarkdown(
              message.content,
              // `incremental` keeps parsing cheap while tokens stream in.
              incremental: message.isStreaming,
              genUiBuilder: (context, payload) => SizedBox(
                width: SessionLayout.contentMaxWidth - 40,
                child: scope.genUi.build(context, payload),
              ),
            ),
          if (message.hasFailed) _FailureNote(error: message.error),
        ],
      ),
    );
  }
}

class _FailureNote extends StatelessWidget {
  const _FailureNote({this.error});

  final String? error;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 16, color: scheme.error),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              error ?? 'Something went wrong.',
              style: TextStyle(color: scheme.error, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
