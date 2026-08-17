import 'package:flutter/material.dart';

/// Every visual constant the default chat UI uses.
///
/// This is the first stop for customization: a rebrand — colours, radii,
/// spacing, widths, typography — should need no builders at all. Reach for
/// `ChatBuilders` only once you want a different *structure*.
///
/// Fields are nullable; anything left null is derived from the ambient
/// [ThemeData]. Resolve with [ChatTheme.of], which merges, in order:
///
/// 1. the `theme:` passed to `GptChat`,
/// 2. a `ChatTheme` registered as a [ThemeExtension],
/// 3. defaults derived from `Theme.of(context)`.
@immutable
class ChatTheme extends ThemeExtension<ChatTheme> {
  const ChatTheme({
    this.contentMaxWidth,
    this.composerMaxWidth,
    this.appBarHeight,
    this.composerReserve,
    this.transcriptPadding,
    this.scrollPhysics,
    this.pairSpacing,
    this.messageSpacing,
    this.horizontalPadding,
    this.showQuestionBubble,
    this.questionBubbleColor,
    this.questionTextStyle,
    this.questionBubbleRadius,
    this.questionBubblePadding,
    this.questionMaxWidthFraction,
    this.questionCollapseThreshold,
    this.answerTextStyle,
    this.answerActionsAlwaysVisible,
    this.composerColor,
    this.composerRadius,
    this.composerElevation,
    this.composerPadding,
    this.composerHintStyle,
    this.sendButtonColor,
    this.sendButtonForegroundColor,
    this.stopButtonColor,
    this.showSeparators,
    this.separatorColor,
    this.surfaceColor,
    this.hintText,
  });

  // ---------------------------------------------------------------- metrics ---

  /// Reading width for messages. Prose past this gets hard to scan.
  final double? contentMaxWidth;

  /// Composer width. Matches [contentMaxWidth] by default so the two columns
  /// line up.
  final double? composerMaxWidth;

  /// Height of the floating app bar, excluding the status-bar inset.
  final double? appBarHeight;

  /// Space kept clear at the bottom of the transcript for the composer.
  final double? composerReserve;

  /// Inset applied *around* the transcript, outside its scrollable. Use it for
  /// a safe-area gutter that should shrink the viewport rather than scroll with
  /// the content.
  final EdgeInsets? transcriptPadding;

  /// Physics for the transcript. Null keeps the platform default.
  final ScrollPhysics? scrollPhysics;

  /// Gap between exchanges.
  final double? pairSpacing;

  /// Gap between a question and its answer.
  final double? messageSpacing;

  /// Gutter either side of the reading column.
  final double? horizontalPadding;

  // --------------------------------------------------------------- question ---

  /// Draw the user's message in a bubble. False renders it as plain text, like
  /// the assistant's.
  final bool? showQuestionBubble;

  final Color? questionBubbleColor;
  final TextStyle? questionTextStyle;
  final BorderRadius? questionBubbleRadius;
  final EdgeInsets? questionBubblePadding;

  /// Widest a question bubble may be, as a fraction of the column.
  final double? questionMaxWidthFraction;

  /// Characters past which a question collapses behind a Show more toggle.
  /// Zero disables collapsing.
  final int? questionCollapseThreshold;

  // ----------------------------------------------------------------- answer ---

  final TextStyle? answerTextStyle;

  /// Keep the copy/retry row visible instead of revealing it on hover. Defaults
  /// to true on touch platforms.
  final bool? answerActionsAlwaysVisible;

  // --------------------------------------------------------------- composer ---

  final Color? composerColor;
  final BorderRadius? composerRadius;
  final double? composerElevation;
  final EdgeInsets? composerPadding;
  final TextStyle? composerHintStyle;
  final Color? sendButtonColor;
  final Color? sendButtonForegroundColor;
  final Color? stopButtonColor;

  // ------------------------------------------------------------------ misc ---

  /// Draw a divider between exchanges. Off by default — spacing separates them.
  final bool? showSeparators;
  final Color? separatorColor;

  /// Background the app bar and composer fade into.
  final Color? surfaceColor;

  /// Composer placeholder.
  final String? hintText;

  /// The theme in effect, with every field filled in.
  ///
  /// [override] is what a `GptChat(theme:)` passed down; it wins over the
  /// [ThemeExtension] and over the derived defaults.
  static ChatTheme of(BuildContext context, [ChatTheme? override]) {
    final theme = Theme.of(context);
    final extension = theme.extension<ChatTheme>();
    return _defaults(theme).merge(extension).merge(override);
  }

  /// A copy with the non-null fields of [other] layered on top.
  ChatTheme merge(ChatTheme? other) {
    if (other == null) return this;
    return ChatTheme(
      contentMaxWidth: other.contentMaxWidth ?? contentMaxWidth,
      composerMaxWidth: other.composerMaxWidth ?? composerMaxWidth,
      appBarHeight: other.appBarHeight ?? appBarHeight,
      composerReserve: other.composerReserve ?? composerReserve,
      transcriptPadding: other.transcriptPadding ?? transcriptPadding,
      scrollPhysics: other.scrollPhysics ?? scrollPhysics,
      pairSpacing: other.pairSpacing ?? pairSpacing,
      messageSpacing: other.messageSpacing ?? messageSpacing,
      horizontalPadding: other.horizontalPadding ?? horizontalPadding,
      showQuestionBubble: other.showQuestionBubble ?? showQuestionBubble,
      questionBubbleColor: other.questionBubbleColor ?? questionBubbleColor,
      questionTextStyle: other.questionTextStyle ?? questionTextStyle,
      questionBubbleRadius: other.questionBubbleRadius ?? questionBubbleRadius,
      questionBubblePadding:
          other.questionBubblePadding ?? questionBubblePadding,
      questionMaxWidthFraction:
          other.questionMaxWidthFraction ?? questionMaxWidthFraction,
      questionCollapseThreshold:
          other.questionCollapseThreshold ?? questionCollapseThreshold,
      answerTextStyle: other.answerTextStyle ?? answerTextStyle,
      answerActionsAlwaysVisible:
          other.answerActionsAlwaysVisible ?? answerActionsAlwaysVisible,
      composerColor: other.composerColor ?? composerColor,
      composerRadius: other.composerRadius ?? composerRadius,
      composerElevation: other.composerElevation ?? composerElevation,
      composerPadding: other.composerPadding ?? composerPadding,
      composerHintStyle: other.composerHintStyle ?? composerHintStyle,
      sendButtonColor: other.sendButtonColor ?? sendButtonColor,
      sendButtonForegroundColor:
          other.sendButtonForegroundColor ?? sendButtonForegroundColor,
      stopButtonColor: other.stopButtonColor ?? stopButtonColor,
      showSeparators: other.showSeparators ?? showSeparators,
      separatorColor: other.separatorColor ?? separatorColor,
      surfaceColor: other.surfaceColor ?? surfaceColor,
      hintText: other.hintText ?? hintText,
    );
  }

  static ChatTheme _defaults(ThemeData theme) {
    final scheme = theme.colorScheme;
    final isTouch = switch (theme.platform) {
      TargetPlatform.iOS || TargetPlatform.android => true,
      _ => false,
    };

    return ChatTheme(
      contentMaxWidth: 760,
      composerMaxWidth: 760,
      appBarHeight: 64,
      composerReserve: 132,
      transcriptPadding: EdgeInsets.zero,
      pairSpacing: 28,
      messageSpacing: 12,
      horizontalPadding: 20,
      showQuestionBubble: true,
      questionBubbleColor: scheme.surfaceContainerHigh,
      questionTextStyle: theme.textTheme.bodyLarge?.copyWith(
        color: scheme.onSurface,
        height: 1.4,
      ),
      questionBubbleRadius: const BorderRadius.all(Radius.circular(20)),
      questionBubblePadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 11,
      ),
      questionMaxWidthFraction: 0.78,
      questionCollapseThreshold: 150,
      answerTextStyle: theme.textTheme.bodyLarge?.copyWith(
        color: scheme.onSurface,
        height: 1.55,
      ),
      answerActionsAlwaysVisible: isTouch,
      composerColor: scheme.surfaceContainerHighest,
      composerRadius: const BorderRadius.all(Radius.circular(26)),
      composerElevation: 0,
      composerPadding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      composerHintStyle: theme.textTheme.bodyLarge?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
      sendButtonColor: scheme.primary,
      sendButtonForegroundColor: scheme.onPrimary,
      stopButtonColor: scheme.error,
      showSeparators: false,
      separatorColor: scheme.outlineVariant,
      surfaceColor: scheme.surface,
      hintText: 'Ask anything',
    );
  }

  @override
  ChatTheme copyWith({
    double? contentMaxWidth,
    double? composerMaxWidth,
    double? appBarHeight,
    double? composerReserve,
    EdgeInsets? transcriptPadding,
    ScrollPhysics? scrollPhysics,
    double? pairSpacing,
    double? messageSpacing,
    double? horizontalPadding,
    bool? showQuestionBubble,
    Color? questionBubbleColor,
    TextStyle? questionTextStyle,
    BorderRadius? questionBubbleRadius,
    EdgeInsets? questionBubblePadding,
    double? questionMaxWidthFraction,
    int? questionCollapseThreshold,
    TextStyle? answerTextStyle,
    bool? answerActionsAlwaysVisible,
    Color? composerColor,
    BorderRadius? composerRadius,
    double? composerElevation,
    EdgeInsets? composerPadding,
    TextStyle? composerHintStyle,
    Color? sendButtonColor,
    Color? sendButtonForegroundColor,
    Color? stopButtonColor,
    bool? showSeparators,
    Color? separatorColor,
    Color? surfaceColor,
    String? hintText,
  }) {
    return merge(
      ChatTheme(
        contentMaxWidth: contentMaxWidth,
        composerMaxWidth: composerMaxWidth,
        appBarHeight: appBarHeight,
        composerReserve: composerReserve,
        transcriptPadding: transcriptPadding,
        scrollPhysics: scrollPhysics,
        pairSpacing: pairSpacing,
        messageSpacing: messageSpacing,
        horizontalPadding: horizontalPadding,
        showQuestionBubble: showQuestionBubble,
        questionBubbleColor: questionBubbleColor,
        questionTextStyle: questionTextStyle,
        questionBubbleRadius: questionBubbleRadius,
        questionBubblePadding: questionBubblePadding,
        questionMaxWidthFraction: questionMaxWidthFraction,
        questionCollapseThreshold: questionCollapseThreshold,
        answerTextStyle: answerTextStyle,
        answerActionsAlwaysVisible: answerActionsAlwaysVisible,
        composerColor: composerColor,
        composerRadius: composerRadius,
        composerElevation: composerElevation,
        composerPadding: composerPadding,
        composerHintStyle: composerHintStyle,
        sendButtonColor: sendButtonColor,
        sendButtonForegroundColor: sendButtonForegroundColor,
        stopButtonColor: stopButtonColor,
        showSeparators: showSeparators,
        separatorColor: separatorColor,
        surfaceColor: surfaceColor,
        hintText: hintText,
      ),
    );
  }

  @override
  ChatTheme lerp(ThemeExtension<ChatTheme>? other, double t) {
    if (other is! ChatTheme) return this;
    return t < 0.5 ? this : other;
  }
}

/// Non-null accessors, so widgets are not littered with `?? fallback`.
///
/// Safe only on an instance produced by [ChatTheme.of], which fills every field.
extension ResolvedChatTheme on ChatTheme {
  double get contentWidth => contentMaxWidth ?? 760;
  double get composerWidth => composerMaxWidth ?? contentWidth;
  double get barHeight => appBarHeight ?? 64;
  double get bottomReserve => composerReserve ?? 132;
  EdgeInsets get outerPadding => transcriptPadding ?? EdgeInsets.zero;
  double get gapBetweenPairs => pairSpacing ?? 28;
  double get gapBetweenMessages => messageSpacing ?? 12;
  double get gutter => horizontalPadding ?? 20;
  bool get bubbleQuestions => showQuestionBubble ?? true;
  double get questionWidthFraction => questionMaxWidthFraction ?? 0.78;
  int get collapseThreshold => questionCollapseThreshold ?? 150;
  bool get pinnedActions => answerActionsAlwaysVisible ?? true;
  bool get separators => showSeparators ?? false;
  String get placeholder => hintText ?? 'Ask anything';
}
