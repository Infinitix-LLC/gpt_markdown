part of 'gpt_markdown.dart';

/// Markdown components
abstract class MarkdownComponent {
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
    ATagMd(),
    ImageMd(),
    TableMd(),
    StrikeMd(),
    BoldMd(),
    ItalicMd(),
    LatexMath(),
    LatexMathMultiLine(),
    HighlightedText(),
    SourceTag(),
  ];

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
    List<InlineSpan> spans = [];
    Iterable<String> regexes = components.map<String>((e) => e.exp.pattern);
    final combinedRegex = RegExp(
      regexes.join("|"),
      multiLine: true,
      dotAll: true,
    );
    text.splitMapJoin(
      combinedRegex,
      onMatch: (p0) {
        String element = p0[0] ?? "";
        for (var each in components) {
          var p = each.exp.pattern;
          var exp = RegExp(
            '^$p\$',
            multiLine: each.exp.isMultiLine,
            dotAll: each.exp.isDotAll,
          );
          if (exp.hasMatch(element)) {
            spans.add(each.span(context, element, config));
            return "";
          }
        }
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
    return WidgetSpan(
      child: child,
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
    );
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
    var theme = GptMarkdownTheme.of(context);
    var match = this.exp.firstMatch(text.trim());
    var conf = config.copyWith(
      style: [
        theme.h1,
        theme.h2,
        theme.h3,
        theme.h4,
        theme.h5,
        theme.h6,
      ][match![1]!.length - 1]?.copyWith(color: config.style?.color),
    );
    return config.getRich(
      TextSpan(
        children: [
          ...(MarkdownComponent.generate(
            context,
            "${match.namedGroup('data')}",
            conf,
            false,
          )),
          if (match.namedGroup('hash')!.length == 1) ...[
            const TextSpan(
              text: "\n ",
              style: TextStyle(fontSize: 0, height: 0),
            ),
            WidgetSpan(
              child: CustomDivider(
                height: theme.hrLineThickness,
                color:
                    config.style?.color ??
                    Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ],
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
    var thickness = GptMarkdownTheme.of(context).hrLineThickness;
    var color = GptMarkdownTheme.of(context).hrLineColor;
    return CustomDivider(
      height: thickness,
      color: config.style?.color ?? color,
    );
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
    return CustomCb(
      value: ("${match?[1]}" == "x"),
      textDirection: config.textDirection,
      child: MdWidget(context, "${match?[2]}", false, config: config),
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
    return CustomRb(
      value: ("${match?[1]}" == "x"),
      textDirection: config.textDirection,
      child: MdWidget(context, "${match?[2]}", false, config: config),
    );
  }
}

/// Block quote component
class BlockQuote extends InlineMd {
  @override
  bool get inline => false;
  @override
  RegExp get exp =>
  // RegExp(r"(?<=\n\n)(\ +)(.+?)(?=\n\n)", dotAll: true, multiLine: true);
  RegExp(
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
    var child = TextSpan(
      children: MarkdownComponent.generate(context, data, config, true),
    );
    return TextSpan(
      children: [
        WidgetSpan(
          child: Directionality(
            textDirection: config.textDirection,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: BlockQuoteWidget(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                direction: config.textDirection,
                width: 3,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(start: 8.0),
                  child: config.getRich(child),
                ),
              ),
            ),
          ),
        ),
      ],
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

    return config.unOrderedListBuilder?.call(
          context,
          child,
          config.copyWith(),
        ) ??
        UnorderedListView(
          bulletColor:
              (config.style?.color ?? DefaultTextStyle.of(context).style.color),
          padding: 7,
          spacing: 10,
          bulletSize:
              0.3 *
              (config.style?.fontSize ??
                  DefaultTextStyle.of(context).style.fontSize ??
                  kDefaultFontSize),
          textDirection: config.textDirection,
          child: child,
        );
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
    var match = this.exp.firstMatch(text.trim());

    var no = "${match?[1]}";

    var child = MdWidget(context, "${match?[2]?.trim()}", true, config: config);
    return config.orderedListBuilder?.call(
          context,
          no,
          child,
          config.copyWith(),
        ) ??
        OrderedListView(
          no: "$no.",
          textDirection: config.textDirection,
          style: (config.style ?? const TextStyle()).copyWith(
            fontWeight: FontWeight.w100,
          ),
          child: child,
        );
  }
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
    var highlightedText = match?[1] ?? "";

    if (config.highlightBuilder != null) {
      return WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: config.highlightBuilder!(
          context,
          highlightedText,
          config.style ?? const TextStyle(),
        ),
      );
    }

    var style =
        config.style?.copyWith(
          fontWeight: FontWeight.bold,
          background:
              Paint()
                ..color = GptMarkdownTheme.of(context).highlightColor
                ..strokeCap = StrokeCap.round
                ..strokeJoin = StrokeJoin.round,
        ) ??
        TextStyle(
          fontWeight: FontWeight.bold,
          background:
              Paint()
                ..color = GptMarkdownTheme.of(context).highlightColor
                ..strokeCap = StrokeCap.round
                ..strokeJoin = StrokeJoin.round,
        );

    return TextSpan(text: highlightedText, style: style);
  }
}

/// Bold text component
class BoldMd extends InlineMd {
  @override
  RegExp get exp => RegExp(r"(?<!\*)\*\*(?<!\s)(.+?)(?<!\s)\*\*(?!\*)");

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
  String get expString => (r"\ *\\\[((?:.)*?)\\\]|(\ *\\begin.*?\\end{.*?})");
  // (r"\ *\\\[((?:(?!\n\n\n).)*?)\\\]|(\\begin.*?\\end{.*?})");
  @override
  RegExp get exp => RegExp(expString, dotAll: true, multiLine: true);

  @override
  Widget build(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    var p0 = exp.firstMatch(text.trim());
    String mathText = p0?[1] ?? p0?[2] ?? '';
    var workaround = config.latexWorkaround ?? (String tex) => tex;

    var builder =
        config.latexBuilder ??
        (BuildContext context, String tex, TextStyle textStyle, bool inline) =>
            SelectableAdapter(
              selectedText: tex,
              child: Math.tex(
                tex,
                textStyle: textStyle,
                mathStyle: MathStyle.display,
                textScaleFactor: 1,
                settings: const TexParserSettings(strict: Strict.ignore),
                options: MathOptions(
                  sizeUnderTextStyle: MathSize.large,
                  color:
                      config.style?.color ??
                      Theme.of(context).colorScheme.onSurface,
                  fontSize:
                      config.style?.fontSize ??
                      Theme.of(context).textTheme.bodyMedium?.fontSize,
                  mathFontOptions: FontOptions(
                    fontFamily: "Main",
                    fontWeight: config.style?.fontWeight ?? FontWeight.normal,
                    fontShape: FontStyle.normal,
                  ),
                  textFontOptions: FontOptions(
                    fontFamily: "Main",
                    fontWeight: config.style?.fontWeight ?? FontWeight.normal,
                    fontShape: FontStyle.normal,
                  ),
                  style: MathStyle.display,
                ),
                onErrorFallback: (err) {
                  return Text(
                    workaround(mathText),
                    textDirection: config.textDirection,
                    style: textStyle.copyWith(
                      color:
                          (!kDebugMode)
                              ? null
                              : Theme.of(context).colorScheme.error,
                    ),
                  );
                },
              ),
            );
    return builder(
      context,
      workaround(mathText),
      config.style ?? const TextStyle(),
      false,
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
    var workaround = config.latexWorkaround ?? (String tex) => tex;
    var builder =
        config.latexBuilder ??
        (BuildContext context, String tex, TextStyle textStyle, bool inline) =>
            SelectableAdapter(
              selectedText: tex,
              child: Math.tex(
                tex,
                textStyle: textStyle,
                mathStyle: MathStyle.display,
                textScaleFactor: 1,
                settings: const TexParserSettings(strict: Strict.ignore),
                options: MathOptions(
                  sizeUnderTextStyle: MathSize.large,
                  color:
                      config.style?.color ??
                      Theme.of(context).colorScheme.onSurface,
                  fontSize:
                      config.style?.fontSize ??
                      Theme.of(context).textTheme.bodyMedium?.fontSize,
                  mathFontOptions: FontOptions(
                    fontFamily: "Main",
                    fontWeight: config.style?.fontWeight ?? FontWeight.normal,
                    fontShape: FontStyle.normal,
                  ),
                  textFontOptions: FontOptions(
                    fontFamily: "Main",
                    fontWeight: config.style?.fontWeight ?? FontWeight.normal,
                    fontShape: FontStyle.normal,
                  ),
                  style: MathStyle.display,
                ),
                onErrorFallback: (err) {
                  return Text(
                    workaround(mathText),
                    textDirection: config.textDirection,
                    style: textStyle.copyWith(
                      color:
                          (!kDebugMode)
                              ? null
                              : Theme.of(context).colorScheme.error,
                    ),
                  );
                },
              ),
            );
    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: builder(
        context,
        workaround(mathText),
        config.style ?? const TextStyle(),
        true,
      ),
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
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child:
            config.sourceTagBuilder?.call(
              context,
              content,
              const TextStyle(),
            ) ??
            SizedBox(
              width: 20,
              height: 20,
              child: Material(
                color: Theme.of(context).colorScheme.onInverseSurface,
                shape: const OvalBorder(),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    content,
                    // style: (style ?? const TextStyle()).copyWith(),
                    textDirection: config.textDirection,
                  ),
                ),
              ),
            ),
      ),
    );
  }
}

/// Link text component
class ATagMd extends InlineMd {
  @override
  RegExp get exp => RegExp(r"(?<!\!)\[.*\]\([^\s]*\)");

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

    if (text[end + 1] != '(') {
      return const TextSpan();
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
      // No closing parenthesis found
      return const TextSpan();
    }

    final url = text.substring(urlStart, urlEnd).trim();

    var builder = config.linkBuilder;

    var ending = text.substring(urlEnd + 1);

    var endingSpans = MarkdownComponent.generate(
      context,
      ending,
      config,
      false,
    );
    var theme = GptMarkdownTheme.of(context);
    var linkTextSpan = TextSpan(
      text: linkText,
      style: config.style?.copyWith(
        color: theme.linkColor,
        decorationColor: theme.linkColor,
      ),
    );

    // Use custom builder if provided
    WidgetSpan? child;
    if (builder != null) {
      child = WidgetSpan(
        child: GestureDetector(
          onTap: () => config.onLinkTap?.call(url, linkText),
          child: builder(
            context,
            linkTextSpan,
            url,
            config.style ?? const TextStyle(),
          ),
        ),
      );
    }

    // Default rendering
    child ??= WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: LinkButton(
        hoverColor: theme.linkHoverColor,
        color: theme.linkColor,
        onPressed: () {
          config.onLinkTap?.call(url, linkText);
        },
        text: linkText,
        config: config,
        child: config.getRich(linkTextSpan),
      ),
    );
    var textSpan = TextSpan(children: [child, ...endingSpans]);
    return textSpan;
  }
}

/// Image component
class ImageMd extends InlineMd {
  @override
  RegExp get exp => RegExp(r"\!\[[^\[\]]*\]\([^\s]*\)");

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

    final Widget image;
    if (config.imageBuilder != null) {
      image = config.imageBuilder!(context, url);
    } else {
      image = SizedBox(
        width: width,
        height: height,
        child: Image(
          image: NetworkImage(url),
          loadingBuilder: (
            BuildContext context,
            Widget child,
            ImageChunkEvent? loadingProgress,
          ) {
            if (loadingProgress == null) {
              return child;
            }
            return CustomImageLoading(
              progress:
                  loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : 1,
            );
          },
          fit: BoxFit.fill,
          errorBuilder: (context, error, stackTrace) {
            return const CustomImageError();
          },
        ),
      );
    }
    return WidgetSpan(alignment: PlaceholderAlignment.bottom, child: image);
  }
}

/// Table component
class TableMd extends BlockMd {
  @override
  String get expString =>
      (r"(((\|[^\n\|]+\|)((([^\n\|]+\|)+)?)\ *)(\n\ *(((\|[^\n\|]+\|)(([^\n\|]+\|)+)?))\ *)+)$");
  @override
  Widget build(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
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
    bool heading = RegExp(
      r"^\|.*?\|\n\|-[-\\ |]*?-\|$",
      multiLine: true,
    ).hasMatch(text.trim());
    int maxCol = 0;
    for (final each in value) {
      if (maxCol < each.keys.length) {
        maxCol = each.keys.length;
      }
    }
    if (maxCol == 0) {
      return Text("", style: config.style);
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
            width: 1,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          children:
              value
                  .asMap()
                  .entries
                  .map<TableRow>(
                    (entry) => TableRow(
                      decoration:
                          (heading)
                              ? BoxDecoration(
                                color:
                                    (entry.key == 0)
                                        ? Theme.of(
                                          context,
                                        ).colorScheme.surfaceContainerHighest
                                        : null,
                              )
                              : null,
                      children: List.generate(maxCol, (index) {
                        var e = entry.value;
                        String data = e[index] ?? "";
                        if (RegExp(r"^:?--+:?$").hasMatch(data.trim()) ||
                            data.trim().isEmpty) {
                          return const SizedBox();
                        }

                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: MdWidget(
                              context,
                              (e[index] ?? "").trim(),
                              false,
                              config: config,
                            ),
                          ),
                        );
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
    codes = codes.replaceAll(r"```", "").trim();
    bool closed = text.endsWith("```");

    return config.codeBuilder?.call(context, name, codes, closed) ??
        CodeField(name: name, codes: codes);
  }
}
