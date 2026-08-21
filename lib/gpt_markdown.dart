import 'package:flutter/material.dart';
import 'package:gpt_markdown/custom_widgets/markdown_config.dart';

// `GptMarkdownConfig` and the builder typedefs are part of the public API —
// custom components receive a config and consumers pass builders in.
export 'package:gpt_markdown/custom_widgets/markdown_config.dart';

// Inline `code` styling is configured by consumers.
export 'package:gpt_markdown/custom_widgets/inline_code.dart';

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
import 'custom_widgets/indent_widget.dart';
import 'custom_widgets/link_button.dart';

part 'theme.dart';
part 'inline_pattern.dart';
part 'autolink.dart';
part 'markdown_component.dart';
part 'md_widget.dart';

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
    this.inlineCodeBuilder,
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
    this.autolink = true,
    this.autolinkSchemes = const <String>{},
    this.useDollarSignsForLatex = false,
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
  ///   SourceTag(),
  ///   IndentMd(),
  /// ];
  /// ```
  final List<MarkdownComponent>? components;

  /// The list of inline components.
  ///  ```dart
  /// List<MarkdownComponent> inlineComponents = [
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

  @override
  Widget build(BuildContext context) {
    String tex = data.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();
    if (useDollarSignsForLatex) {
      tex = tex.replaceAllMapped(
        RegExp(r"(?<!\\)\$\$(.*?)(?<!\\)\$\$", dotAll: true),
        (match) => "\\[${match[1] ?? ""}\\]",
      );
      if (!tex.contains(r"\(")) {
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

    return wrap(
      ClipRRect(
        child: MdWidget(
          context,
          tex,
          true,
          isRoot: true,
          config: GptMarkdownConfig(
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
            inlineCodeBuilder: inlineCodeBuilder,
            linkBuilder: linkBuilder,
            imageBuilder: imageBuilder,
            orderedListBuilder: orderedListBuilder,
            unOrderedListBuilder: unOrderedListBuilder,
            components: components,
            inlineComponents: inlineComponents,
            inlinePatterns: inlinePatterns,
            inlineCodeStyle: inlineCodeStyle,
            autolink: autolink,
            autolinkSchemes: autolinkSchemes,
            tableBuilder: tableBuilder,
          ),
        ),
      ),
    );
  }
}
