import 'package:flutter/material.dart';
import 'package:gpt_markdown/custom_widgets/markdown_config.dart';

// `GptMarkdownConfig` and the builder typedefs are part of the public API —
// custom components receive a config and consumers pass builders in.
export 'package:gpt_markdown/custom_widgets/markdown_config.dart';

// Inline `code` styling is configured by consumers.
export 'package:gpt_markdown/custom_widgets/inline_code.dart';

// Reveal animation for streamed replies.
export 'package:gpt_markdown/streaming/streaming_markdown.dart';
export 'package:gpt_markdown/streaming/reveal_engine.dart';
export 'package:gpt_markdown/streaming/inline_hold.dart';
export 'package:gpt_markdown/streaming/reveal_effect.dart';
export 'package:gpt_markdown/streaming/reveal_spans.dart';
export 'package:gpt_markdown/streaming/block_entrance.dart';
export 'package:gpt_markdown/streaming/stream_split.dart';

// Per-component appearance.
export 'package:gpt_markdown/styles/block_quote_style.dart';
export 'package:gpt_markdown/styles/heading_style.dart';
export 'package:gpt_markdown/styles/link_style.dart';
export 'package:gpt_markdown/styles/list_style.dart';
export 'package:gpt_markdown/styles/checkbox_style.dart';
export 'package:gpt_markdown/styles/code_block_style.dart';
export 'package:gpt_markdown/styles/table_style.dart';
export 'package:gpt_markdown/styles/image_style.dart';
export 'package:gpt_markdown/styles/hr_style.dart';
export 'package:gpt_markdown/styles/source_tag_style.dart';
export 'package:gpt_markdown/styles/latex_style.dart';
export 'package:gpt_markdown/styles/gpt_markdown_style_sheet.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:gpt_markdown/custom_widgets/custom_divider.dart';
import 'package:gpt_markdown/custom_widgets/custom_error_image.dart';
import 'package:gpt_markdown/custom_widgets/custom_rb_cb.dart';
import 'package:gpt_markdown/custom_widgets/selectable_adapter.dart';
import 'package:gpt_markdown/custom_widgets/unordered_ordered_list.dart';
import 'dart:math';

import 'custom_widgets/code_field.dart';
import 'custom_widgets/inline_code.dart';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/scheduler.dart';

import 'streaming/block_entrance.dart';
import 'streaming/inline_hold.dart';
import 'streaming/reveal_effect.dart';
import 'streaming/reveal_engine.dart';
import 'streaming/reveal_spans.dart';
import 'streaming/streaming_markdown.dart';
import 'styles/block_quote_style.dart';
import 'styles/heading_style.dart';
import 'styles/link_style.dart';
import 'styles/list_style.dart';
import 'styles/checkbox_style.dart';
import 'styles/code_block_style.dart';
import 'styles/table_style.dart';
import 'styles/image_style.dart';
import 'styles/hr_style.dart';
import 'styles/source_tag_style.dart';
import 'styles/latex_style.dart';
import 'styles/gpt_markdown_style_sheet.dart';
import 'custom_widgets/indent_widget.dart';
import 'custom_widgets/link_button.dart';

import 'plusparse/plusparse.dart';

export 'gen_ui/gen_ui.dart';
export 'plusparse/plusparse.dart';

part 'theme.dart';
part 'inline_pattern.dart';
part 'autolink.dart';
part 'markdown_component.dart';
part 'shared_render.dart';
part 'md_widget.dart';
part 'inline_directive.dart';
part 'plusparse/renderer.dart';
part 'plusparse/incremental.dart';

/// This widget create a full markdown widget as a column view.
class GptMarkdown extends StatelessWidget {
  const GptMarkdown(
    this.data, {
    super.key,
    this.style,
    this.followLinkColor = false,
    this.textDirection = TextDirection.ltr,
    this.latexWorkaround,
    this.textAlign,
    this.imageBuilder,
    this.textScaler,
    this.onLinkTap,
    this.latexBuilder,
    this.codeBuilder,
    this.sourceTagBuilder,
    this.inlineDirectives,
    this.inlineCodeBuilder,
    @Deprecated('Use inlineCodeBuilder. Will be removed in 2.0.0.')
    this.highlightBuilder,
    this.linkBuilder,
    this.maxLines,
    this.overflow,
    this.orderedListBuilder,
    this.unOrderedListBuilder,
    this.tableBuilder,
    this.components,
    this.inlineComponents,
    this.inlinePatterns,
    this.inlineCodeStyle,
    this.styleSheet,
    this.blockQuoteBuilder,
    this.headingBuilder,
    this.checkboxBuilder,
    this.radioOptionBuilder,
    this.hrBuilder,
    this.onCheckboxChanged,
    this.onCodeCopy,
    this.onImageTap,
    this.onSourceTagTap,
    this.autolink = true,
    this.autolinkSchemes = const <String>{},
    this.animation = GptMarkdownAnimation.none,
    this.blockAnimation = GptMarkdownBlockAnimation.none,
    this.isStreaming = true,
    this.charactersPerSecond = 300,
    this.revealFadeSeconds = 0.25,
    this.blockAnimationDuration = const Duration(milliseconds: 200),
    this.blockAnimationCurve = Curves.easeOut,
    this.useDollarSignsForLatex = false,
    this.incremental = true,
  });

  /// The direction of the text.
  final TextDirection textDirection;

  /// The data to be displayed.
  final String data;

  /// The style of the text.
  final TextStyle? style;

  /// The alignment of the text.
  final TextAlign? textAlign;

  /// The text scaler.
  final TextScaler? textScaler;

  /// The callback function to handle link clicks.
  final void Function(String url, String title)? onLinkTap;

  /// The LaTeX workaround.
  final String Function(String tex)? latexWorkaround;
  final int? maxLines;

  /// The overflow.
  final TextOverflow? overflow;

  /// The LaTeX builder.
  final LatexBuilder? latexBuilder;

  /// Whether to follow the link color.
  final bool followLinkColor;

  /// The code builder.
  final CodeBlockBuilder? codeBuilder;

  /// The source tag builder.
  final SourceTagBuilder? sourceTagBuilder;

  /// Host-defined inline regions the parser must not look inside.
  ///
  /// Use these for content that is not Markdown and must survive the parse
  /// intact — a JSON payload a server substituted into the reply, say. Unlike
  /// [inlinePatterns], which matches over the text a parse produced, a
  /// directive is lifted out *before* parsing, so nothing inside it can be
  /// interpreted as Markdown. See [InlineDirective].
  final List<InlineDirective>? inlineDirectives;

  /// Builds a widget for inline `` `code` ``.
  ///
  /// Used only when [inlineCodeBuilder] is null, and kept so 1.1.x code keeps
  /// compiling. The result is wrapped in a baseline-aligned [WidgetSpan],
  /// which is the shape that made this hook a problem: it cannot wrap across
  /// lines, is skipped by text selection, and does not paint on iOS inside a
  /// link label.
  ///
  /// Reach for [inlineCodeStyle] if you only want to restyle inline code, or
  /// [inlineCodeBuilder] if you need to build the span yourself.
  @Deprecated('Use inlineCodeBuilder. Will be removed in 2.0.0.')
  final HighlightBuilder? highlightBuilder;

  /// Builds the span for inline `` `code` ``, replacing the default chip.
  ///
  /// Reach for [inlineCodeStyle] first — it covers font, colours, outline,
  /// radius and padding without a builder. Use this when the styling has to
  /// depend on the code itself.
  final InlineCodeBuilder? inlineCodeBuilder;

  /// The link builder.
  final LinkBuilder? linkBuilder;

  /// The image builder.
  final ImageBuilder? imageBuilder;

  /// The ordered list builder.
  final OrderedListBuilder? orderedListBuilder;

  /// The unordered list builder.
  final UnOrderedListBuilder? unOrderedListBuilder;

  /// Whether to use dollar signs for LaTeX.
  final bool useDollarSignsForLatex;

  /// Incremental rendering for streaming content: the document is split into
  /// top-level segments, each rendered as its own cached widget, so appending
  /// text only rebuilds and re-lays-out the tail segment instead of the whole
  /// message. Recommended for chat UIs that re-render while a reply streams.
  /// Ignored when custom [components]/[inlineComponents] are provided (those
  /// force the legacy single-text pipeline).
  final bool incremental;

  /// The table builder.
  final TableBuilder? tableBuilder;

  /// The list of components.
  ///  ```dart
  /// List<MarkdownComponent> components = [
  ///   CodeBlockMd(),
  ///   NewLines(),
  ///   BlockQuote(),
  ///   ImageMd(),
  ///   ATagMd(),
  ///   TableMd(),
  ///   HTag(),
  ///   UnOrderedList(),
  ///   OrderedList(),
  ///   RadioButtonMd(),
  ///   CheckBoxMd(),
  ///   HrLine(),
  ///   StrikeMd(),
  ///   BoldMd(),
  ///   ItalicMd(),
  ///   LatexMath(),
  ///   LatexMathMultiLine(),
  ///   HighlightedText(),
  ///   GenUiMd(),
  ///   SourceTag(),
  ///   IndentMd(),
  /// ];
  /// ```
  final List<MarkdownComponent>? components;

  /// The list of inline components.
  ///  ```dart
  /// List<MarkdownComponent> inlineComponents = [
  ///   GenUiMd(),
  ///   ImageMd(),
  ///   ATagMd(),
  ///   TableMd(),
  ///   StrikeMd(),
  ///   BoldMd(),
  ///   ItalicMd(),
  ///   LatexMath(),
  ///   LatexMathMultiLine(),
  ///   HighlightedText(),
  ///   SourceTag(),
  /// ];
  /// ```
  final List<MarkdownComponent>? inlineComponents;

  /// App-specific inline syntaxes rendered alongside Markdown.
  ///
  /// Use this for tokens Markdown does not define — `@mention`, `#channel`,
  /// `:emoji:`. Patterns are matched ahead of the built-in components, and by
  /// default do not apply inside link labels.
  ///
  /// ```dart
  /// GptMarkdown(
  ///   text,
  ///   inlinePatterns: [
  ///     InlinePattern.prefixed(
  ///       prefix: '#',
  ///       knownNames: channelNames,
  ///       builder: (context, match, style) =>
  ///           WidgetSpan(child: ChannelChip(match.group(0)!)),
  ///     ),
  ///   ],
  /// )
  /// ```
  ///
  /// Prefer building a [TextSpan] over a [WidgetSpan] where the design allows
  /// it: a [TextSpan] stays selectable, wraps across lines, and sits on the
  /// surrounding baseline.
  final List<InlinePattern>? inlinePatterns;

  /// How inline `code` is drawn, for this widget only.
  ///
  /// Null fields fall back to the ambient [ColorScheme], so a single field is
  /// enough:
  ///
  /// ```dart
  /// GptMarkdown(
  ///   text,
  ///   inlineCodeStyle: const InlineCodeStyle(fontFamily: 'GeistMono'),
  /// )
  /// ```
  ///
  /// Set [GptMarkdownThemeData.inlineCode] instead to restyle the whole app.
  final InlineCodeStyle? inlineCodeStyle;

  /// Per-component appearance for this widget.
  ///
  /// Values here win over [GptMarkdownThemeData.styleSheet] field by field,
  /// and anything left unset keeps the package default — so adding a style
  /// sheet never changes how existing content looks.
  ///
  /// ```dart
  /// GptMarkdown(
  ///   text,
  ///   styleSheet: const GptMarkdownStyleSheet(
  ///     blockQuote: BlockQuoteStyle(barWidth: 4),
  ///   ),
  /// )
  /// ```
  final GptMarkdownStyleSheet? styleSheet;

  /// Called when a task-list checkbox is tapped.
  ///
  /// Only fires when `CheckboxStyle.interactive` is set — Markdown checkboxes
  /// render the source text, so they are read-only unless you opt in.
  final void Function(bool value)? onCheckboxChanged;

  /// Called with the code after a code block's copy button is used.
  final void Function(String code)? onCodeCopy;

  /// Called with the image URL when an image is tapped.
  final void Function(String url)? onImageTap;

  /// Called with the tag content when a `[1]` citation chip is tapped.
  final void Function(String content)? onSourceTagTap;

  /// Replaces the whole heading widget, including the rule an h1 draws.
  ///
  /// Reach for [styleSheet] first — `HeadingStyle` covers the text style,
  /// padding and the rule without giving up the default structure.
  final HeadingBuilder? headingBuilder;

  /// Replaces the whole checkbox row.
  final CheckboxBuilder? checkboxBuilder;

  /// Replaces the whole radio row.
  final RadioOptionBuilder? radioOptionBuilder;

  /// Replaces the horizontal rule.
  final HrBuilder? hrBuilder;

  /// Replaces the whole blockquote widget.
  ///
  /// Reach for [styleSheet] first — it covers the bar, padding, background and
  /// text style without giving up the default structure.
  final BlockQuoteBuilder? blockQuoteBuilder;

  /// Whether bare URLs, `www.` hosts, email addresses and `<...>` autolinks
  /// become links. Defaults to true.
  ///
  /// Bare autolinks follow the GFM autolink extension; `<...>` autolinks follow
  /// CommonMark §6.5. Turn this off to render URLs as plain text — for
  /// untrusted input where an accidental tap target is unwelcome.
  final bool autolink;

  /// Extra URL schemes linked **without** `<>`.
  ///
  /// `http`, `https`, `mailto` and `xmpp` are always linked. Anything else has
  /// to be opted into, because a bare `foo://bar` in prose is usually not meant
  /// as a link:
  ///
  /// ```dart
  /// GptMarkdown(text, autolinkSchemes: const {'myapp'})
  /// ```
  ///
  /// This does not affect `<...>` autolinks, which accept any scheme as
  /// CommonMark specifies — the author wrote the brackets deliberately.
  final Set<String> autolinkSchemes;

  /// How each character arrives.
  ///
  /// Defaults to [GptMarkdownAnimation.none], which builds exactly the tree
  /// this widget built before the feature existed — no ticker, no wrapper, no
  /// cost. Pick anything else for a reply that is still being generated:
  ///
  /// ```dart
  /// GptMarkdown(
  ///   reply,
  ///   animation: GptMarkdownAnimation.blurIn,
  ///   blockAnimation: GptMarkdownBlockAnimation.growIn,
  ///   isStreaming: stillGenerating,
  /// )
  /// ```
  ///
  /// This and [blockAnimation] are separate on purpose: how a letter appears
  /// and how a table appears are different questions, and combining them into
  /// one preset means a new preset for every pairing.
  ///
  /// Streaming is data, not a `Stream`: rebuild with a longer [data] as
  /// tokens arrive. Only the part of the reply that can still change is
  /// rebuilt, so the cost per token does not grow with the reply.
  final GptMarkdownAnimation animation;

  /// How a block that contains a laid-out widget — a table, a fence, block
  /// maths, a rule — plays its entrance.
  ///
  /// Prose reveals a character at a time, but these have no half-state: the
  /// delimiter row lands and a full-height table exists in the next frame.
  /// Without an entrance that is a step change in layout and everything below
  /// it moves at once.
  ///
  /// Only [GptMarkdownBlockAnimation.growIn] changes the space a block takes
  /// while it plays; the rest animate paint alone, so content below them holds
  /// still. It can be used independently when [animation] is
  /// [GptMarkdownAnimation.none].
  final GptMarkdownBlockAnimation blockAnimation;

  /// Whether more text may still arrive. Only consulted when [animation] is
  /// not [GptMarkdownAnimation.none].
  ///
  /// While true the reveal animates. Set it to false when the reply finishes
  /// and the remainder is revealed quickly rather than trickling.
  final bool isStreaming;

  /// Baseline reveal speed for [animation].
  ///
  /// The reveal exceeds this on its own whenever it would otherwise fall
  /// behind the incoming text, so a fast model never leaves the animation
  /// lagging.
  final double charactersPerSecond;

  /// How long one character takes to finish arriving.
  ///
  /// Independent of [charactersPerSecond]: that sets how fast the head moves,
  /// this sets how long a character keeps animating after the head has passed
  /// it. Larger values give a longer, softer trail. Ignored by
  /// [GptMarkdownAnimation.typewriter], whose characters are final on arrival.
  final double revealFadeSeconds;

  /// How long [blockAnimation] takes.
  final Duration blockAnimationDuration;

  /// The easing [blockAnimation] plays on.
  final Curve blockAnimationCurve;

  /// A method to remove extra lines inside block LaTeX.
  // String _removeExtraLinesInsideBlockLatex(String text) {
  //   return text.replaceAllMapped(
  //     RegExp(r"\\\[(.*?)\\\]", multiLine: true, dotAll: true),
  //     (match) {
  //       String content = match[0] ?? "";
  //       return content.replaceAllMapped(RegExp(r"\n[\n\ ]+"), (match) => "\n");
  //     },
  //   );
  // }

  /// Whether the span-level reveal is available for this call.
  ///
  /// It lives inside the incremental view, which custom components opt out of,
  /// and it needs an animating effect to have anything to do.
  bool get _usesSpanReveal =>
      animation.reveals && components == null && inlineComponents == null;

  @override
  Widget build(BuildContext context) {
    if (animation == GptMarkdownAnimation.none) {
      return _buildDocument(context, data);
    }
    if (_usesSpanReveal) {
      // The reveal is applied to spans that are already built, inside the
      // incremental view — so the document is rendered once per *text* change
      // rather than once per frame, and there is no settled/tail seam to keep
      // aligned.
      return _buildDocument(context, data);
    }
    // Custom components force the legacy single-text pipeline, which has no
    // spans to restyle: fall back to re-slicing the source and softening the
    // tail's edge.
    return StreamingMarkdown(
      text: data,
      isStreaming: isStreaming,
      charactersPerSecond: charactersPerSecond,
      // The settled prefix and the live tail are two separate documents, so
      // the block gap at their boundary has to be supplied here; the
      // whole-document build creates it on its own.
      seamGap: blockGap(
        context,
        GptMarkdownConfig(style: style, textScaler: textScaler),
      ),
      builder: _buildDocument,
    );
  }

  /// Builds the document for [source], with no reveal involved.
  Widget _buildDocument(BuildContext context, String source) {
    String tex = source.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();
    // Before anything reads the text as Markdown, and before either pipeline
    // sees it, so a payload cannot be parsed, split or truncated.
    final directives = inlineDirectives;
    if (directives != null && directives.isNotEmpty) {
      tex = maskInlineDirectives(tex, directives);
    }
    var dollarsAreMath = false;
    if (useDollarSignsForLatex) {
      tex = tex.replaceAllMapped(
        RegExp(r"(?<!\\)\$\$(.*?)(?<!\\)\$\$", dotAll: true),
        (match) => "\\[${match[1] ?? ""}\\]",
      );
      if (!tex.contains(r"\(")) {
        // Same condition as the rewrite below: once a native `\(` appears,
        // a single `$` can never become maths, so it must not be held either.
        dollarsAreMath = true;
        tex = tex.replaceAllMapped(
          RegExp(r"(?<!\\)\$(.*?)(?<!\\)\$"),
          (match) => "\\(${match[1] ?? ""}\\)",
        );
        tex = tex.splitMapJoin(
          RegExp(r"\[.*?\]|\(.*?\)"),
          onNonMatch: (p0) {
            return p0.replaceAll("\\\$", "\$");
          },
        );
      }
    }
    // tex = _removeExtraLinesInsideBlockLatex(tex);
    final config = GptMarkdownConfig(
      textDirection: textDirection,
      style: style,
      onLinkTap: onLinkTap,
      textAlign: textAlign,
      textScaler: textScaler,
      followLinkColor: followLinkColor,
      latexWorkaround: latexWorkaround,
      latexBuilder: latexBuilder,
      codeBuilder: codeBuilder,
      maxLines: maxLines,
      overflow: overflow,
      sourceTagBuilder: sourceTagBuilder,
      inlineDirectives: inlineDirectives,
      inlineCodeBuilder: inlineCodeBuilder,
      // ignore: deprecated_member_use_from_same_package
      highlightBuilder: highlightBuilder,
      linkBuilder: linkBuilder,
      imageBuilder: imageBuilder,
      orderedListBuilder: orderedListBuilder,
      unOrderedListBuilder: unOrderedListBuilder,
      components: components,
      inlineComponents: inlineComponents,
      inlinePatterns: inlinePatterns,
      inlineCodeStyle: inlineCodeStyle,
      styleSheet: styleSheet,
      blockQuoteBuilder: blockQuoteBuilder,
      headingBuilder: headingBuilder,
      checkboxBuilder: checkboxBuilder,
      radioOptionBuilder: radioOptionBuilder,
      hrBuilder: hrBuilder,
      onCheckboxChanged: onCheckboxChanged,
      onCodeCopy: onCodeCopy,
      onImageTap: onImageTap,
      onSourceTagTap: onSourceTagTap,
      autolink: autolink,
      autolinkSchemes: autolinkSchemes,
      tableBuilder: tableBuilder,
    );

    // An explicit `textScaler` has to reach the inline widgets too: they
    // compensate for the paragraph's scaling of their box, and to do that they
    // need the same scaler the paragraph uses. Publishing it through
    // `MediaQuery` keeps one source of truth.
    final scaler = textScaler;
    Widget wrap(Widget child) {
      if (scaler == null) {
        return child;
      }
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: scaler),
        child: child,
      );
    }

    // The reveal forces the incremental path even when the caller did not ask
    // for it: it is the only pipeline that keeps spans around to restyle.
    if ((incremental || _usesSpanReveal) &&
        components == null &&
        inlineComponents == null) {
      return wrap(
        ClipRRect(
          child: _IncrementalMdView(
            text: tex,
            config: config,
            effect: animation,
            blockAnimation: blockAnimation,
            isStreaming: isStreaming,
            revealing: _usesSpanReveal,
            charactersPerSecond: charactersPerSecond,
            revealFadeSeconds: revealFadeSeconds,
            blockAnimationDuration: blockAnimationDuration,
            blockAnimationCurve: blockAnimationCurve,
            holdMathDollars: dollarsAreMath,
          ),
        ),
      );
    }
    return wrap(
      ClipRRect(
        child: MdWidget(context, tex, true, isRoot: true, config: config),
      ),
    );
  }
}
