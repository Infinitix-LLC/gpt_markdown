import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gpt_markdown/custom_widgets/bidi_rich_text.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

/// A builder function for the ordered list.
typedef OrderedListBuilder =
    Widget Function(
      BuildContext context,
      String no,
      Widget child,
      GptMarkdownConfig config,
    );

/// A builder function for the unordered list.
typedef UnOrderedListBuilder =
    Widget Function(
      BuildContext context,
      Widget child,
      GptMarkdownConfig config,
    );

/// A builder function for the source tag.
typedef SourceTagBuilder =
    Widget Function(BuildContext context, String content, TextStyle textStyle);

/// A builder function for the code block.
typedef CodeBlockBuilder =
    Widget Function(
      BuildContext context,
      String name,
      String code,
      bool closed,
    );

/// A builder function for the LaTeX.
typedef LatexBuilder =
    Widget Function(
      BuildContext context,
      String tex,
      TextStyle textStyle,
      bool inline,
    );

/// A builder function for the link.
typedef LinkBuilder =
    Widget Function(
      BuildContext context,
      InlineSpan text,
      String url,
      TextStyle style,
    );

/// A builder function for the table.
typedef TableBuilder =
    Widget Function(
      BuildContext context,
      List<CustomTableRow> tableRows,
      TextStyle textStyle,
      GptMarkdownConfig config,
    );

/// Builds the span for one run of inline `` `code` ``.
///
/// [code] is the text between the backticks, [style] is the resolved code
/// [TextStyle] (monospace, sized and coloured per [InlineCodeStyle]), and
/// [codeStyle] is the resolved [InlineCodeStyle] itself, so a builder can reuse
/// the chip colours it would have been drawn with.
///
/// Return a [CodeTextSpan] to keep the painted chip, any other [TextSpan] to
/// drop it, or [baselineWidgetSpan] when a widget is genuinely required:
///
/// ```dart
/// inlineCodeBuilder: (context, code, style, codeStyle) => CodeTextSpan(
///   text: code,
///   codeStyle: codeStyle.copyWith(
///     backgroundColor: code.startsWith('TODO') ? Colors.amber : null,
///   ),
///   style: style,
/// ),
/// ```
///
/// Returning an [InlineSpan] rather than a [Widget] is what keeps inline code
/// on the text baseline, wrapping across lines, and selectable.
typedef InlineCodeBuilder =
    InlineSpan Function(
      BuildContext context,
      String code,
      TextStyle style,
      InlineCodeStyle codeStyle,
    );

/// A builder function for the image.
///
/// [width] and [height] come from the image alt text when parsed as `WxH`
/// (for example `![100x200](url)`); otherwise they are null.
typedef ImageBuilder =
    Widget Function(
      BuildContext context,
      String imageUrl,
      double? width,
      double? height,
    );

/// A configuration class for the GPT Markdown component.
///
/// The [GptMarkdownConfig] class is used to configure the GPT Markdown component.
/// It takes a [style] parameter to set the style of the text,
/// a [textDirection] parameter to set the direction of the text,
/// and an optional [onLinkTap] parameter to handle link clicks.
class GptMarkdownConfig {
  const GptMarkdownConfig({
    this.style,
    this.textDirection = TextDirection.ltr,
    this.onLinkTap,
    this.textAlign,
    this.textScaler,
    this.latexWorkaround,
    this.latexBuilder,
    this.followLinkColor = false,
    this.codeBuilder,
    this.sourceTagBuilder,
    this.inlineCodeBuilder,
    this.orderedListBuilder,
    this.unOrderedListBuilder,
    this.linkBuilder,
    this.imageBuilder,
    this.maxLines,
    this.overflow,
    this.components,
    this.inlineComponents,
    this.inlinePatterns,
    this.tableBuilder,
    this.inlineCodeStyle,
    this.autolink = true,
    this.autolinkSchemes = const <String>{},
    this.scope = MarkdownScope.content,
  });

  /// The direction of the text.
  final TextDirection textDirection;

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

  /// The LaTeX builder.
  final LatexBuilder? latexBuilder;

  /// The source tag builder.
  final SourceTagBuilder? sourceTagBuilder;

  /// Whether to follow the link color.
  final bool followLinkColor;

  /// The code builder.
  final CodeBlockBuilder? codeBuilder;

  /// The Ordered List builder.
  final OrderedListBuilder? orderedListBuilder;

  /// The Unordered List builder.
  final UnOrderedListBuilder? unOrderedListBuilder;

  /// The maximum number of lines.
  final int? maxLines;

  /// The overflow.
  final TextOverflow? overflow;

  /// Builds the span for inline `` `code` ``, overriding the default chip.
  final InlineCodeBuilder? inlineCodeBuilder;

  /// The link builder.
  final LinkBuilder? linkBuilder;

  /// The image builder.
  final ImageBuilder? imageBuilder;

  /// The list of components.
  final List<MarkdownComponent>? components;

  /// The list of inline components.
  final List<MarkdownComponent>? inlineComponents;

  /// App-specific inline syntaxes. See [GptMarkdown.inlinePatterns].
  final List<InlinePattern>? inlinePatterns;

  /// Overrides the themed inline `code` style for this widget only.
  final InlineCodeStyle? inlineCodeStyle;

  /// Whether bare URLs, `www.` hosts, emails and `<...>` autolinks are linked.
  final bool autolink;

  /// Extra URL schemes linked without `<>`. See [GptMarkdown.autolinkSchemes].
  final Set<String> autolinkSchemes;

  /// The nesting context the current text is being rendered in.
  ///
  /// Set by the components that recurse — [ATagMd] renders its label with
  /// [MarkdownScope.linkLabel], [TableMd] renders cells with
  /// [MarkdownScope.tableCell], and so on. Components whose
  /// [MarkdownComponent.scopes] excludes the current scope are skipped.
  final MarkdownScope scope;

  /// The table builder.
  final TableBuilder? tableBuilder;

  /// A copy of the configuration with the specified parameters.
  GptMarkdownConfig copyWith({
    TextStyle? style,
    TextDirection? textDirection,
    final void Function(String url, String title)? onLinkTap,
    final TextAlign? textAlign,
    final TextScaler? textScaler,
    final String Function(String tex)? latexWorkaround,
    final LatexBuilder? latexBuilder,
    final SourceTagBuilder? sourceTagBuilder,
    final bool? followLinkColor,
    final CodeBlockBuilder? codeBuilder,
    final int? maxLines,
    final TextOverflow? overflow,
    final InlineCodeBuilder? inlineCodeBuilder,
    final LinkBuilder? linkBuilder,
    final ImageBuilder? imageBuilder,
    final OrderedListBuilder? orderedListBuilder,
    final UnOrderedListBuilder? unOrderedListBuilder,
    final List<MarkdownComponent>? components,
    final List<MarkdownComponent>? inlineComponents,
    final List<InlinePattern>? inlinePatterns,
    final TableBuilder? tableBuilder,
    final InlineCodeStyle? inlineCodeStyle,
    final bool? autolink,
    final Set<String>? autolinkSchemes,
    final MarkdownScope? scope,
  }) {
    return GptMarkdownConfig(
      style: style ?? this.style,
      textDirection: textDirection ?? this.textDirection,
      onLinkTap: onLinkTap ?? this.onLinkTap,
      textAlign: textAlign ?? this.textAlign,
      textScaler: textScaler ?? this.textScaler,
      latexWorkaround: latexWorkaround ?? this.latexWorkaround,
      latexBuilder: latexBuilder ?? this.latexBuilder,
      followLinkColor: followLinkColor ?? this.followLinkColor,
      codeBuilder: codeBuilder ?? this.codeBuilder,
      sourceTagBuilder: sourceTagBuilder ?? this.sourceTagBuilder,
      maxLines: maxLines ?? this.maxLines,
      overflow: overflow ?? this.overflow,
      inlineCodeBuilder: inlineCodeBuilder ?? this.inlineCodeBuilder,
      linkBuilder: linkBuilder ?? this.linkBuilder,
      imageBuilder: imageBuilder ?? this.imageBuilder,
      orderedListBuilder: orderedListBuilder ?? this.orderedListBuilder,
      unOrderedListBuilder: unOrderedListBuilder ?? this.unOrderedListBuilder,
      components: components ?? this.components,
      inlineComponents: inlineComponents ?? this.inlineComponents,
      inlinePatterns: inlinePatterns ?? this.inlinePatterns,
      tableBuilder: tableBuilder ?? this.tableBuilder,
      inlineCodeStyle: inlineCodeStyle ?? this.inlineCodeStyle,
      autolink: autolink ?? this.autolink,
      autolinkSchemes: autolinkSchemes ?? this.autolinkSchemes,
      scope: scope ?? this.scope,
    );
  }

  /// A method to get a rich text widget from an inline span.
  ///
  /// Paragraphs that mix right-to-left text with two or more inline widgets
  /// (LaTeX, images, links) are rendered with [BidiText], which works around
  /// https://github.com/flutter/flutter/issues/54400 — the engine otherwise
  /// lays those inline widgets out left to right and they come out reversed.
  /// Everything else keeps using a plain [Text].
  Widget getRich(InlineSpan span, {bool isRoot = false}) {
    // A nested paragraph sits inside a `WidgetSpan`, and a paragraph lays its
    // inline children out in scaled space — it hands them `maxWidth / scale`
    // and multiplies the reported size back. A child that scales its own text
    // as well is counted twice, so nested paragraphs opt out.
    //
    // Passing `textScaler` here would defeat that: an explicit scaler on a
    // `Text` wins over the ambient `MediaQuery`, so the paragraph would scale
    // itself again despite the `withNoTextScaling` wrapper below.
    final effectiveScaler = isRoot ? textScaler : TextScaler.noScaling;
    final codeRuns = collectInlineCodeRuns(span);
    final needsBidi = needsBidiPlaceholderFix(span);
    if (codeRuns.isEmpty && !needsBidi) {
      // Nothing to decorate and no placeholders to reorder — the stock widget
      // does the job, and stays the hot path for ordinary paragraphs.
      final Widget child = Text.rich(
        span,
        textDirection: textDirection,
        textScaler: effectiveScaler,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      );
      if (isRoot) {
        return child;
      }
      return MediaQuery.withNoTextScaling(child: child);
    }
    final child = BidiText(
      span,
      bidiEnabled: needsBidi,
      inlineCodeRuns: codeRuns,
      textDirection: textDirection,
      textScaler: effectiveScaler,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
    if (isRoot) {
      return child;
    }
    return MediaQuery.withNoTextScaling(child: child);
  }

  /// A method to check if the configuration is the same.
  bool isSame(GptMarkdownConfig other) {
    return style == other.style &&
        textAlign == other.textAlign &&
        textScaler == other.textScaler &&
        maxLines == other.maxLines &&
        overflow == other.overflow &&
        followLinkColor == other.followLinkColor &&
        scope == other.scope &&
        autolink == other.autolink &&
        // Value types, so comparing them is cheap and a runtime change to any
        // of them regenerates the spans. Getting this wrong is silent: the
        // widget rebuilds with the new config and keeps rendering the old
        // output.
        setEquals(autolinkSchemes, other.autolinkSchemes) &&
        inlineCodeStyle == other.inlineCodeStyle &&
        // `InlinePattern` holds a builder closure and has no value equality,
        // so this falls back to element identity. A consumer that rebuilds the
        // list inline pays a regeneration per rebuild — the safe direction.
        listEquals(inlinePatterns, other.inlinePatterns) &&
        // Same reasoning: `MarkdownComponent` has no value equality, so these
        // compare by element identity. Swapping a component list at runtime
        // used to be ignored outright.
        listEquals(components, other.components) &&
        listEquals(inlineComponents, other.inlineComponents) &&
        // The rest are closures. They are recreated on every build by any
        // consumer that writes them inline, so comparing them would defeat the
        // cache entirely — a change to one of these needs a key or a remount.
        // latexWorkaround == other.latexWorkaround &&
        // latexBuilder == other.latexBuilder &&
        // sourceTagBuilder == other.sourceTagBuilder &&
        // codeBuilder == other.codeBuilder &&
        // orderedListBuilder == other.orderedListBuilder &&
        // unOrderedListBuilder == other.unOrderedListBuilder &&
        // linkBuilder == other.linkBuilder &&
        // imageBuilder == other.imageBuilder &&
        // inlineCodeBuilder == other.inlineCodeBuilder &&
        // onLinkTap == other.onLinkTap &&
        textDirection == other.textDirection;
  }
}
