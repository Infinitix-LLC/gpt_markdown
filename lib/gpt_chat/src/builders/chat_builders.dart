import 'package:flutter/foundation.dart';

import '../../../custom_widgets/markdown_config.dart';
import 'chat_slots.dart';

/// Every replaceable part of the chat UI.
///
/// Leave a builder null to keep the default. Each one takes a single [ChatSlot]
/// carrying the controller, the resolved theme, the default widget, and the
/// parts that composed it — see [ChatSlot] for why that last point is what makes
/// customization progressive.
///
/// Reach for these only after [ChatTheme]: colours, radii, spacing, widths and
/// typography are theme work, not builder work.
///
/// Names are flat and prefixed, so typing `answer` or `composer` in an IDE lists
/// everything in that area.
///
/// A builder replaces what a part *draws*, not the widget that hosts it: the
/// default widget is what applies your builder, so e.g. `ChatAppBar` stays in
/// the tree while everything it would have drawn is yours.
///
/// ```dart
/// GptChat(
///   adapter: adapter,
///   builders: ChatBuilders(
///     // decorate
///     answerText: (s) => Padding(padding: const EdgeInsets.all(8), child: s.child),
///     // replace a leaf
///     composerSend: (s) => MySendButton(onTap: s.controller.onSend),
///     // recompose, keeping every part
///     answer: (s) => Column(children: [...s.above, s.text, MyFooter(), s.actions]),
///   ),
/// )
/// ```
@immutable
class ChatBuilders {
  const ChatBuilders({
    // frame
    this.scaffold,
    this.background,
    this.loading,
    this.errorBar,
    this.jumpToLatest,
    // app bar
    this.appBar,
    this.appBarLeading,
    this.appBarTitle,
    this.appBarActions,
    this.modelSelector,
    this.modelTile,
    // drawer
    this.drawer,
    this.drawerHeader,
    this.drawerFooter,
    this.newSessionButton,
    this.sessionTile,
    // transcript
    this.body,
    this.messageList,
    this.listHeader,
    this.listFooter,
    this.pair,
    this.separator,
    this.empty,
    this.typingIndicator,
    // question
    this.question,
    this.questionText,
    this.questionAttachments,
    this.questionActions,
    this.questionReplyQuote,
    this.questionAttachmentTile,
    // answer
    this.answer,
    this.answerText,
    this.answerStatus,
    this.answerReasoning,
    this.answerAttachments,
    this.answerError,
    this.answerActions,
    this.answerAbove,
    this.answerBelow,
    // composer
    this.composer,
    this.composerField,
    this.composerSend,
    this.composerStop,
    this.composerAbove,
    this.composerSuggestions,
    this.composerAttachments,
    this.composerAttachmentTile,
    this.composerLeading,
    this.composerTrailing,
    // markdown content
    this.codeBlock,
    this.latex,
    this.link,
    this.image,
    this.highlight,
    this.sourceTag,
    this.genUi,
  });

  // ------------------------------------------------------------------ frame ---

  /// The whole screen. `slot.appBar`, `slot.body`, `slot.composer`,
  /// `slot.drawer` are the regions, already built.
  final ChatBuild<ChatScaffoldSlot>? scaffold;

  /// Painted behind the transcript, below every other layer.
  final ChatBuild<ChatSlot>? background;

  /// Shown while the conversation is being restored.
  final ChatBuild<ChatSlot>? loading;

  /// The failure banner.
  final ChatBuild<ChatErrorSlot>? errorBar;

  /// The affordance shown while the transcript is scrolled away from the latest
  /// message.
  final ChatBuild<ChatSlot>? jumpToLatest;

  // ---------------------------------------------------------------- app bar ---

  final ChatBuild<ChatAppBarSlot>? appBar;
  final ChatBuild<ChatSlot>? appBarLeading;
  final ChatBuild<ChatSlot>? appBarTitle;

  /// Trailing actions, in order. Replaces the defaults.
  final List<ChatBuild<ChatSlot>>? appBarActions;

  final ChatBuild<ChatSlot>? modelSelector;
  final ChatBuild<ChatModelSlot>? modelTile;

  // ----------------------------------------------------------------- drawer ---

  /// The session drawer. `slot.tile(i)` is the built row, `slot.list` the whole
  /// date-grouped list.
  final ChatBuild<ChatDrawerSlot>? drawer;
  final ChatBuild<ChatSlot>? drawerHeader;
  final ChatBuild<ChatSlot>? drawerFooter;
  final ChatBuild<ChatSlot>? newSessionButton;
  final ChatBuild<ChatSessionSlot>? sessionTile;

  // ------------------------------------------------------------- transcript ---

  /// Transcript or empty state. `slot.isEmpty` says which the default picked.
  final ChatBuild<ChatBodySlot>? body;

  /// The scrollable itself. `slot.item(i)` gives the built exchange, so a custom
  /// list keeps the package's bubbles.
  final ChatBuild<ChatListSlot>? messageList;

  final ChatBuild<ChatSlot>? listHeader;
  final ChatBuild<ChatSlot>? listFooter;

  /// One exchange. `slot.question` and `slot.answer` are already built.
  final ChatBuild<ChatPairSlot>? pair;

  final ChatBuild<ChatSeparatorSlot>? separator;

  /// Shown instead of the transcript before the first message.
  final ChatBuild<ChatSlot>? empty;

  /// Shown while a reply has been requested but no token has arrived.
  final ChatBuild<ChatSlot>? typingIndicator;

  // --------------------------------------------------------------- question ---

  final ChatBuild<ChatQuestionSlot>? question;
  final ChatBuild<ChatMessagePartSlot>? questionText;
  final ChatBuild<ChatMessagePartSlot>? questionAttachments;
  final ChatBuild<ChatMessagePartSlot>? questionActions;

  /// The quoted message a question replies to.
  final ChatBuild<ChatMessagePartSlot>? questionReplyQuote;
  final ChatBuild<ChatAttachmentSlot>? questionAttachmentTile;

  // ----------------------------------------------------------------- answer ---

  /// The assistant message. `slot.above` / `slot.below` hold [answerAbove] /
  /// [answerBelow], already built and ordered.
  final ChatBuild<ChatAnswerSlot>? answer;

  final ChatBuild<ChatMessagePartSlot>? answerText;
  final ChatBuild<ChatMessagePartSlot>? answerStatus;
  final ChatBuild<ChatMessagePartSlot>? answerReasoning;
  final ChatBuild<ChatMessagePartSlot>? answerAttachments;
  final ChatBuild<ChatMessagePartSlot>? answerError;
  final ChatBuild<ChatMessagePartSlot>? answerActions;

  /// Sections inserted before the answer text, in order. Return
  /// `SizedBox.shrink()` to omit one for a given message.
  final List<ChatBuild<ChatMessagePartSlot>>? answerAbove;

  /// Sections inserted after the answer text, in order.
  final List<ChatBuild<ChatMessagePartSlot>>? answerBelow;

  // --------------------------------------------------------------- composer ---

  /// The composer. Every control is on the slot, already built.
  final ChatBuild<ChatComposerSlot>? composer;

  final ChatBuild<ChatSlot>? composerField;
  final ChatBuild<ChatSlot>? composerSend;

  /// Shown in the send button's place while a reply streams.
  final ChatBuild<ChatSlot>? composerStop;

  /// Banners above the composer — quota notices, mode hints.
  final ChatBuild<ChatSlot>? composerAbove;

  final ChatBuild<ChatSlot>? composerSuggestions;
  final ChatBuild<ChatSlot>? composerAttachments;
  final ChatBuild<ChatAttachmentSlot>? composerAttachmentTile;

  /// Leading controls — attach, tools. Replaces the defaults.
  final List<ChatBuild<ChatSlot>>? composerLeading;

  /// Trailing controls, before the send button.
  final List<ChatBuild<ChatSlot>>? composerTrailing;

  // ---------------------------------------------------------------- content ---

  /// Fenced code blocks inside an answer.
  final CodeBlockBuilder? codeBlock;

  /// Math blocks inside an answer.
  final LatexBuilder? latex;

  final LinkBuilder? link;
  final ImageBuilder? image;
  final HighlightBuilder? highlight;
  final SourceTagBuilder? sourceTag;

  /// Renders one `genui{...}` payload. Defaults to the registry on the
  /// enclosing [ChatScope]; override to handle payload shapes of your own
  /// before falling back to it.
  final GenUiBuilder? genUi;

  /// A copy with the non-null builders of [other] layered on top.
  ChatBuilders merge(ChatBuilders? other) {
    if (other == null) return this;
    return ChatBuilders(
      scaffold: other.scaffold ?? scaffold,
      background: other.background ?? background,
      loading: other.loading ?? loading,
      errorBar: other.errorBar ?? errorBar,
      jumpToLatest: other.jumpToLatest ?? jumpToLatest,
      appBar: other.appBar ?? appBar,
      appBarLeading: other.appBarLeading ?? appBarLeading,
      appBarTitle: other.appBarTitle ?? appBarTitle,
      appBarActions: other.appBarActions ?? appBarActions,
      modelSelector: other.modelSelector ?? modelSelector,
      modelTile: other.modelTile ?? modelTile,
      drawer: other.drawer ?? drawer,
      drawerHeader: other.drawerHeader ?? drawerHeader,
      drawerFooter: other.drawerFooter ?? drawerFooter,
      newSessionButton: other.newSessionButton ?? newSessionButton,
      sessionTile: other.sessionTile ?? sessionTile,
      body: other.body ?? body,
      messageList: other.messageList ?? messageList,
      listHeader: other.listHeader ?? listHeader,
      listFooter: other.listFooter ?? listFooter,
      pair: other.pair ?? pair,
      separator: other.separator ?? separator,
      empty: other.empty ?? empty,
      typingIndicator: other.typingIndicator ?? typingIndicator,
      question: other.question ?? question,
      questionText: other.questionText ?? questionText,
      questionAttachments: other.questionAttachments ?? questionAttachments,
      questionActions: other.questionActions ?? questionActions,
      questionReplyQuote: other.questionReplyQuote ?? questionReplyQuote,
      questionAttachmentTile:
          other.questionAttachmentTile ?? questionAttachmentTile,
      answer: other.answer ?? answer,
      answerText: other.answerText ?? answerText,
      answerStatus: other.answerStatus ?? answerStatus,
      answerReasoning: other.answerReasoning ?? answerReasoning,
      answerAttachments: other.answerAttachments ?? answerAttachments,
      answerError: other.answerError ?? answerError,
      answerActions: other.answerActions ?? answerActions,
      answerAbove: other.answerAbove ?? answerAbove,
      answerBelow: other.answerBelow ?? answerBelow,
      composer: other.composer ?? composer,
      composerField: other.composerField ?? composerField,
      composerSend: other.composerSend ?? composerSend,
      composerStop: other.composerStop ?? composerStop,
      composerAbove: other.composerAbove ?? composerAbove,
      composerSuggestions: other.composerSuggestions ?? composerSuggestions,
      composerAttachments: other.composerAttachments ?? composerAttachments,
      composerAttachmentTile:
          other.composerAttachmentTile ?? composerAttachmentTile,
      composerLeading: other.composerLeading ?? composerLeading,
      composerTrailing: other.composerTrailing ?? composerTrailing,
      codeBlock: other.codeBlock ?? codeBlock,
      latex: other.latex ?? latex,
      link: other.link ?? link,
      image: other.image ?? image,
      highlight: other.highlight ?? highlight,
      sourceTag: other.sourceTag ?? sourceTag,
      genUi: other.genUi ?? genUi,
    );
  }
}
