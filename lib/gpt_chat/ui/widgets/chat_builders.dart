import 'package:flutter/material.dart';

import '../../data/models/chat_message.dart';
import '../../data/models/chat_session.dart';
import '../controller/chat_controller.dart';
import '../controller/chat_message_pair.dart';

/// Builds a piece of chrome from the controller alone.
typedef ChatWidgetBuilder = Widget Function(
  BuildContext context,
  ChatController controller,
);

/// Builds one exchange in the transcript.
typedef ChatPairBuilder = Widget Function(
  BuildContext context,
  ChatController controller,
  ChatMessagePair pair,
  int index,
  bool isLast,
);

/// Builds a single message.
typedef ChatMessageBuilder = Widget Function(
  BuildContext context,
  ChatController controller,
  ChatMessage message,
  bool isLast,
);

/// Builds the divider between exchanges.
typedef ChatSeparatorBuilder = Widget Function(
  BuildContext context,
  ChatController controller,
  int index,
);

/// Builds the failure banner.
typedef ChatErrorBuilder = Widget Function(
  BuildContext context,
  ChatController controller,
  String message,
);

/// Builds one row in the session list.
typedef ChatSessionTileBuilder = Widget Function(
  BuildContext context,
  ChatController controller,
  ChatSession session,
  bool isActive,
);

/// Every replaceable part of the chat UI.
///
/// Leave a builder null to keep the default. Each one receives the same
/// [ChatController], which carries both the current state and the actions
/// (`onSend`, `onModelChoose`, `onStop`, `onRetry`, `onNewSession`, …), so a
/// custom widget never has to reach past its arguments.
///
/// ```dart
/// GptChat(
///   config: config,
///   builders: ChatBuilders(
///     input: (context, controller) => MyComposer(
///       text: controller.input,
///       canSend: controller.canSend,
///       onSend: controller.onSend,
///       onStop: controller.onStop,
///     ),
///     question: (context, controller, message, isLast) =>
///         MyQuestion(message.content),
///   ),
/// )
/// ```
///
/// Builders are grouped by where they sit: the outer frame, the transcript, and
/// the composer.
@immutable
class ChatBuilders {
  const ChatBuilders({
    this.scaffold,
    this.appBar,
    this.background,
    this.drawer,
    this.sessionTile,
    this.modelSelector,
    this.body,
    this.messageList,
    this.pair,
    this.separator,
    this.question,
    this.answer,
    this.typingIndicator,
    this.empty,
    this.loading,
    this.error,
    this.input,
    this.sendButton,
    this.jumpToLatest,
  });

  // ----------------------------------------------------------------- frame ---

  /// Replaces the whole screen. Everything below is then yours to place; the
  /// other builders are ignored unless you call them.
  final ChatWidgetBuilder? scaffold;

  /// The bar overlaid on top of the transcript.
  final ChatWidgetBuilder? appBar;

  /// Painted behind the transcript, below every other layer.
  final ChatWidgetBuilder? background;

  /// The session drawer. Return null-producing builder content to omit it.
  final ChatWidgetBuilder? drawer;

  /// One row of the session list inside the default drawer.
  final ChatSessionTileBuilder? sessionTile;

  /// The model picker shown in the default app bar.
  final ChatWidgetBuilder? modelSelector;

  // ------------------------------------------------------------ transcript ---

  /// Everything between the app bar and the composer, including the empty and
  /// loading states.
  final ChatWidgetBuilder? body;

  /// The scrollable transcript itself.
  final ChatWidgetBuilder? messageList;

  /// One question/answer exchange.
  final ChatPairBuilder? pair;

  /// The gap between exchanges.
  final ChatSeparatorBuilder? separator;

  /// A user message.
  final ChatMessageBuilder? question;

  /// An assistant message.
  final ChatMessageBuilder? answer;

  /// Shown while a reply has been requested but no token has arrived.
  final ChatWidgetBuilder? typingIndicator;

  /// Shown instead of the transcript before the first message.
  final ChatWidgetBuilder? empty;

  /// Shown while sessions are being restored.
  final ChatWidgetBuilder? loading;

  /// The failure banner.
  final ChatErrorBuilder? error;

  // -------------------------------------------------------------- composer ---

  /// The composer.
  final ChatWidgetBuilder? input;

  /// The send / stop button inside the default composer.
  final ChatWidgetBuilder? sendButton;

  /// The affordance shown while the transcript is scrolled away from the
  /// latest message.
  final ChatWidgetBuilder? jumpToLatest;

  /// A copy with the non-null builders of [other] layered on top.
  ChatBuilders merge(ChatBuilders? other) {
    if (other == null) return this;
    return ChatBuilders(
      scaffold: other.scaffold ?? scaffold,
      appBar: other.appBar ?? appBar,
      background: other.background ?? background,
      drawer: other.drawer ?? drawer,
      sessionTile: other.sessionTile ?? sessionTile,
      modelSelector: other.modelSelector ?? modelSelector,
      body: other.body ?? body,
      messageList: other.messageList ?? messageList,
      pair: other.pair ?? pair,
      separator: other.separator ?? separator,
      question: other.question ?? question,
      answer: other.answer ?? answer,
      typingIndicator: other.typingIndicator ?? typingIndicator,
      empty: other.empty ?? empty,
      loading: other.loading ?? loading,
      error: other.error ?? error,
      input: other.input ?? input,
      sendButton: other.sendButton ?? sendButton,
      jumpToLatest: other.jumpToLatest ?? jumpToLatest,
    );
  }
}
