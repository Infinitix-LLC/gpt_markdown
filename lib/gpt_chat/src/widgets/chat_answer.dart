import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../gpt_markdown.dart';
import '../adapter/chat_message.dart';
import '../builders/chat_slots.dart';
import '../theme/chat_theme.dart';
import 'chat_indicators.dart';
import 'chat_scope.dart';

/// The assistant's message.
///
/// Full column width and no bubble, the way a long reply wants to be read. The
/// parts stack in this order:
///
/// ```
/// [ …answerAbove ]  status  reasoning  text  attachments  error  actions  [ …answerBelow ]
/// ```
///
/// Every one of those is a slot, and `answerAbove` / `answerBelow` are lists, so
/// a host can insert sources, media, citations or tool output without replacing
/// the answer itself.
class ChatAnswer extends StatelessWidget {
  const ChatAnswer({super.key, required this.message, this.isLast = false});

  final ChatMessage message;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final scope = ChatScope.of(context);
    final controller = scope.controller;
    final theme = scope.theme;
    final builders = scope.builders;

    ChatMessagePartSlot part(Widget child) => ChatMessagePartSlot(
      context: context,
      controller: controller,
      theme: theme,
      message: message,
      isLast: isLast,
      child: child,
    );

    // A requested reply with nothing in it yet shows the indicator rather than
    // an empty block, so the send visibly did something.
    //
    // This stands in for the *text*, rather than short-circuiting the whole
    // widget: a host that replaces `answer` has its own header, status line and
    // progress to draw, and those belong on screen from the moment the question
    // is sent — not from the first token.
    final awaiting = message.isAwaitingFirstToken;
    final indicator =
        awaiting
            ? scope.build(
              builders.typingIndicator,
              ChatSlot(
                context: context,
                controller: controller,
                theme: theme,
                child: const ChatTypingDots(),
              ),
            )
            : const SizedBox.shrink();

    final above = [
      for (final section
          in builders.answerAbove ?? const <ChatBuild<ChatMessagePartSlot>>[])
        section(part(const SizedBox.shrink())),
    ];
    final below = [
      for (final section
          in builders.answerBelow ?? const <ChatBuild<ChatMessagePartSlot>>[])
        section(part(const SizedBox.shrink())),
    ];

    final status = scope.build(
      builders.answerStatus,
      part(const SizedBox.shrink()),
    );
    final reasoning = scope.build(
      builders.answerReasoning,
      part(const SizedBox.shrink()),
    );
    final text = scope.build(
      builders.answerText,
      part(
        awaiting
            ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Align(alignment: Alignment.centerLeft, child: indicator),
            )
            : ChatAnswerText(message: message),
      ),
    );
    final attachments = scope.build(
      builders.answerAttachments,
      part(const SizedBox.shrink()),
    );
    final error = scope.build(
      builders.answerError,
      part(
        message.hasFailed
            ? ChatAnswerError(error: message.error)
            : const SizedBox.shrink(),
      ),
    );
    final actions = scope.build(
      builders.answerActions,
      part(ChatAnswerActions(message: message, isLast: isLast)),
    );

    final body = Padding(
      padding: EdgeInsets.symmetric(horizontal: theme.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ...above,
          status,
          reasoning,
          text,
          attachments,
          error,
          actions,
          ...below,
        ],
      ),
    );

    return scope.build(
      builders.answer,
      ChatAnswerSlot(
        context: context,
        controller: controller,
        theme: theme,
        message: message,
        isLast: isLast,
        text: text,
        attachments: attachments,
        actions: actions,
        status: status,
        reasoning: reasoning,
        error: error,
        above: above,
        below: below,
        child: body,
      ),
    );
  }
}

/// The answer body: markdown, LaTeX and any gen-UI widgets it draws.
class ChatAnswerText extends StatelessWidget {
  const ChatAnswerText({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    if (message.content.isEmpty) return const SizedBox.shrink();

    final scope = ChatScope.of(context);
    final theme = scope.theme;
    final builders = scope.builders;

    return GptMarkdown(
      message.content,
      style: theme.answerTextStyle,
      // `incremental` keeps parsing cheap while tokens stream in.
      incremental: message.isStreaming,
      codeBuilder: builders.codeBlock,
      latexBuilder: builders.latex,
      linkBuilder: builders.link,
      imageBuilder: builders.image,
      highlightBuilder: builders.highlight,
      sourceTagBuilder: builders.sourceTag,
      genUiBuilder:
          (context, payload) => SizedBox(
            // Inline widgets sit inside a text span, so they need an explicit width.
            width: theme.contentWidth - theme.gutter * 2,
            child:
                builders.genUi?.call(context, payload) ??
                scope.genUi.build(context, payload),
          ),
    );
  }
}

/// The per-message failure notice.
class ChatAnswerError extends StatelessWidget {
  const ChatAnswerError({super.key, this.error});

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

/// Copy and regenerate, under a finished answer.
///
/// Revealed on hover on pointer platforms and pinned on touch, per
/// `ChatTheme.answerActionsAlwaysVisible`.
class ChatAnswerActions extends StatefulWidget {
  const ChatAnswerActions({
    super.key,
    required this.message,
    this.isLast = false,
  });

  final ChatMessage message;

  /// Regenerate is offered on the newest answer only — re-running an older one
  /// would drop every exchange after it.
  final bool isLast;

  @override
  State<ChatAnswerActions> createState() => _ChatAnswerActionsState();
}

class _ChatAnswerActionsState extends State<ChatAnswerActions> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    if (message.isStreaming || message.content.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final scope = ChatScope.of(context);
    final controller = scope.controller;
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    final pinned = scope.theme.pinnedActions;

    final row = Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Action(
            icon: Icons.content_copy_outlined,
            tooltip: 'Copy',
            color: color,
            onTap: () {
              Clipboard.setData(ClipboardData(text: message.content));
              HapticFeedback.lightImpact();
            },
          ),
          if (controller.capabilities.retry &&
              (widget.isLast || message.hasFailed))
            _Action(
              icon: Icons.refresh_rounded,
              tooltip: 'Regenerate',
              color: color,
              onTap: controller.onRetry,
            ),
        ],
      ),
    );

    if (pinned) return row;

    // Hover-reveal keeps a long transcript quiet, but the row still occupies
    // its space so hovering does not shift the text under the pointer.
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: _hovered ? 1 : 0,
        child: row,
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 17, color: color),
      tooltip: tooltip,
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 34, height: 34),
      padding: EdgeInsets.zero,
    );
  }
}
