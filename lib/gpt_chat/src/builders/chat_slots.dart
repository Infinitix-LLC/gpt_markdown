import 'package:flutter/material.dart';

import '../adapter/chat_capabilities.dart';
import '../adapter/chat_draft.dart';
import '../adapter/chat_message.dart';
import '../adapter/chat_model_source.dart';
import '../adapter/chat_session.dart';
import '../controller/chat_controller.dart';
import '../controller/chat_message_pair.dart';
import '../theme/chat_theme.dart';

/// The one shape every builder in [ChatBuilders] takes.
typedef ChatBuild<S extends ChatSlot> = Widget Function(S slot);

/// What a builder is handed.
///
/// Two things make customization progressive rather than all-or-nothing:
///
/// * [child] is the widget the package would have built. Return it wrapped and
///   you have decorated; ignore it and you have replaced.
/// * Slot subtypes carry the **parts** that composed [child], already built.
///   Replace the transcript and you still get the bubbles; replace a bubble and
///   you still get its text, actions and attachments. There is no point where a
///   small change forces you to rebuild everything beneath it.
///
/// ```dart
/// ChatBuilders(
///   answer: (s) => Column(children: [...s.above, s.text, MyCitations(), s.actions]),
///   messageList: (s) => AnimatedList(
///     controller: s.scrollController,
///     itemBuilder: (_, i, __) => s.item(i),
///   ),
/// )
/// ```
class ChatSlot {
  const ChatSlot({
    required this.context,
    required this.controller,
    required this.theme,
    required this.child,
  });

  final BuildContext context;

  /// State and actions. Everything a slot needs is reachable from here.
  final ChatController controller;

  /// The resolved theme — every field non-null.
  final ChatTheme theme;

  /// The default widget for this slot.
  final Widget child;

  ChatCapabilities get capabilities => controller.capabilities;
}

/// The whole screen. [child] is the default `Scaffold`.
class ChatScaffoldSlot extends ChatSlot {
  const ChatScaffoldSlot({
    required super.context,
    required super.controller,
    required super.theme,
    required super.child,
    required this.appBar,
    required this.background,
    required this.body,
    required this.composer,
    required this.errorBar,
    required this.jumpToLatest,
    this.drawer,
  });

  final Widget appBar;
  final Widget background;

  /// Transcript or empty state, whichever applies.
  final Widget body;

  final Widget composer;

  /// The failure banner. Already collapsed to nothing when there is no error.
  final Widget errorBar;

  final Widget jumpToLatest;

  /// Null when the adapter reports no session support.
  final Widget? drawer;
}

/// Everything between the app bar and the composer.
class ChatBodySlot extends ChatSlot {
  const ChatBodySlot({
    required super.context,
    required super.controller,
    required super.theme,
    required super.child,
    required this.list,
    required this.empty,
    required this.isEmpty,
  });

  final Widget list;
  final Widget empty;
  final bool isEmpty;
}

/// The scrollable transcript.
class ChatListSlot extends ChatSlot {
  const ChatListSlot({
    required super.context,
    required super.controller,
    required super.theme,
    required super.child,
    required this.pairs,
    required this.item,
    required this.scrollController,
    required this.onScroll,
    required this.header,
    required this.footer,
    required this.anchorHeight,
  });

  final List<ChatMessagePair> pairs;

  /// The built exchange at [index], separator and anchoring included. Use this
  /// in a custom scrollable and the bubbles stay the package's.
  final Widget Function(int index) item;

  int get count => pairs.length;

  final ScrollController scrollController;

  /// Feed this to a `NotificationListener<ScrollNotification>` so the
  /// follow-the-latest behaviour keeps working.
  final bool Function(ScrollNotification) onScroll;

  final Widget header;
  final Widget footer;

  /// Minimum height the last exchange is given, so a new question lands at the
  /// top of the viewport with the reply growing under it.
  final double anchorHeight;
}

/// One question/answer exchange.
class ChatPairSlot extends ChatSlot {
  const ChatPairSlot({
    required super.context,
    required super.controller,
    required super.theme,
    required super.child,
    required this.pair,
    required this.index,
    required this.isLast,
    required this.question,
    required this.answer,
  });

  final ChatMessagePair pair;
  final int index;
  final bool isLast;

  final Widget question;

  /// Collapsed to nothing until the reply exists.
  final Widget answer;
}

/// One piece of a message — its text, its actions, a host section.
///
/// Leaf parts get this; the assembled message gets [ChatMessageSlot], which adds
/// the sibling parts.
class ChatMessagePartSlot extends ChatSlot {
  const ChatMessagePartSlot({
    required super.context,
    required super.controller,
    required super.theme,
    required super.child,
    required this.message,
    required this.isLast,
  });

  final ChatMessage message;

  /// This is the newest exchange — where the typing indicator, the retry
  /// affordance and the anchoring apply.
  final bool isLast;
}

/// A whole message, with its parts already built.
class ChatMessageSlot extends ChatMessagePartSlot {
  const ChatMessageSlot({
    required super.context,
    required super.controller,
    required super.theme,
    required super.child,
    required super.message,
    required super.isLast,
    required this.text,
    required this.attachments,
    required this.actions,
  });

  final Widget text;
  final Widget attachments;
  final Widget actions;
}

/// The user's message.
class ChatQuestionSlot extends ChatMessageSlot {
  const ChatQuestionSlot({
    required super.context,
    required super.controller,
    required super.theme,
    required super.child,
    required super.message,
    required super.isLast,
    required super.text,
    required super.attachments,
    required super.actions,
    required this.replyQuote,
  });

  final Widget replyQuote;
}

/// The assistant's message.
///
/// [above] and [below] are the host's own sections, already built and in order —
/// where sources, tool status, media, citations or anything else belongs.
class ChatAnswerSlot extends ChatMessageSlot {
  const ChatAnswerSlot({
    required super.context,
    required super.controller,
    required super.theme,
    required super.child,
    required super.message,
    required super.isLast,
    required super.text,
    required super.attachments,
    required super.actions,
    required this.status,
    required this.reasoning,
    required this.error,
    required this.above,
    required this.below,
  });

  /// Tool/progress line shown while the reply works.
  final Widget status;

  /// Thinking, collapsed by default.
  final Widget reasoning;

  /// Per-message failure notice.
  final Widget error;

  final List<Widget> above;
  final List<Widget> below;
}

/// The composer.
class ChatComposerSlot extends ChatSlot {
  const ChatComposerSlot({
    required super.context,
    required super.controller,
    required super.theme,
    required super.child,
    required this.field,
    required this.send,
    required this.stop,
    required this.attachmentPreview,
    required this.suggestions,
    required this.above,
    required this.leading,
    required this.trailing,
  });

  /// The text field, wired to `controller.input` and the Enter-to-send shortcut.
  final Widget field;

  /// Sends the draft.
  final Widget send;

  /// Cancels the in-flight reply. The default composer shows this *instead of*
  /// [send] while [isResponding]; a custom one is free to show both.
  final Widget stop;

  /// Staged attachments strip. Empty when nothing is staged.
  final Widget attachmentPreview;

  final Widget suggestions;

  /// Banners above the composer.
  final Widget above;

  /// Attach / tool buttons, in order.
  final List<Widget> leading;

  /// Extra trailing controls, before [send].
  final List<Widget> trailing;

  bool get canSend => controller.canSend;
  bool get isResponding => controller.isResponding;
}

/// The bar over the transcript.
class ChatAppBarSlot extends ChatSlot {
  const ChatAppBarSlot({
    required super.context,
    required super.controller,
    required super.theme,
    required super.child,
    required this.leading,
    required this.title,
    required this.modelSelector,
    required this.actions,
  });

  final Widget leading;
  final Widget title;

  /// Empty when the adapter reports no model support.
  final Widget modelSelector;

  final List<Widget> actions;
}

/// The session drawer.
class ChatDrawerSlot extends ChatSlot {
  const ChatDrawerSlot({
    required super.context,
    required super.controller,
    required super.theme,
    required super.child,
    required this.sessions,
    required this.tile,
    required this.header,
    required this.footer,
    required this.newSessionButton,
    required this.list,
  });

  final List<ChatSession> sessions;

  /// The built row at [index].
  final Widget Function(int index) tile;

  final Widget header;
  final Widget footer;
  final Widget newSessionButton;

  /// The scrollable list of [tile]s, date-grouped.
  final Widget list;
}

/// One row in the session list.
class ChatSessionSlot extends ChatSlot {
  const ChatSessionSlot({
    required super.context,
    required super.controller,
    required super.theme,
    required super.child,
    required this.session,
    required this.isActive,
  });

  final ChatSession session;
  final bool isActive;
}

/// One row in the model picker.
class ChatModelSlot extends ChatSlot {
  const ChatModelSlot({
    required super.context,
    required super.controller,
    required super.theme,
    required super.child,
    required this.model,
    required this.isSelected,
  });

  final ChatModelOption model;
  final bool isSelected;
}

/// One attachment, staged in the composer or attached to a message.
class ChatAttachmentSlot extends ChatSlot {
  const ChatAttachmentSlot({
    required super.context,
    required super.controller,
    required super.theme,
    required super.child,
    required this.attachment,
    required this.index,
    required this.isStaged,
  });

  final ChatAttachment attachment;
  final int index;

  /// True in the composer (removable), false on a sent message.
  final bool isStaged;
}

/// The failure banner.
class ChatErrorSlot extends ChatSlot {
  const ChatErrorSlot({
    required super.context,
    required super.controller,
    required super.theme,
    required super.child,
    required this.message,
  });

  final String message;
}

/// The gap between exchanges.
class ChatSeparatorSlot extends ChatSlot {
  const ChatSeparatorSlot({
    required super.context,
    required super.controller,
    required super.theme,
    required super.child,
    required this.index,
  });

  final int index;
}
