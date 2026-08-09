import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

import '../../data/models/chat_message.dart';
import '../../data/services/genui_parser.dart';
import 'chat_scope.dart';
import 'typing_dots.dart';
import 'val_artifact_card.dart';

/// One message. User text is plain; assistant text renders as markdown, with
/// gen-UI directives turned into widgets or animation cards.
class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message});

  final ChatMessage message;

  static const _maxWidthFactor = 0.82;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isUser = message.isUser;

    if (message.isStreaming && message.content.isEmpty) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: Padding(padding: EdgeInsets.all(12), child: TypingDots()),
      );
    }

    final maxWidth = MediaQuery.sizeOf(context).width * _maxWidthFactor;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isUser ? scheme.primaryContainer : scheme.surfaceContainerHighest,
            borderRadius: _radius(isUser),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Content(message: message, isUser: isUser, contentWidth: maxWidth - 28),
              if (message.hasFailed) _FailureNote(error: message.error),
            ],
          ),
        ),
      ),
    );
  }

  BorderRadius _radius(bool isUser) => BorderRadius.only(
    topLeft: const Radius.circular(16),
    topRight: const Radius.circular(16),
    bottomLeft: Radius.circular(isUser ? 16 : 4),
    bottomRight: Radius.circular(isUser ? 4 : 16),
  );
}

class _Content extends StatelessWidget {
  const _Content({required this.message, required this.isUser, required this.contentWidth});

  final ChatMessage message;
  final bool isUser;
  final double contentWidth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = isUser ? scheme.onPrimaryContainer : scheme.onSurface;

    if (message.content.isEmpty) return const SizedBox.shrink();
    if (isUser) return SelectableText(message.content, style: TextStyle(color: color));

    // `incremental` keeps parsing cheap while tokens stream in.
    return GptMarkdown(
      message.content,
      style: TextStyle(color: color),
      incremental: message.isStreaming,
      genUiBuilder: _buildGenUi,
    );
  }

  /// Inline widgets sit inside a text span, so they need an explicit width.
  ///
  /// Everything goes through the one registry, animations included: the gateway
  /// emits an animation as a `val_scene` widget like any other, so a reply
  /// holding an animation AND a chart renders both. `chatGenUiRegistry` is what
  /// puts `val_scene` in there.
  Widget _buildGenUi(BuildContext context, String payload) {
    // Replies from before 2026-08 carried a flat `{"type":"val_artifact"}`
    // payload with no widget key to dispatch on, so they cannot go through the
    // registry. Persisted sessions still hold them.
    final legacy = parseLegacyGenUiArtifact(payload);
    final child = legacy != null
        ? ValArtifactCard(initial: legacy)
        : ChatScope.of(context).genUi.build(context, payload);

    return SizedBox(width: contentWidth, child: child);
  }
}

class _FailureNote extends StatelessWidget {
  const _FailureNote({this.error});

  final String? error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        error ?? 'Something went wrong.',
        style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
      ),
    );
  }
}
