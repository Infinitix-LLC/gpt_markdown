import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../adapter/chat_message.dart';
import '../builders/chat_slots.dart';
import '../controller/chat_controller.dart';
import '../controller/chat_message_pair.dart';
import '../theme/chat_theme.dart';
import 'chat_answer.dart';
import 'chat_question.dart';
import 'chat_scope.dart';

/// The default transcript: a forward-scrolling list of exchanges.
///
/// Two behaviours make it read like a document rather than a message feed.
///
/// **Anchoring.** The last exchange is given a viewport-tall minimum height, so
/// sending a question scrolls it to the top of the screen with the answer
/// growing beneath it — instead of the question sliding off the top as the reply
/// arrives.
///
/// **Following that yields.** While a reply streams the view keeps the newest
/// tokens visible, but the moment the user scrolls up it stops and stays put.
/// Scrolling is never disabled to achieve this — the user is always in control,
/// and [ChatJumpToLatest] brings them back.
class ChatTranscript extends StatelessWidget {
  const ChatTranscript({super.key, required this.controller});

  final ChatController controller;

  @override
  Widget build(BuildContext context) {
    final scope = ChatScope.of(context);
    final theme = scope.theme;
    final builders = scope.builders;
    final pairs = controller.pairs;

    if (pairs.isEmpty) return const SizedBox.shrink();

    ChatSlot plain(Widget child) => ChatSlot(
      context: context,
      controller: controller,
      theme: theme,
      child: child,
    );

    final header = ChatColumn(
      child: scope.build(builders.listHeader, plain(const SizedBox.shrink())),
    );
    final footer = ChatColumn(
      child: scope.build(builders.listFooter, plain(const SizedBox.shrink())),
    );

    // The inset is applied *outside* the LayoutBuilder so the anchor height is
    // measured against the space the transcript actually gets. Measuring first
    // and padding after would make the last exchange taller than the viewport
    // by exactly the inset.
    final content = LayoutBuilder(
      builder: (context, constraints) {
        // What the last exchange must be tall enough to fill for the question to
        // land at the top: the viewport minus what the floating bars reserve.
        final anchorHeight = math.max(
          0.0,
          constraints.maxHeight - theme.barHeight - theme.bottomReserve,
        );

        Widget item(int index) => _Exchange(
          controller: controller,
          pair: pairs[index],
          index: index,
          isLast: index == pairs.length - 1,
          anchorHeight: anchorHeight,
        );

        final list = NotificationListener<ScrollNotification>(
          onNotification: controller.onScrollNotification,
          child: ListView.builder(
            controller: controller.scrollController,
            physics: theme.scrollPhysics,
            padding: EdgeInsets.fromLTRB(
              0,
              theme.barHeight + MediaQuery.paddingOf(context).top,
              0,
              theme.bottomReserve,
            ),
            itemCount: pairs.length,
            // The header and footer ride along with the first and last
            // exchange rather than being list entries of their own: two
            // zero-height items skew `ListView.builder`'s extent estimate,
            // which leaves the scroll position past the real end.
            itemBuilder:
                (context, index) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (index == 0) header,
                    item(index),
                    if (index == pairs.length - 1) footer,
                  ],
                ),
          ),
        );

        return scope.build(
          builders.messageList,
          ChatListSlot(
            context: context,
            controller: controller,
            theme: theme,
            pairs: pairs,
            item: item,
            scrollController: controller.scrollController,
            onScroll: controller.onScrollNotification,
            header: header,
            footer: footer,
            anchorHeight: anchorHeight,
            child: list,
          ),
        );
      },
    );

    return theme.outerPadding == EdgeInsets.zero
        ? content
        : Padding(padding: theme.outerPadding, child: content);
  }
}

/// One exchange, constrained to the reading column and separated from the one
/// before it.
class _Exchange extends StatelessWidget {
  const _Exchange({
    required this.controller,
    required this.pair,
    required this.index,
    required this.isLast,
    required this.anchorHeight,
  });

  final ChatController controller;
  final ChatMessagePair pair;
  final int index;
  final bool isLast;
  final double anchorHeight;

  @override
  Widget build(BuildContext context) {
    final scope = ChatScope.of(context);
    final theme = scope.theme;

    final separator =
        index == 0
            ? const SizedBox.shrink()
            : scope.build(
              scope.builders.separator,
              ChatSeparatorSlot(
                context: context,
                controller: controller,
                theme: theme,
                index: index,
                child:
                    theme.separators
                        ? Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: theme.gapBetweenPairs / 2,
                          ),
                          child: Divider(
                            height: 1,
                            color: theme.separatorColor,
                          ),
                        )
                        : SizedBox(height: theme.gapBetweenPairs),
              ),
            );

    final answer = pair.answer;

    final question = _observed(
      controller,
      pair.question,
      () => ChatQuestion(message: pair.question, isLast: isLast),
    );
    final answerWidget =
        answer == null
            ? const SizedBox.shrink()
            : Padding(
              padding: EdgeInsets.only(top: theme.gapBetweenMessages),
              child: _observed(
                controller,
                answer,
                () => ChatAnswer(message: answer, isLast: isLast),
              ),
            );

    Widget exchange = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [question, answerWidget],
    );

    exchange = scope.build(
      scope.builders.pair,
      ChatPairSlot(
        context: context,
        controller: controller,
        theme: theme,
        pair: pair,
        index: index,
        isLast: isLast,
        question: question,
        answer: answerWidget,
        child: exchange,
      ),
    );

    if (isLast) {
      exchange = ConstrainedBox(
        constraints: BoxConstraints(minHeight: anchorHeight),
        child: exchange,
      );
    }

    return ChatColumn(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [separator, exchange],
      ),
    );
  }

  /// Rebuilds only this message when the adapter reports it as individually
  /// observable — a streaming reply then repaints one bubble, not the list.
  Widget _observed(
    ChatController controller,
    ChatMessage message,
    Widget Function() build,
  ) {
    final listenable = controller.messageListenable(message.id);
    if (listenable == null) return build();

    return ListenableBuilder(
      listenable: listenable,
      builder: (context, _) => build(),
    );
  }
}
