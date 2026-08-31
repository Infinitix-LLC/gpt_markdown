part of 'gpt_markdown.dart';

/// The nesting context a [MarkdownComponent] is being rendered in.
///
/// Markdown nests: a link label may contain bold text, a table cell may
/// contain a link, a heading may contain inline code. A component declares the
/// contexts it is meaningful in through [MarkdownComponent.scopes] and is
/// skipped everywhere else.
///
/// This is what stops, for example, an app-specific `#channel` chip from also
/// rendering *inside* `[#channel](url)`. That produced a [WidgetSpan] nested
/// in the link's own [WidgetSpan], which does not paint on iOS.
enum MarkdownScope {
  /// Ordinary document or inline content. The default.
  content,

  /// Inside the `label` half of a `[label](url)` link.
  linkLabel,

  /// Inside a table cell.
  tableCell,

  /// Inside a `#` heading.
  heading,
}

/// Markdown components
abstract class MarkdownComponent {
  /// Every scope — the default value of [scopes].
  ///
  /// Declared `const` so reading [scopes] allocates nothing; it is read once
  /// per component per [generate] call, and [generate] recurses.
  static const Set<MarkdownScope> allScopes = {
    MarkdownScope.content,
    MarkdownScope.linkLabel,
    MarkdownScope.tableCell,
    MarkdownScope.heading,
  };

  /// Every scope except [MarkdownScope.linkLabel].
  ///
  /// The right default for anything rendering a [WidgetSpan]: a placeholder
  /// nested inside the link's own placeholder does not paint on iOS.
  static const Set<MarkdownScope> allScopesExceptLinkLabel = {
    MarkdownScope.content,
    MarkdownScope.tableCell,
    MarkdownScope.heading,
  };

  /// The nesting contexts this component is allowed to render in.
  ///
  /// Defaults to [allScopes], so existing components keep their behaviour.
  /// Override it to opt out of a context — most commonly
  /// [allScopesExceptLinkLabel].
  Set<MarkdownScope> get scopes => allScopes;

  static List<MarkdownComponent> get globalComponents => [
    CodeBlockMd(),
    LatexMathMultiLine(),
    NewLines(),
    BlockQuote(),
    TableMd(),
    HTag(),
    UnOrderedList(),
    OrderedList(),
    RadioButtonMd(),
    CheckBoxMd(),
    HrLine(),
    IndentMd(),
  ];

  static final List<MarkdownComponent> inlineComponents = [
    InlineDirectiveMd(),
    ATagMd(),
    ImageMd(),
    AutolinkMd(),
    TableMd(),
    StrikeMd(),
    BoldMd(),
    ItalicMd(),
    UnderLineMd(),
    LatexMath(),
    LatexMathMultiLine(),
    HighlightedText(),
    SourceTag(),
  ];

  /// Compiled combined regexes, keyed by the joined pattern string.
  ///
  /// Building and compiling the combined pattern is the most expensive part of
  /// [generate], and [generate] recurses once per nested span. The joined
  /// pattern string fully determines the [RegExp], so it is the natural key.
  static final Map<String, RegExp> _combinedRegexCache = {};

  /// Upper bound on [_combinedRegexCache].
  ///
  /// Components may be built from runtime data (a channel list, an emoji
  /// palette), so the set of distinct patterns is not bounded by the package.
  /// The cache is dropped wholesale rather than grown without limit.
  static const int _combinedRegexCacheLimit = 64;

  static RegExp _combinedRegexFor(List<MarkdownComponent> components) {
    final pattern = components.map<String>((e) => e.exp.pattern).join("|");
    // The combined regex carries one set of flags for every alternative, so a
    // single case-insensitive component makes the whole alternation
    // case-insensitive. Without this its matches never reach the dispatch loop
    // at all — the combined regex simply does not find them.
    final caseSensitive = components.every((e) => e.exp.isCaseSensitive);
    final key = caseSensitive ? pattern : 'i:$pattern';
    final cached = _combinedRegexCache[key];
    if (cached != null) {
      return cached;
    }
    if (_combinedRegexCache.length >= _combinedRegexCacheLimit) {
      _combinedRegexCache.clear();
    }
    return _combinedRegexCache[key] = RegExp(
      pattern,
      multiLine: true,
      dotAll: true,
      caseSensitive: caseSensitive,
    );
  }

  /// Generate widget for markdown widget
  static List<InlineSpan> generate(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
    bool includeGlobalComponents,
  ) {
    var components =
        includeGlobalComponents
            ? config.components ?? MarkdownComponent.globalComponents
            : config.inlineComponents ?? MarkdownComponent.inlineComponents;

    // Consumer patterns are matched ahead of the built-ins, and only in the
    // inline pass. The global pass resolves block structure (headings, lists,
    // tables); everything it does not claim comes straight back here with
    // [includeGlobalComponents] false, so inline patterns still see all of it.
    final inlinePatterns = config.inlinePatterns;
    if (!includeGlobalComponents &&
        inlinePatterns != null &&
        inlinePatterns.isNotEmpty) {
      components = [...inlinePatterns.map(InlinePatternMd.new), ...components];
    }

    // Filter *before* the combined regex is built, not just in the dispatch
    // loop below. Filtering only the dispatch loop would leave the combined
    // regex claiming text that no component then handles.
    final scope = config.scope;
    components = components
        .where((e) => e.scopes.contains(scope))
        .toList(growable: false);

    List<InlineSpan> spans = [];
    if (components.isEmpty) {
      // An empty pattern matches everywhere and would consume the text.
      return [TextSpan(text: text, style: config.style)];
    }
    final combinedRegex = _combinedRegexFor(components);
    text.splitMapJoin(
      combinedRegex,
      onMatch: (p0) {
        String element = p0[0] ?? "";
        for (var each in components) {
          var p = each.exp.pattern;
          // The group matters: `^a|b$` anchors only the first and last
          // alternative, so any component whose pattern has a top-level `|`
          // would claim matches it does not actually cover.
          var exp = RegExp(
            '^(?:$p)\$',
            multiLine: each.exp.isMultiLine,
            dotAll: each.exp.isDotAll,
            caseSensitive: each.exp.isCaseSensitive,
          );
          if (exp.hasMatch(element)) {
            spans.add(each.span(context, element, config));
            return "";
          }
        }
        // The combined regex matched but no single component claims the whole
        // match. Show the source text rather than dropping it silently.
        assert(() {
          debugPrint(
            'gpt_markdown: no component claimed "$element"; '
            'rendering it as plain text.',
          );
          return true;
        }());
        spans.add(TextSpan(text: element, style: config.style));
        return "";
      },
      onNonMatch: (p0) {
        if (p0.isEmpty) {
          return "";
        }
        if (includeGlobalComponents) {
          var newSpans = generate(context, p0, config.copyWith(), false);
          spans.addAll(newSpans);
          return "";
        }
        spans.add(TextSpan(text: p0, style: config.style));
        return "";
      },
    );

    return spans;
  }

  InlineSpan span(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  );

  RegExp get exp;
  bool get inline;
}

/// Inline component
abstract class InlineMd extends MarkdownComponent {
  @override
  bool get inline => true;

  @override
  InlineSpan span(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  );
}

/// A masked [InlineDirective], put back as the host's span.
///
/// The directive was lifted out of the source before parsing, leaving an inert
/// sentinel; this is the regex pipeline's half of putting it back. Registered
/// first so nothing else can claim the sentinel.
class InlineDirectiveMd extends InlineMd {
  @override
  Set<MarkdownScope> get scopes => MarkdownComponent.allScopes;

  @override
  RegExp get exp => RegExp(inlineDirectiveMaskPattern);

  @override
  InlineSpan span(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    final directives = config.inlineDirectives;
    final match = exp.firstMatch(text.trim());
    final decoded =
        match == null || directives == null
            ? null
            : decodeInlineDirectiveMask(match[0]!, directives.length);
    if (decoded == null || directives == null) {
      // A sentinel that is not one of this document's directives renders as
      // the text it is, rather than being mistaken for a widget.
      return TextSpan(text: text, style: config.style);
    }
    return directives[decoded.index].builder(
      context,
      decoded.payload,
      config.style ?? const TextStyle(),
    );
  }
}

/// Block component
abstract class BlockMd extends MarkdownComponent {
  @override
  bool get inline => false;

  @override
  RegExp get exp =>
      RegExp(r'^\ *?' + expString + r"$", dotAll: true, multiLine: true);

  String get expString;

  @override
  InlineSpan span(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    var matches = RegExp(r'^(?<spaces>\ \ +).*').firstMatch(text);
    var spaces = matches?.namedGroup('spaces');
    var length = spaces?.length ?? 0;
    var child = build(context, text, config);
    length = min(length, 4);
    if (length > 0) {
      child = UnorderedListView(
        spacing: length * 1.0,
        textDirection: config.textDirection,
        child: child,
      );
    }
    child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [Flexible(child: child)],
    );
    return scaledWidgetSpan(child: child, config: config);
  }

  Widget build(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  );
}

/// Indent component
class IndentMd extends BlockMd {
  @override
  String get expString => (r"^(\ \ +)([^\n]+)$");
  @override
  Widget build(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    var match = this.exp.firstMatch(text);
    var conf = config.copyWith();
    return Directionality(
      textDirection: config.textDirection,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: config.getRich(
              TextSpan(
                children: MarkdownComponent.generate(
                  context,
                  match?[2]?.trim() ?? "",
                  conf,
                  false,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Heading component
class HTag extends BlockMd {
  @override
  String get expString => (r"(?<hash>#{1,6})\ (?<data>[^\n]+?)$");
  @override
  Widget build(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    var match = this.exp.firstMatch(text.trim());
    final hashes = match?.namedGroup('hash');
    return headingWidget(
      context,
      config,
      level: hashes == null ? 1 : hashes.length,
      buildChildren:
          (conf) => MarkdownComponent.generate(
            context,
            "${match?.namedGroup('data')}",
            conf,
            false,
          ),
    );
  }
}

class NewLines extends InlineMd {
  @override
  RegExp get exp => RegExp(r"\n\n+");
  @override
  InlineSpan span(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    return TextSpan(
      text: "\n\n",
      style: TextStyle(
        fontSize: config.style?.fontSize ?? 14,
        height: 1.15,
        color: config.style?.color,
      ),
    );
  }
}

/// Horizontal line component
class HrLine extends BlockMd {
  @override
  String get expString => (r"⸻|((--)[-]+)$");
  @override
  Widget build(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    return hrWidget(context, config);
  }
}

/// Checkbox component
class CheckBoxMd extends BlockMd {
  @override
  String get expString => (r"\[((?:\x|\ ))\]\ (\S[^\n]*?)$");

  @override
  Widget build(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    var match = this.exp.firstMatch(text.trim());
    return checkboxWidget(
      context,
      config,
      checked: "${match?[1]}" == "x",
      label: MdWidget(context, "${match?[2]}", false, config: config),
    );
  }
}

/// Radio Button component
class RadioButtonMd extends BlockMd {
  @override
  String get expString => (r"\(((?:\x|\ ))\)\ (\S[^\n]*)$");

  @override
  Widget build(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    var match = this.exp.firstMatch(text.trim());
    return radioWidget(
      context,
      config,
      selected: "${match?[1]}" == "x",
      label: MdWidget(context, "${match?[2]}", false, config: config),
    );
  }
}

/// Block quote component
class BlockQuote extends InlineMd {
  @override
  bool get inline => false;

  @override
  RegExp get exp => RegExp(
    r"(?:(?:^)\ *>[^\n]+)(?:(?:\n)\ *>[^\n]+)*",
    dotAll: true,
    multiLine: true,
  );

  @override
  InlineSpan span(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    var match = exp.firstMatch(text);
    var dataBuilder = StringBuffer();
    var m = match?[0] ?? '';
    for (var each in m.split('\n')) {
      if (each.startsWith(RegExp(r'\ *>'))) {
        var subString = each.trimLeft().substring(1);
        if (subString.startsWith(' ')) {
          subString = subString.substring(1);
        }
        dataBuilder.writeln(subString);
      } else {
        dataBuilder.writeln(each);
      }
    }
    var data = dataBuilder.toString().trim();

    return blockQuoteSpan(
      context,
      config,
      buildContent:
          (conf) => conf.getRich(
            TextSpan(
              children: MarkdownComponent.generate(context, data, conf, true),
            ),
          ),
    );
  }
}

/// Unordered list component
class UnOrderedList extends BlockMd {
  @override
  String get expString => (r"(?:\-|\*)\ ([^\n]+)$");

  @override
  Widget build(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    var match = this.exp.firstMatch(text);

    var child = MdWidget(context, "${match?[1]?.trim()}", true, config: config);

    return unorderedListItem(context, config, child);
  }
}

/// Ordered list component
class OrderedList extends BlockMd {
  @override
  String get expString => (r"([0-9]+)\.\ ([^\n]+)$");

  @override
  Widget build(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    var match = this.exp.firstMatch(text);

    var no = "${match?[1]}".trim();

    var child = MdWidget(context, "${match?[2]}".trim(), true, config: config);
    return orderedListItem(context, config, no, child);
  }
}

/// Builds the span for one run of inline `` `code` ``.
///
/// Shared by [HighlightedText] and the plusparse renderer so the two parsers
/// cannot drift apart on the thing a reader sees most often.
InlineSpan inlineCodeSpan(
  BuildContext context,
  String code,
  GptMarkdownConfig config,
) {
  // A plain TextSpan, tagged so the paragraph paints a rounded chip behind
  // it — see `custom_widgets/inline_code.dart`. Keeping it out of a
  // WidgetSpan is what lets inline code wrap across lines, stay selectable,
  // sit on the surrounding baseline, and appear inside a link label.
  final codeStyle = (config.inlineCodeStyle ??
          GptMarkdownTheme.of(context).inlineCode)
      .resolve(Theme.of(context).colorScheme);
  final textStyle = codeStyle.applyTo(config.style ?? const TextStyle());

  final builder = config.inlineCodeBuilder;
  if (builder != null) {
    return builder(context, code, textStyle, codeStyle);
  }

  // ignore: deprecated_member_use_from_same_package
  final legacyBuilder = config.highlightBuilder;
  if (legacyBuilder != null) {
    // Kept so 1.1.x code compiles. Wrapped on the baseline rather than at
    // the old hardcoded `PlaceholderAlignment.middle`, which sat visibly off
    // the surrounding text.
    return baselineWidgetSpan(
      legacyBuilder(context, code, config.style ?? textStyle),
    );
  }

  return CodeTextSpan(text: code, codeStyle: codeStyle, style: textStyle);
}

class HighlightedText extends InlineMd {
  @override
  RegExp get exp => RegExp(r"`(?!`)(.+?)(?<!`)`(?!`)");

  @override
  InlineSpan span(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    var match = exp.firstMatch(text.trim());
    return inlineCodeSpan(context, match?[1] ?? "", config);
  }
}

/// Bold text component
class BoldMd extends InlineMd {
  @override
  RegExp get exp =>
      RegExp(r"(?<!\*)\*\*(?<!\s)(.+?)(?<!\s)\*\*(?!\*)", dotAll: true);

  @override
  InlineSpan span(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    var match = exp.firstMatch(text.trim());
    var conf = config.copyWith(
      style:
          config.style?.copyWith(fontWeight: FontWeight.bold) ??
          const TextStyle(fontWeight: FontWeight.bold),
    );
    return TextSpan(
      children: MarkdownComponent.generate(
        context,
        "${match?[1]}",
        conf,
        false,
      ),
      style: conf.style,
    );
  }
}

class StrikeMd extends InlineMd {
  @override
  RegExp get exp => RegExp(r"(?<!\*)\~\~(?<!\s)(.+?)(?<!\s)\~\~(?!\*)");

  @override
  InlineSpan span(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    var match = exp.firstMatch(text.trim());
    var conf = config.copyWith(
      style:
          config.style?.copyWith(
            decoration: TextDecoration.lineThrough,
            decorationColor: config.style?.color,
          ) ??
          const TextStyle(decoration: TextDecoration.lineThrough),
    );
    return TextSpan(
      children: MarkdownComponent.generate(
        context,
        "${match?[1]}",
        conf,
        false,
      ),
      style: conf.style,
    );
  }
}

/// Italic text component
class ItalicMd extends InlineMd {
  @override
  RegExp get exp =>
      RegExp(r"(?:(?<!\*)\*(?<!\s)(.+?)(?<!\s)\*(?!\*))", dotAll: true);

  @override
  InlineSpan span(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    var match = exp.firstMatch(text.trim());
    var data = match?[1] ?? match?[2];
    var conf = config.copyWith(
      style: (config.style ?? const TextStyle()).copyWith(
        fontStyle: FontStyle.italic,
      ),
    );
    return TextSpan(
      children: MarkdownComponent.generate(context, "$data", conf, false),
      style: conf.style,
    );
  }
}

class LatexMathMultiLine extends BlockMd {
  @override
  String get expString => (r"\ *\\\[((?:.)*?)\\\]");
  @override
  RegExp get exp => RegExp(expString, dotAll: true, multiLine: true);

  @override
  Widget build(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    var p0 = exp.firstMatch(text.trim());
    return latexWidget(
      context,
      config,
      tex: p0?[1] ?? p0?[2] ?? '',
      inline: false,
    );
  }
}

/// Italic text component
class LatexMath extends InlineMd {
  @override
  RegExp get exp => RegExp(
    [
      r"\\\((.*?)\\\)",
      // r"(?<!\\)\$((?:\\.|[^$])*?)\$(?!\\)",
    ].join("|"),
    dotAll: true,
  );

  @override
  InlineSpan span(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    var p0 = exp.firstMatch(text.trim());
    p0?.group(0);
    String mathText = p0?[1]?.toString() ?? "";
    return scaledWidgetSpan(
      config: config,
      child: latexWidget(context, config, tex: mathText, inline: true),
    );
  }
}

/// source text component
class SourceTag extends InlineMd {
  @override
  RegExp get exp => RegExp(r"(?:【.*?)?\[(\d+?)\]");

  @override
  InlineSpan span(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    var match = exp.firstMatch(text.trim());
    var content = match?[1];
    if (content == null) {
      return const TextSpan();
    }
    return sourceTagSpan(context, content, config);
  }
}

/// Link text component
class ATagMd extends InlineMd {
  @override
  RegExp get exp => RegExp(r"(?<!\!)\[.*?\]\([^\s]*\)");

  /// CommonMark forbids links inside link labels, and the label is rendered
  /// inside this component's own [WidgetSpan] — a second one nested in it does
  /// not paint on iOS.
  @override
  Set<MarkdownScope> get scopes => MarkdownComponent.allScopesExceptLinkLabel;

  @override
  InlineSpan span(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    var bracketCount = 0;
    var start = 1;
    var end = 0;
    for (var i = 0; i < text.length; i++) {
      if (text[i] == '[') {
        bracketCount++;
      } else if (text[i] == ']') {
        bracketCount--;
        if (bracketCount == 0) {
          end = i;
          break;
        }
      }
    }

    if (end + 1 >= text.length || text[end + 1] != '(') {
      // Malformed link. Show the source text instead of deleting it.
      return TextSpan(text: text, style: config.style);
    }

    // First try to find the basic pattern
    // final basicMatch = RegExp(r'(?<!\!)\[(.*)\]\(').firstMatch(text.trim());
    // if (basicMatch == null) {
    //   return const TextSpan();
    // }

    final linkText = text.substring(start, end);
    final urlStart = end + 2;

    // Now find the balanced closing parenthesis
    int parenCount = 0;
    int urlEnd = urlStart;

    for (int i = urlStart; i < text.length; i++) {
      final char = text[i];

      if (char == '(') {
        parenCount++;
      } else if (char == ')') {
        if (parenCount == 0) {
          // This is the closing parenthesis of the link
          urlEnd = i;
          break;
        } else {
          parenCount--;
        }
      }
    }

    if (urlEnd == urlStart) {
      // No closing parenthesis found. Show the source text instead of
      // deleting it.
      return TextSpan(text: text, style: config.style);
    }

    final url = text.substring(urlStart, urlEnd).trim();

    var ending = text.substring(urlEnd + 1);

    var endingSpans = MarkdownComponent.generate(
      context,
      ending,
      config,
      false,
    );

    final child = buildLinkSpan(context, config, url: url, label: linkText);
    var textSpan = TextSpan(children: [child, ...endingSpans]);
    return textSpan;
  }
}

/// The style sheet in force: the widget's, merged over the theme's, field by
/// field, with anything still unset resolved to the package default.
///
/// Kept in one place so every component resolves its style the same way and a
/// widget override never discards the rest of the theme.
GptMarkdownStyleSheet resolvedStyleSheet(
  BuildContext context,
  GptMarkdownConfig config,
) {
  final widgetSheet = config.styleSheet ?? const GptMarkdownStyleSheet();
  return widgetSheet.merge(GptMarkdownTheme.of(context).styleSheet);
}

/// A [WidgetSpan] for an inline widget.
///
/// Note for anyone touching text scaling: a paragraph lays inline children out
/// in *scaled* space — it divides their constraints by the scale factor and
/// multiplies the reported size back. At a 3x setting a block widget is
/// therefore given a third of the width, wraps into a narrow column and
/// reserves far more height than it needs. Compensating for that inside the
/// child was tried and produced overlapping text; the fix belongs in how
/// blocks are composed, not in a wrapper. See CHANGELOG.
WidgetSpan scaledWidgetSpan({
  required Widget child,
  required GptMarkdownConfig config,
  PlaceholderAlignment alignment = PlaceholderAlignment.baseline,
  TextBaseline? baseline = TextBaseline.alphabetic,
}) {
  return WidgetSpan(alignment: alignment, baseline: baseline, child: child);
}

/// Builds the span for a link, shared by [ATagMd] and [AutolinkMd].
///
/// [label] is rendered through [MarkdownComponent.generate] in the
/// [MarkdownScope.linkLabel] scope when [parseLabel] is true. Autolinks pass
/// false: their label *is* the URL, and running it back through the inline
/// components would let `ItalicMd` eat the underscores out of a path such as
/// `https://example.com/a_b_c`.
InlineSpan buildLinkSpan(
  BuildContext context,
  GptMarkdownConfig config, {
  required String url,
  required String label,
  bool parseLabel = true,
  List<InlineSpan> Function(GptMarkdownConfig conf)? buildLabelSpans,
}) {
  final theme = GptMarkdownTheme.of(context);
  final linkStyleSpec = (resolvedStyleSheet(context, config).link ??
          const LinkStyle())
      .resolve(Theme.of(context).colorScheme);
  final baseColor = linkStyleSpec.color ?? theme.linkColor;
  final hoverColor = linkStyleSpec.hoverColor ?? theme.linkHoverColor;
  final decoration = linkStyleSpec.decoration ?? TextDecoration.underline;
  final builder = config.linkBuilder;

  List<InlineSpan> labelSpans(TextStyle style) {
    final conf = config.copyWith(style: style, scope: MarkdownScope.linkLabel);
    // The plusparse renderer already holds the label's parsed children, so it
    // supplies them rather than having the text re-parsed.
    final custom = buildLabelSpans;
    if (custom != null) {
      return custom(conf);
    }
    if (!parseLabel) {
      return [TextSpan(text: label, style: style)];
    }
    return MarkdownComponent.generate(context, label, conf, false);
  }

  if (builder != null) {
    // Build a styled span to hand off to the custom linkBuilder.
    final linkStyle = (config.style ?? const TextStyle()).copyWith(
      color: baseColor,
      decorationColor: baseColor,
      decoration: decoration,
      decorationThickness: linkStyleSpec.decorationThickness,
      fontWeight: linkStyleSpec.fontWeight,
    );
    return scaledWidgetSpan(
      config: config,
      child: GestureDetector(
        onTap: () => config.onLinkTap?.call(url, label),
        child: builder(
          context,
          TextSpan(children: labelSpans(linkStyle), style: linkStyle),
          url,
          config.style ?? const TextStyle(),
        ),
      ),
    );
  }

  // Default rendering — LinkButton rebuilds the span on every hover change so
  // bold/italic text inside a link also picks up the hover colour.
  return scaledWidgetSpan(
    config: config,
    child: LinkButton(
      hoverColor: hoverColor,
      color: baseColor,
      onPressed: () => config.onLinkTap?.call(url, label),
      text: label,
      config: config,
      spanBuilder: (color) {
        final spanStyle = (config.style ?? const TextStyle()).copyWith(
          color: color,
          decorationColor: color,
          decoration: decoration,
          decorationThickness: linkStyleSpec.decorationThickness,
          fontWeight: linkStyleSpec.fontWeight,
        );
        return TextSpan(children: labelSpans(spanStyle), style: spanStyle);
      },
    ),
  );
}

/// Image component
class ImageMd extends InlineMd {
  @override
  RegExp get exp => RegExp(r"\!\[[^\[\]]*\]\([^\s]*\)");

  /// An image is not meaningful as a link label, and nesting its [WidgetSpan]
  /// inside the link's own one does not paint on iOS.
  @override
  Set<MarkdownScope> get scopes => MarkdownComponent.allScopesExceptLinkLabel;

  @override
  InlineSpan span(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    // First try to find the basic pattern
    final basicMatch = RegExp(r'\!\[([^\[\]]*)\]\(').firstMatch(text.trim());
    if (basicMatch == null) {
      return const TextSpan();
    }

    final altText = basicMatch.group(1) ?? '';
    final urlStart = basicMatch.end;

    // Now find the balanced closing parenthesis
    int parenCount = 0;
    int urlEnd = urlStart;

    for (int i = urlStart; i < text.length; i++) {
      final char = text[i];

      if (char == '(') {
        parenCount++;
      } else if (char == ')') {
        if (parenCount == 0) {
          // This is the closing parenthesis of the image
          urlEnd = i;
          break;
        } else {
          parenCount--;
        }
      }
    }

    if (urlEnd == urlStart) {
      // No closing parenthesis found
      return const TextSpan();
    }

    final url = text.substring(urlStart, urlEnd).trim();

    double? height;
    double? width;
    if (altText.isNotEmpty) {
      var size = RegExp(r"^([0-9]+)?x?([0-9]+)?").firstMatch(altText.trim());
      width = double.tryParse(size?[1]?.toString().trim() ?? 'a');
      height = double.tryParse(size?[2]?.toString().trim() ?? 'a');
    }

    return imageSpan(context, config, url: url, width: width, height: height);
  }
}

/// Table component
class TableMd extends BlockMd {
  /// A table cannot be a link label.
  @override
  Set<MarkdownScope> get scopes => MarkdownComponent.allScopesExceptLinkLabel;

  @override
  String get expString =>
      (r"(((\|[^\n\|]+\|)((([^\n\|]+\|)+)?)\ *)(\n\ *(((\|[^\n\|]+\|)(([^\n\|]+\|)+)?))\ *)+)$");
  @override
  Widget build(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    final tableStyle = (resolvedStyleSheet(context, config).table ??
            const TableStyle())
        .resolve(Theme.of(context).colorScheme);
    final tableRadius = tableStyle.borderRadius;
    final List<Map<int, String>> value =
        text
            .split('\n')
            .map<Map<int, String>>(
              (e) =>
                  e
                      .trim()
                      .split('|')
                      .where((element) => element.isNotEmpty)
                      .toList()
                      .asMap(),
            )
            .toList();

    // Check if table has a header and separator row
    bool hasHeader = value.length >= 2;
    List<TextAlign> columnAlignments = [];

    if (hasHeader) {
      // Parse alignment from the separator row (second row)
      var separatorRow = value[1];
      columnAlignments = List.generate(separatorRow.length, (index) {
        String separator = separatorRow[index] ?? "";
        separator = separator.trim();

        // Check for alignment indicators
        bool hasLeftColon = separator.startsWith(':');
        bool hasRightColon = separator.endsWith(':');

        if (hasLeftColon && hasRightColon) {
          return TextAlign.center;
        } else if (hasRightColon) {
          return TextAlign.right;
        } else if (hasLeftColon) {
          return TextAlign.left;
        } else {
          return TextAlign.left; // Default alignment
        }
      });
    }

    int maxCol = 0;
    for (final each in value) {
      if (maxCol < each.keys.length) {
        maxCol = each.keys.length;
      }
    }

    if (maxCol == 0) {
      return Text("", style: config.style);
    }

    // Ensure we have alignment for all columns
    while (columnAlignments.length < maxCol) {
      columnAlignments.add(TextAlign.left);
    }

    var tableBuilder = config.tableBuilder;

    if (tableBuilder != null) {
      var customTable =
          List<CustomTableRow?>.generate(value.length, (index) {
            var isHeader = index == 0;
            var row = value[index];
            if (row.isEmpty) {
              return null;
            }
            if (index == 1) {
              return null;
            }
            var fields = List<CustomTableField>.generate(maxCol, (index) {
              var field = row[index];
              return CustomTableField(
                data: field ?? "",
                alignment: columnAlignments[index],
              );
            });
            return CustomTableRow(isHeader: isHeader, fields: fields);
          }).nonNulls.toList();
      return tableBuilder(
        context,
        customTable,
        config.style ?? const TextStyle(),
        config,
      );
    }

    final controller = ScrollController();
    return Scrollbar(
      controller: controller,
      child: SingleChildScrollView(
        controller: controller,
        scrollDirection: Axis.horizontal,
        child: Table(
          textDirection: config.textDirection,
          defaultColumnWidth: CustomTableColumnWidth(),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          border: TableBorder.all(
            width: tableStyle.borderWidth ?? 1,
            color:
                tableStyle.borderColor ??
                Theme.of(context).colorScheme.onSurface,
            borderRadius:
                tableRadius == null
                    ? BorderRadius.zero
                    : BorderRadius.all(tableRadius),
          ),
          children:
              value
                  .asMap()
                  .entries
                  .where((entry) {
                    // Skip the separator row (second row) from rendering
                    if (hasHeader && entry.key == 1) {
                      return false;
                    }
                    return true;
                  })
                  .map<TableRow>(
                    (entry) => TableRow(
                      decoration:
                          (hasHeader && entry.key == 0)
                              ? BoxDecoration(
                                color:
                                    tableStyle.headerBackground ??
                                    Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                              )
                              : null,
                      children: List.generate(maxCol, (index) {
                        var e = entry.value;
                        String data = e[index] ?? "";
                        if (RegExp(r"^:?--+:?$").hasMatch(data.trim()) ||
                            data.trim().isEmpty) {
                          return const SizedBox();
                        }

                        // Apply alignment based on column alignment
                        Widget content = Padding(
                          padding:
                              tableStyle.cellPadding ??
                              const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                          child: MdWidget(
                            context,
                            (e[index] ?? "").trim(),
                            false,
                            config: config.copyWith(
                              scope: MarkdownScope.tableCell,
                            ),
                          ),
                        );

                        // Wrap with alignment widget
                        switch (columnAlignments[index]) {
                          case TextAlign.center:
                            content = Center(child: content);
                            break;
                          case TextAlign.right:
                            content = Align(
                              alignment: Alignment.centerRight,
                              child: content,
                            );
                            break;
                          case TextAlign.left:
                          default:
                            content = Align(
                              alignment: Alignment.centerLeft,
                              child: content,
                            );
                            break;
                        }

                        return content;
                      }),
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }
}

class CodeBlockMd extends BlockMd {
  @override
  String get expString => r"```(.*?)\n((.*?)(:?\n\s*?```)|(.*)(:?\n```)?)$";
  @override
  Widget build(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    String codes = this.exp.firstMatch(text)?[2] ?? "";
    String name = this.exp.firstMatch(text)?[1] ?? "";
    codes = codes.replaceAll(r"```", "");
    return codeBlockWidget(
      context,
      config,
      name: name,
      code: codes,
      closed: text.endsWith("```"),
    );
  }
}

class UnderLineMd extends InlineMd {
  @override
  RegExp get exp =>
      RegExp(r"<u>(.*?)(?:</u>|$)", multiLine: true, dotAll: true);

  @override
  InlineSpan span(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    var match = exp.firstMatch(text.trim());
    var conf = config.copyWith(
      style: (config.style ?? const TextStyle()).copyWith(
        decoration: TextDecoration.underline,
        decorationColor: config.style?.color,
      ),
    );
    return TextSpan(
      children: MarkdownComponent.generate(
        context,
        "${match?[1]}",
        conf,
        false,
      ),
      style: conf.style,
    );
  }
}

class CustomTableField {
  final String data;
  final TextAlign alignment;

  CustomTableField({required this.data, this.alignment = TextAlign.left});
}

class CustomTableRow {
  final bool isHeader;
  final List<CustomTableField> fields;

  CustomTableRow({this.isHeader = false, required this.fields});
}
