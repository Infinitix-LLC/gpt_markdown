import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../adapter/chat_message.dart';
import '../builders/chat_slots.dart';
import '../theme/chat_theme.dart';
import 'chat_scope.dart';

/// The user's message.
///
/// Default shape is the familiar one: a right-aligned bubble, inset from the
/// left so it never spans the full column, with a long question collapsed behind
/// a Show more toggle. Pasted material can run for screens, and left whole it
/// would bury the answer it belongs to.
///
/// Set `ChatTheme.showQuestionBubble` false for a bubble-less transcript.
class ChatQuestion extends StatelessWidget {
  const ChatQuestion({super.key, required this.message, this.isLast = false});

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

    final text = scope.build(
      builders.questionText,
      part(ChatQuestionText(message: message)),
    );
    final attachments = scope.build(
      builders.questionAttachments,
      part(const SizedBox.shrink()),
    );
    final actions = scope.build(
      builders.questionActions,
      part(const SizedBox.shrink()),
    );
    final replyQuote = scope.build(
      builders.questionReplyQuote,
      part(const SizedBox.shrink()),
    );

    final body = Padding(
      padding: EdgeInsets.symmetric(horizontal: theme.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [replyQuote, attachments, text, actions],
      ),
    );

    return scope.build(
      builders.question,
      ChatQuestionSlot(
        context: context,
        controller: controller,
        theme: theme,
        message: message,
        isLast: isLast,
        text: text,
        attachments: attachments,
        actions: actions,
        replyQuote: replyQuote,
        child: body,
      ),
    );
  }
}

/// The question's text, bubbled and collapsible.
class ChatQuestionText extends StatefulWidget {
  const ChatQuestionText({super.key, required this.message});

  final ChatMessage message;

  @override
  State<ChatQuestionText> createState() => _ChatQuestionTextState();
}

class _ChatQuestionTextState extends State<ChatQuestionText> {
  static const int _collapsedMaxLines = 3;
  static const double _fadeHeight = 40;

  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final scope = ChatScope.of(context);
    final theme = scope.theme;
    final content = widget.message.content;
    if (content.trim().isEmpty) return const SizedBox.shrink();

    final threshold = theme.collapseThreshold;
    final isLong = threshold > 0 && content.length > threshold;
    final isClipped = isLong && !_expanded;
    final bubbleColor =
        theme.questionBubbleColor ??
        Theme.of(context).colorScheme.surfaceContainerHigh;

    final text = Text(
      content,
      maxLines: isClipped ? _collapsedMaxLines : null,
      overflow: isClipped ? TextOverflow.ellipsis : null,
      style: theme.questionTextStyle,
    );

    if (!theme.bubbleQuestions) {
      return Align(alignment: Alignment.centerLeft, child: text);
    }

    return Align(
      alignment: Alignment.centerRight,
      child: FractionallySizedBox(
        alignment: Alignment.centerRight,
        widthFactor: theme.questionWidthFraction,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            GestureDetector(
              onLongPress: () => _copy(context, content),
              child: Container(
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: theme.questionBubbleRadius,
                ),
                padding: theme.questionBubblePadding,
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    text,
                    if (isClipped)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: _fadeHeight,
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  bubbleColor.withValues(alpha: 0),
                                  bubbleColor,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (isLong)
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _expanded ? 'Show less' : 'Show more',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _copy(BuildContext context, String content) {
    Clipboard.setData(ClipboardData(text: content));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.maybeOf(context)
      ?..clearSnackBars()
      ..showSnackBar(
        const SnackBar(content: Text('Copied'), duration: Duration(seconds: 1)),
      );
  }
}
