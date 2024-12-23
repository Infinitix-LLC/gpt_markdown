import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:gpt_markdown/custom_widgets/custom_divider.dart';
import 'package:gpt_markdown/custom_widgets/custom_error_image.dart';
import 'package:gpt_markdown/custom_widgets/custom_rb_cb.dart';
import 'package:gpt_markdown/custom_widgets/markdow_config.dart';
import 'package:gpt_markdown/custom_widgets/unordered_ordered_list.dart';
import 'md_widget.dart';

/// Markdown components
abstract class MarkdownComponent {
  static List<MarkdownComponent> get components => [
        CodeBlockMd(),
        NewLines(),
        TableMd(),
        HTag(),
        IndentMd(),
        UnOrderedList(),
        OrderedList(),
        RadioButtonMd(),
        CheckBoxMd(),
        HrLine(),
        ImageMd(),
        HighlightedText(),
        StrikeMd(),
        BoldMd(),
        ItalicMd(),
        LatexMathMultyLine(),
        LatexMath(),
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

    List<MarkdownComponent> combinedComponenets = [
      ...config.customComponents,
      ...components,
    ];

    List<String> regexes =
        combinedComponenets.map<String>((e) => e.exp.pattern).toList();
    final combinedRegex = RegExp(
      regexes.join("|"),
      multiLine: true,
      dotAll: true,
    );
    List<String> elements = [];
    text.splitMapJoin(
      combinedRegex,
      onMatch: (p0) {
        String element = p0[0] ?? "";
        elements.add(element);
        for (var each in combinedComponenets) {
          if (each.exp.hasMatch(element)) {
            if (each is InlineMd) {
              spans.add(each.span(
                context,
                element,
                config,
              ));
            } else {
              if (each is BlockMd) {
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
  InlineSpan span(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    return WidgetSpan(
      child: build(
        context,
        text,
        config,
      ),
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
  RegExp get exp => RegExp(r"^(#{1,6})\ ([^\n]+?)$");
  @override
  Widget build(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    var match = exp.firstMatch(text.trim());
    var conf = config.copyWith(
        style: [
      Theme.of(context)
          .textTheme
          .headlineLarge
          ?.copyWith(color: config.style?.color),
      Theme.of(context)
          .textTheme
          .headlineMedium
          ?.copyWith(color: config.style?.color),
      Theme.of(context)
          .textTheme
          .headlineSmall
          ?.copyWith(color: config.style?.color),
      Theme.of(context)
          .textTheme
          .titleLarge
          ?.copyWith(color: config.style?.color),
      Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(color: config.style?.color),
      Theme.of(context)
          .textTheme
          .titleSmall
          ?.copyWith(color: config.style?.color),
    ][match![1]!.length - 1]);
    return config.getRich(
      TextSpan(
        children: [
          ...(MarkdownComponent.generate(
            context,
            "${match[2]}",
            conf,
          )),
          if (match[1]!.length == 1) ...[
            const TextSpan(
              text: "\n ",
              style: TextStyle(fontSize: 0, height: 0),
            ),
            WidgetSpan(
              child: CustomDivider(
                height: 2,
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
  RegExp get exp => RegExp(r"""\n\n+""");
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
  RegExp get exp => RegExp(r"^(--)[-]+$");
  @override
  Widget build(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    return CustomDivider(
      height: 2,
      color: config.style?.color ?? Theme.of(context).colorScheme.outline,
    );
  }
}

/// Checkbox component
class CheckBoxMd extends BlockMd {
  @override
  RegExp get exp => RegExp(r"^\[(\x?)\]\ (\S[^\n]*?)$");
  get onLinkTab => null;

  @override
  Widget build(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    var match = exp.firstMatch(text.trim());
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
  RegExp get exp => RegExp(r"^\((\x?)\)\ (\S[^\n]*)$");
  get onLinkTab => null;

  @override
  Widget build(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    var match = exp.firstMatch(text.trim());
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
class IndentMd extends BlockMd {
  @override
  RegExp get exp => RegExp(r"^(\ +)([^\n]+)$");
  get onLinkTab => null;

  @override
  Widget build(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    [
      r"\\\[(.*?)\\\]",
      r"\\\((.*?)\\\)",
      r"(?<!\\)\$((?:\\.|[^$])*?)\$(?!\\)",
    ].join("|");
    var match = exp.firstMatch(text);
    int spaces = (match?[1] ?? "").length;
    return UnorderedListView(
      bulletColor: config.style?.color,
      padding: spaces * 5,
      bulletSize: 0,
      textDirection: config.textDirection,
      child: Text.rich(TextSpan(
        children: MarkdownComponent.generate(
          context,
          "${match?[2]}",
          config,
        ),
      )),
    );
  }
}

/// Unordered list component
class UnOrderedList extends BlockMd {
  @override
  RegExp get exp => RegExp(r"^(?:\-|\*)\ ([^\n]+)$");
  get onLinkTab => null;

  @override
  Widget build(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    var match = exp.firstMatch(text);
    return UnorderedListView(
      bulletColor:
          config.style?.color ?? DefaultTextStyle.of(context).style.color,
      padding: 10.0,
      bulletSize: 0.4 *
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
  RegExp get exp => RegExp(r"^([0-9]+\.)\ ([^\n]+)$");

  get onLinkTab => null;

  @override
  Widget build(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    var match = exp.firstMatch(text.trim());
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
  RegExp get exp => RegExp(r"`(.+?)`");

  @override
  InlineSpan span(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    var match = exp.firstMatch(text.trim());
    var conf = config.copyWith(
      style: config.style?.copyWith(
            fontWeight: FontWeight.bold,
            background: Paint()
              ..color = Theme.of(context).colorScheme.onInverseSurface
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round,
          ) ??
          TextStyle(
            fontWeight: FontWeight.bold,
            background: Paint()
              ..color = Theme.of(context).colorScheme.surfaceContainerHighest
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round,
          ),
    );
    return TextSpan(
      text: match?[1],
      style: conf.style,
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
      RegExp(r"(?<!\*)\*(?<!\s)(.+?)(?<!\s)\*(?!\*)", dotAll: true);

  @override
  InlineSpan span(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    var match = exp.firstMatch(text.trim());
    var conf = config.copyWith(
        style: (config.style ?? const TextStyle())
            .copyWith(fontStyle: FontStyle.italic));
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

class LatexMathMultyLine extends BlockMd {
  @override
  RegExp get exp => RegExp(
        r"\\\[(.*?)\\\]|(\\begin.*?\\end{.*?})",
        dotAll: true,
      );

  @override
  Widget build(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    var p0 = exp.firstMatch(text.trim());
    p0?.group(0);
    String mathText = p0?[1] ?? p0?[2] ?? "";
    var workaround = config.latexWorkaround ?? (String tex) => tex;

    var builder = config.latexBuilder ??
        (BuildContext context, String tex, TextStyle textStyle, bool inline) =>
            Math.tex(
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
            Math.tex(
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
      // baseline: TextBaseline.alphabetic,
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
  RegExp get exp => RegExp(r"\[([^\s\*][^\n]*?[^\s]?)?\]\(([^\s\*]+)?\)");

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
    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: GestureDetector(
        onTap: () {
          config.onLinkTab?.call("${match?[2]}", "${match?[1]}");
        },
        child: config.getRich(
          TextSpan(
            text: "${match?[1]}",
            style: (config.style ?? const TextStyle()).copyWith(
              color: Colors.blueAccent,
              decorationColor: Colors.blue,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ),
    );
  }
}

/// Image component
class ImageMd extends InlineMd {
  @override
  RegExp get exp => RegExp(r"\!\[([^\s][^\n]*[^\s]?)?\]\(([^\s]+)\)");

  @override
  InlineSpan span(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    var match = exp.firstMatch(text.trim());
    double? height;
    double? width;
    if (match?[1] != null) {
      var size = RegExp(r"^([0-9]+)?x?([0-9]+)?")
          .firstMatch(match![1].toString().trim());
      width = double.tryParse(size?[1]?.toString().trim() ?? 'a');
      height = double.tryParse(size?[2]?.toString().trim() ?? 'a');
    }
    return WidgetSpan(
      alignment: PlaceholderAlignment.bottom,
      child: SizedBox(
        width: width,
        height: height,
        child: Image(
          image: NetworkImage(
            "${match?[2]}",
          ),
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
      ),
    );
  }
}

/// Table component
class TableMd extends BlockMd {
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

  @override
  RegExp get exp => RegExp(
        r"^(((\|[^\n\|]+\|)((([^\n\|]+\|)+)?))(\n(((\|[^\n\|]+\|)(([^\n\|]+\|)+)?)))+)$",
      );
}

class CodeBlockMd extends BlockMd {
  @override
  RegExp get exp => RegExp(
        r"\s*?```(.*?)\n((.*?)(:?\n\s*?```)|(.*)(:?\n```)?)$",
        multiLine: true,
        dotAll: true,
      );
  @override
  Widget build(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    String codes = exp.firstMatch(text)?[2] ?? "";
    String name = exp.firstMatch(text)?[1] ?? "";
    codes = codes.replaceAll(r"```", "").trim();
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: config.codeBuilder != null
          ? config.codeBuilder?.call(context, name, codes)
          : CodeField(name: name, codes: codes),
    );
  }
}

class CodeField extends StatefulWidget {
  const CodeField({super.key, required this.name, required this.codes});
  final String name;
  final String codes;

  @override
  State<CodeField> createState() => _CodeFieldState();
}

class _CodeFieldState extends State<CodeField> {
  bool _copied = false;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.onInverseSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: Text(widget.name),
              ),
              const Spacer(),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.normal,
                  ),
                ),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: widget.codes))
                      .then((value) {
                    setState(() {
                      _copied = true;
                    });
                  });
                  await Future.delayed(const Duration(seconds: 2));
                  setState(() {
                    _copied = false;
                  });
                },
                icon: Icon(
                  (_copied) ? Icons.done : Icons.content_paste,
                  size: 15,
                ),
                label: Text((_copied) ? "Copied!" : "Copy code"),
              ),
            ],
          ),
          const Divider(
            height: 1,
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Text(
              widget.codes,
            ),
          ),
        ],
      ),
    );
  }
}
