import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../controller/chat_controller.dart';
import '../controller/chat_message_pair.dart';
import 'chat_scope.dart';
import 'session_answer.dart';
import 'session_layout.dart';
import 'session_question.dart';

/// The default transcript: a forward-scrolling list of question/answer
/// exchanges.
///
/// Two behaviours make it read like a document rather than a message feed:
///
/// **Anchoring.** The last exchange is given a viewport-tall minimum height, so
/// sending a question scrolls it to the top of the screen with the answer
/// growing beneath it — instead of the question sliding off the top as the
/// reply arrives.
///
/// **Following that yields.** While a reply streams the view keeps the newest
/// tokens visible, but the moment the user scrolls up it stops and stays put.
/// Scrolling is never disabled to achieve this — the user is always in control,
/// and a "jump to latest" affordance brings them back.
class SessionTranscript extends StatelessWidget {
  const SessionTranscript({super.key, required this.controller});

  final ChatController controller;

  @override
  Widget build(BuildContext context) {
    final builders = ChatScope.of(context).builders;
    final pairs = controller.pairs;

    if (pairs.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // What the last exchange must be tall enough to fill for the question
        // to land at the top: the viewport minus the space the floating bars
        // already reserve.
        final anchorHeight = math.max(
          0.0,
          constraints.maxHeight -
              SessionLayout.appBarHeight -
              SessionLayout.composerReserve,
        );

        return NotificationListener<ScrollNotification>(
          onNotification: controller.onScrollNotification,
          child: ListView.separated(
            controller: controller.scrollController,
            padding: EdgeInsets.fromLTRB(
              0,
              SessionLayout.appBarHeight + MediaQuery.paddingOf(context).top,
              0,
              SessionLayout.composerReserve,
            ),
            itemCount: pairs.length,
            separatorBuilder: (context, index) {
              final separator = builders.separator;
              if (separator != null) {
                return separator(context, controller, index);
              }
              return SessionLayout.constrain(
                const Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: Divider(height: 10),
                ),
              );
            },
            itemBuilder: (context, index) {
              final pair = pairs[index];
              final isLast = index == pairs.length - 1;

              final custom = builders.pair;
              Widget child = custom != null
                  ? custom(context, controller, pair, index, isLast)
                  : SessionExchange(
                      controller: controller,
                      pair: pair,
                      isLast: isLast,
                    );

              if (isLast) {
                child = ConstrainedBox(
                  constraints: BoxConstraints(minHeight: anchorHeight),
                  child: child,
                );
              }

              return SessionLayout.constrain(child);
            },
          ),
        );
      },
    );
  }
}

/// One question with its answer beneath it.
class SessionExchange extends StatelessWidget {
  const SessionExchange({
    super.key,
    required this.controller,
    required this.pair,
    required this.isLast,
  });

  final ChatController controller;
  final ChatMessagePair pair;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final builders = ChatScope.of(context).builders;
    final answer = pair.answer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: builders.question?.call(
                context,
                controller,
                pair.question,
                isLast,
              ) ??
              SessionQuestion(message: pair.question),
        ),
        if (answer != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: builders.answer?.call(context, controller, answer, isLast) ??
                SessionAnswer(message: answer, isLast: isLast),
          ),
      ],
    );
  }
}
