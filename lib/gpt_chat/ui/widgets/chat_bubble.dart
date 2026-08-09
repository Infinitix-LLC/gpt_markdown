import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

import '../../data/models/chat_message.dart';
import '../../data/models/val_artifact.dart';
import '../../data/services/genui_parser.dart';
import 'typing_dots.dart';
import 'val_artifact_card.dart';

/// One message. User text is plain; assistant text renders as markdown, with
/// `genui{...}` tags turned into animation cards.
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
  /// Animations and widgets go through the SAME registry, because the gateway
  /// emits an animation as a `val_scene` widget like any other. Handling only
  /// the animation here — as this did until 2026-08 — silently dropped every
  /// chart, timeline and 3D surface the gateway sent, and a payload holding
  /// both could never render both.
  Widget _buildGenUi(BuildContext context, String payload) {
    // The pre-2026-08 form was a flat object with no widget key to dispatch on,
    // so it cannot go through the registry. Persisted sessions still hold them.
    final legacy = parseGenUiArtifact(payload);
    final child = legacy != null && !payload.contains('val_scene')
        ? ValArtifactCard(initial: legacy)
        : GenUiView(payload: payload, registry: _registry);

    return SizedBox(width: contentWidth, child: child);
  }
}

/// Built once: a registry is a plain map, and rebuilding it per bubble would
/// re-register every builder on every frame of a streaming reply.
final GenUiRegistry _registry = GenUiRegistry.defaults()
  ..register(
    'val_scene',
    (context, model) => ValArtifactCard(initial: ValArtifact.fromJson(model.attributes)),
  );

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
