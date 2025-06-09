part of 'gpt_markdown.dart';

/// Markdown components
abstract class MarkdownComponent {
  static List<MarkdownComponent> get components => [
        CodeBlockMd(),
        NewLines(),
        IndentMd(),
        ImageMd(),
        TableMd(),
        HTag(),
        UnOrderedList(),
        OrderedList(),
        RadioButtonMd(),
        CheckBoxMd(),
        HrLine(),
        LatexMath(),
        LatexMathMultiLine(),
        HighlightedText(),
        StrikeMd(),
        BoldMd(),
        ItalicMd(),
        ATagMd(),
        SourceTag(),
      ];

  /// Generate widget for markdown widget
  static List<InlineSpan> generate(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    List<InlineSpan> spans = [];
    List<String> regexes =
        components.map<String>((e) => e.exp.pattern).toList();
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
          if (each.exp.hasMatch(element)) {
            if (each.inline) {
              spans.add(each.span(
                context,
                element,
                config,
              ));
            } else {
              spans.addAll([
                TextSpan(
                  text: "\n ",
                  style: TextStyle(
                    fontSize: 0,
                    height: 0,
                    color: config.style?.color,
                  ),
                ),
                each.span(
                  context,
                  element,
                  config,
                ),
                TextSpan(
                  text: "\n ",
                  style: TextStyle(
                    fontSize: 0,
                    height: 0,
                    color: config.style?.color,
                  ),
                ),
              ]);
            }
            return "";
          }
        }
        return "";
      },
      onNonMatch: (p0) {
        spans.add(
          TextSpan(
            text: p0,
            style: config.style,
          ),
        );
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
  RegExp get exp => RegExp(
        r'^\ *?' + expString,
        dotAll: true,
        multiLine: true,
      );

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
    var child = build(
      context,
      text,
      config,
    );
    length = min(length, 4);
    if (length > 0) {
      child = UnorderedListView(
        spacing: length * 6.0,
        child: child,
      );
    }
    return WidgetSpan(
      child: child,
      alignment: PlaceholderAlignment.middle,
    );
  }

  Widget build(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  );
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
      ][match![1]!.length - 1]
          ?.copyWith(
        color: config.style?.color,
      ),
    );
    return config.getRich(
      TextSpan(
        children: [
          ...(MarkdownComponent.generate(
            context,
            "${match.namedGroup('data')}",
            conf,
          )),
          if (match.namedGroup('hash')!.length == 1) ...[
            const TextSpan(
              text: "\n ",
              style: TextStyle(fontSize: 0, height: 0),
            ),
            WidgetSpan(
              child: CustomDivider(
                height: theme.hrLineThickness,
                color: config.style?.color ??
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
      text: "\n\n\n\n",
      style: TextStyle(
        fontSize: 6,
        color: config.style?.color,
      ),
    );
  }
}

/// Horizontal line component
class HrLine extends BlockMd {
  @override
  String get expString => (r"(--)[-]+$");

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
  String get expString => (r"\[(\x?)\]\ (\S[^\n]*?)$");

  get onLinkTab => null;

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
      child: MdWidget(
        "${match?[2]}",
        config: config,
      ),
    );
  }
}

/// Radio Button component
class RadioButtonMd extends BlockMd {
  @override
  String get expString => (r"\((\x?)\)\ (\S[^\n]*)$");

  get onLinkTab => null;

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
      child: MdWidget(
        "${match?[2]}",
        config: config,
      ),
    );
  }
}

/// Indent
class IndentMd extends InlineMd {
  @override
  bool get inline => false;

  @override
  RegExp get exp =>
      // RegExp(r"(?<=\n\n)(\ +)(.+?)(?=\n\n)", dotAll: true, multiLine: true);
      RegExp(r"^>([^\n]+)$", dotAll: true, multiLine: true);

  @override
  InlineSpan span(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    var match = exp.firstMatch(text);
    var data = "${match?[1]}".trim();
    // data = data.replaceAll(RegExp(r'\n\ {' '$spaces' '}'), '\n').trim();
    data = data.trim();
    var child = TextSpan(
      children: MarkdownComponent.generate(
        context,
        data,
        config,
      ),
    );
    return TextSpan(
      children: [
        WidgetSpan(
          child: Directionality(
            textDirection: config.textDirection,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: IndentWidget(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                direction: config.textDirection,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(start: 10.0),
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
    return UnorderedListView(
      bulletColor:
          (config.style?.color ?? DefaultTextStyle.of(context).style.color),
      padding: 7,
      spacing: 10,
      bulletSize: 0.3 *
          (config.style?.fontSize ??
              DefaultTextStyle.of(context).style.fontSize ??
              kDefaultFontSize),
      textDirection: config.textDirection,
      child: MdWidget(
        "${match?[1]}",
        config: config,
      ),
    );
  }
}

/// Ordered list component
class OrderedList extends BlockMd {
  @override
  String get expString => (r"([0-9]+\.)\ ([^\n]+)$");

  @override
  Widget build(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    var match = this.exp.firstMatch(text.trim());
    return OrderedListView(
      no: "${match?[1]}",
      textDirection: config.textDirection,
      style: (config.style ?? const TextStyle())
          .copyWith(fontWeight: FontWeight.w100),
      child: MdWidget(
        "${match?[2]}",
        config: config,
      ),
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

    var style = config.style?.copyWith(
          fontWeight: FontWeight.bold,
          background: Paint()
            ..color = GptMarkdownTheme.of(context).highlightColor
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        ) ??
        TextStyle(
          fontWeight: FontWeight.bold,
          background: Paint()
            ..color = GptMarkdownTheme.of(context).highlightColor
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );

    return TextSpan(
      text: highlightedText,
      style: style,
    );
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
        style: config.style?.copyWith(fontWeight: FontWeight.bold) ??
            const TextStyle(fontWeight: FontWeight.bold));
    return TextSpan(
      children: MarkdownComponent.generate(
        context,
        "${match?[1]}",
        conf,
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
        style: config.style?.copyWith(
              decoration: TextDecoration.lineThrough,
              decorationColor: config.style?.color,
            ) ??
            const TextStyle(
              decoration: TextDecoration.lineThrough,
            ));
    return TextSpan(
      children: MarkdownComponent.generate(
        context,
        "${match?[1]}",
        conf,
      ),
      style: conf.style,
    );
  }
}

/// Italic text component
class ItalicMd extends InlineMd {
  @override
  RegExp get exp =>
      RegExp(r"(?<!\*)\*(?<!\s)(.+?)(?<!\s)\*(?!\*)|\_(?<!\s)(.+?)(?<!\s)\_",
          dotAll: true);

  @override
  InlineSpan span(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    var match = exp.firstMatch(text.trim());
    var data = match?[1] ?? match?[2];
    var conf = config.copyWith(
        style: (config.style ?? const TextStyle())
            .copyWith(fontStyle: FontStyle.italic));
    return TextSpan(
      children: MarkdownComponent.generate(
        context,
        "$data",
        conf,
      ),
      style: conf.style,
    );
  }
}

class LatexMathMultiLine extends BlockMd {
  @override
  String get expString => (r"\\\[(((?!\n\n).)*?)\\\]|(\\begin.*?\\end{.*?})");

  @override
  RegExp get exp => RegExp(expString, dotAll: true, multiLine: true);

  @override
  Widget build(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    var p0 = exp.firstMatch(text.trim());
    String mathText = p0?[1] ?? p0?[2] ?? "";
    var workaround = config.latexWorkaround ?? (String tex) => tex;

    var builder = config.latexBuilder ??
        (BuildContext context, String tex, TextStyle textStyle, bool inline) =>
            SelectableAdapter(
              selectedText: tex,
              child: Math.tex(
                tex,
                textStyle: textStyle,
                mathStyle: MathStyle.display,
                textScaleFactor: 1,
                settings: const TexParserSettings(
                  strict: Strict.ignore,
                ),
                options: MathOptions(
                  sizeUnderTextStyle: MathSize.large,
                  color: config.style?.color ??
                      Theme.of(context).colorScheme.onSurface,
                  fontSize: config.style?.fontSize ??
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
                        color: (!kDebugMode)
                            ? null
                            : Theme.of(context).colorScheme.error),
                  );
                },
              ),
            );
    return builder(context, workaround(mathText),
        config.style ?? const TextStyle(), false);
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
    var builder = config.latexBuilder ??
        (BuildContext context, String tex, TextStyle textStyle, bool inline) =>
            SelectableAdapter(
              selectedText: tex,
              child: Math.tex(
                tex,
                textStyle: textStyle,
                mathStyle: MathStyle.display,
                textScaleFactor: 1,
                settings: const TexParserSettings(
                  strict: Strict.ignore,
                ),
                options: MathOptions(
                  sizeUnderTextStyle: MathSize.large,
                  color: config.style?.color ??
                      Theme.of(context).colorScheme.onSurface,
                  fontSize: config.style?.fontSize ??
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
                        color: (!kDebugMode)
                            ? null
                            : Theme.of(context).colorScheme.error),
                  );
                },
              ),
            );
    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: builder(context, workaround(mathText),
          config.style ?? const TextStyle(), true),
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
        child: config.sourceTagBuilder
                ?.call(context, content, const TextStyle()) ??
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
  RegExp get exp =>
      RegExp(r"(?<!!)\[((?:[^\]\n]|\\\])*)\]\(((?:[^)\n]|\\\))*)\)");

  @override
  InlineSpan span(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    var match = exp.firstMatch(text.trim());
    if (match?[1] == null && match?[2] == null) {
      return const TextSpan();
    }

    final linkText = match?[1] ?? "";
    final url = match?[2] ?? "";

    // Use custom builder if provided
    if (config.linkBuilder != null) {
      return WidgetSpan(
        child: GestureDetector(
          onTap: () => config.onLinkTab?.call(url, linkText),
          child: config.linkBuilder!(
            context,
            linkText,
            url,
            config.style ?? const TextStyle(),
          ),
        ),
      );
    }

    // Default rendering
    var theme = GptMarkdownTheme.of(context);
    return WidgetSpan(
      child: LinkButton(
        hoverColor: theme.linkHoverColor,
        color: theme.linkColor,
        onPressed: () {
          config.onLinkTab?.call(url, linkText);
        },
        text: linkText,
        config: config,
      ),
    );
  }
}

/// Image component
class ImageMd extends InlineMd {
  @override
  RegExp get exp => RegExp(r"!\[([^\]]*)\]\((?<url>[^)]+)\)");

  @override
  InlineSpan span(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    var match = exp.firstMatch(text.trim());
    final url = match?.namedGroup('url');
    if (url == null || url.isEmpty) {
      return const TextSpan();
    }

    // double? height;
    // double? width;
    // if (match?[1] != null) {
    //   var size = RegExp(r"^([0-9]+)?x?([0-9]+)?")
    //       .firstMatch(match![1].toString().trim());
    //   width = double.tryParse(size?[1]?.toString().trim() ?? 'a');
    //   height = double.tryParse(size?[2]?.toString().trim() ?? 'a');
    // }

    return WidgetSpan(
      alignment: PlaceholderAlignment.bottom,
      child: Image(
        image: NetworkImage(url),
        loadingBuilder: (BuildContext context, Widget child,
            ImageChunkEvent? loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return CustomImageLoading(
            progress: loadingProgress.expectedTotalBytes != null
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
}

/// Table component
class TableMd extends BlockMd {
  @override
  String get expString =>
      (r"(((\|[^\n\|]+\|)((([^\n\|]+\|)+)?))(\n(((\|[^\n\|]+\|)(([^\n\|]+\|)+)?)))+)$");

  @override
  Widget build(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    final List<Map<int, String>> value = text
        .split('\n')
        .map<Map<int, String>>(
          (e) => e
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
          children: value
              .asMap()
              .entries
              .map<TableRow>(
                (entry) => TableRow(
                  decoration: (heading)
                      ? BoxDecoration(
                          color: (entry.key == 0)
                              ? Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                              : null,
                        )
                      : null,
                  children: List.generate(
                    maxCol,
                    (index) {
                      var e = entry.value;
                      String data = e[index] ?? "";
                      if (RegExp(r"^--+$").hasMatch(data.trim()) ||
                          data.trim().isEmpty) {
                        return const SizedBox();
                      }

                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: MdWidget(
                            (e[index] ?? "").trim(),
                            config: config,
                          ),
                        ),
                      );
                    },
                  ),
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
