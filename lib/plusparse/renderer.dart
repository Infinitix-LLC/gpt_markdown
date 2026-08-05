part of '../gpt_markdown.dart';

/// Renders a plusparse [MdDocument] AST into the same `InlineSpan` tree the
/// regex pipeline (`MarkdownComponent.generate`) produces — same custom
/// widgets ([CodeField], [UnorderedListView], [LinkButton], [CustomCb], …),
/// same theme handling, same config builder hooks. Parsing is a single pass
/// over the text instead of recursive combined-regex scanning, which is what
/// makes re-rendering streaming LLM output cheap.
class PlusparseRenderer {
  PlusparseRenderer._();

  /// Parses [text] and renders it to spans. When [inlineOnly] is true (the
  /// old `includeGlobalComponents: false` mode used for nested content such
  /// as table cells), a single-paragraph document is unwrapped to its inline
  /// spans instead of being treated as a block.
  static List<InlineSpan> render(
    BuildContext context,
    String text,
    GptMarkdownConfig config, {
    bool inlineOnly = false,
  }) {
    final doc = Plusparse.parse(text);
    if (inlineOnly &&
        doc.children.length == 1 &&
        doc.children.first is MdParagraph) {
      return _inlineSpans(
        context,
        (doc.children.first as MdParagraph).children,
        config,
      );
    }
    return _blockSpans(context, doc.children, config);
  }

  // ---------------------------------------------------------------------
  // Block level
  // ---------------------------------------------------------------------

  /// The paragraph-break span the regex pipeline's `NewLines` component emits.
  static TextSpan _paragraphBreak(GptMarkdownConfig config) => TextSpan(
    text: "\n\n",
    style: TextStyle(
      fontSize: config.style?.fontSize ?? 14,
      height: 1.15,
      color: config.style?.color,
    ),
  );

  /// Replicates `BlockMd.span`'s wrapping of a block widget.
  static InlineSpan _blockSpan(Widget child) => WidgetSpan(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [Flexible(child: child)],
    ),
    alignment: PlaceholderAlignment.baseline,
    baseline: TextBaseline.alphabetic,
  );

  static List<InlineSpan> _blockSpans(
    BuildContext context,
    List<MdNode> blocks,
    GptMarkdownConfig config, {
    String separator = "\n\n",
  }) {
    final spans = <InlineSpan>[];
    for (final node in blocks) {
      if (spans.isNotEmpty) {
        spans.add(
          separator == "\n\n"
              ? _paragraphBreak(config)
              : TextSpan(text: separator, style: config.style),
        );
      }
      spans.addAll(_block(context, node, config));
    }
    return spans;
  }

  static List<InlineSpan> _block(
    BuildContext context,
    MdNode node,
    GptMarkdownConfig config,
  ) {
    switch (node) {
      case MdParagraph(:final children):
        return _inlineSpans(context, children, config);
      case MdHeading():
        return [_blockSpan(_heading(context, node, config))];
      case MdHorizontalRule():
        final theme = GptMarkdownTheme.of(context);
        return [
          _blockSpan(
            CustomDivider(
              height: theme.hrLineThickness,
              color: theme.hrLineColor,
              padding: theme.hrLinePadding,
            ),
          ),
        ];
      case MdCodeBlock(:final language, :final code, :final closed):
        return [
          _blockSpan(
            config.codeBuilder?.call(context, language, code, closed) ??
                CodeField(name: language, codes: code),
          ),
        ];
      case MdBlockLatex(:final tex):
        return [_blockSpan(_latex(context, tex, config, inline: false))];
      case MdBlockQuote(:final children):
        return [_blockQuote(context, children, config)];
      case MdCheckbox(:final checked, :final children):
        return [
          _blockSpan(
            CustomCb(
              value: checked,
              textDirection: config.textDirection,
              child: config.getRich(
                TextSpan(children: _inlineSpans(context, children, config)),
              ),
            ),
          ),
        ];
      case MdRadio(:final selected, :final children):
        return [
          _blockSpan(
            CustomRb(
              value: selected,
              textDirection: config.textDirection,
              child: config.getRich(
                TextSpan(children: _inlineSpans(context, children, config)),
              ),
            ),
          ),
        ];
      case MdUnorderedList(:final items):
        return _list(context, items, config, ordered: false, start: 1);
      case MdOrderedList(:final start, :final items):
        return _list(context, items, config, ordered: true, start: start);
      case MdTable():
        return [_table(context, node, config)];
      // Inline nodes reaching block position (defensive; parser does not
      // produce this) render as inline content.
      default:
        return _inlineSpans(context, [node], config);
    }
  }

  static Widget _heading(
    BuildContext context,
    MdHeading node,
    GptMarkdownConfig config,
  ) {
    final theme = GptMarkdownTheme.of(context);
    final conf = config.copyWith(
      style:
          [
            theme.h1,
            theme.h2,
            theme.h3,
            theme.h4,
            theme.h5,
            theme.h6,
          ][node.level - 1],
    );
    return conf.getRich(
      TextSpan(
        children: [
          ..._inlineSpans(context, node.children, conf),
          if (node.level == 1 && theme.autoAddDividerLineAfterH1) ...[
            const TextSpan(
              text: "\n ",
              style: TextStyle(fontSize: 0, height: 0),
            ),
            WidgetSpan(
              child: CustomDivider(
                height: theme.hrLineThickness,
                color: theme.hrLineColor,
                padding: theme.hrLinePadding,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static InlineSpan _blockQuote(
    BuildContext context,
    List<MdNode> children,
    GptMarkdownConfig config,
  ) {
    final child = TextSpan(
      children: _blockSpans(context, children, config),
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

  static List<InlineSpan> _list(
    BuildContext context,
    List<MdListItem> items,
    GptMarkdownConfig config, {
    required bool ordered,
    required int start,
  }) {
    final spans = <InlineSpan>[];
    for (var i = 0; i < items.length; i++) {
      if (spans.isNotEmpty) {
        spans.add(TextSpan(text: "\n", style: config.style));
      }
      // An item's children are its inline content followed by any nested
      // blocks (e.g. a nested list); render them into one rich child.
      final item = items[i];
      final inline = <MdNode>[];
      final nested = <MdNode>[];
      for (final n in item.children) {
        (_isInline(n) && nested.isEmpty ? inline : nested).add(n);
      }
      final itemChild = config.getRich(
        TextSpan(
          children: [
            ..._inlineSpans(context, inline, config),
            if (nested.isNotEmpty) ...[
              TextSpan(text: "\n", style: config.style),
              ..._blockSpans(context, nested, config, separator: "\n"),
            ],
          ],
        ),
      );
      if (ordered) {
        final no = "${item.number ?? (start + i)}";
        spans.add(
          _blockSpan(
            config.orderedListBuilder?.call(
                  context,
                  no,
                  itemChild,
                  config.copyWith(),
                ) ??
                OrderedListView(
                  no: "$no.",
                  textDirection: config.textDirection,
                  style: (config.style ?? const TextStyle()).copyWith(
                    fontWeight: FontWeight.w100,
                  ),
                  child: itemChild,
                ),
          ),
        );
      } else {
        spans.add(
          _blockSpan(
            config.unOrderedListBuilder?.call(
                  context,
                  itemChild,
                  config.copyWith(),
                ) ??
                UnorderedListView(
                  bulletColor:
                      (config.style?.color ??
                          DefaultTextStyle.of(context).style.color),
                  padding: 7,
                  spacing: 10,
                  bulletSize:
                      0.3 *
                      (config.style?.fontSize ??
                          DefaultTextStyle.of(context).style.fontSize ??
                          kDefaultFontSize),
                  textDirection: config.textDirection,
                  child: itemChild,
                ),
          ),
        );
      }
    }
    return spans;
  }

  static bool _isInline(MdNode n) => switch (n) {
    MdText() ||
    MdBold() ||
    MdItalic() ||
    MdStrike() ||
    MdUnderline() ||
    MdInlineCode() ||
    MdInlineLatex() ||
    MdLink() ||
    MdImage() ||
    MdSourceTag() ||
    MdLineBreak() => true,
    _ => false,
  };

  static InlineSpan _table(
    BuildContext context,
    MdTable node,
    GptMarkdownConfig config,
  ) {
    final rows = [node.header, ...node.rows];
    var maxCol = 0;
    for (final row in rows) {
      maxCol = max(maxCol, row.cells.length);
    }
    if (maxCol == 0) {
      return TextSpan(text: "", style: config.style);
    }

    final columnAlignments = List<TextAlign>.generate(maxCol, (i) {
      final align = i < node.aligns.length ? node.aligns[i] : MdAlign.none;
      return switch (align) {
        MdAlign.center => TextAlign.center,
        MdAlign.right => TextAlign.right,
        _ => TextAlign.left,
      };
    });

    final tableBuilder = config.tableBuilder;
    if (tableBuilder != null) {
      final customTable = List<CustomTableRow>.generate(rows.length, (index) {
        final row = rows[index];
        final fields = List<CustomTableField>.generate(maxCol, (col) {
          return CustomTableField(
            data: col < row.cells.length
                ? _plainText(row.cells[col].content)
                : "",
            alignment: columnAlignments[col],
          );
        });
        return CustomTableRow(isHeader: index == 0, fields: fields);
      });
      return _blockSpan(
        tableBuilder(
          context,
          customTable,
          config.style ?? const TextStyle(),
          config,
        ),
      );
    }

    final controller = ScrollController();
    return _blockSpan(
      Scrollbar(
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
            children: List<TableRow>.generate(rows.length, (index) {
              final row = rows[index];
              return TableRow(
                decoration: index == 0
                    ? BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                      )
                    : null,
                children: List<Widget>.generate(maxCol, (col) {
                  final cell = col < row.cells.length
                      ? row.cells[col]
                      : null;
                  if (cell == null || cell.content.isEmpty) {
                    return const SizedBox();
                  }
                  Widget content = Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: config.getRich(
                      TextSpan(
                        children: _inlineSpans(context, cell.content, config),
                      ),
                    ),
                  );
                  switch (columnAlignments[col]) {
                    case TextAlign.center:
                      content = Center(child: content);
                      break;
                    case TextAlign.right:
                      content = Align(
                        alignment: Alignment.centerRight,
                        child: content,
                      );
                      break;
                    default:
                      content = Align(
                        alignment: Alignment.centerLeft,
                        child: content,
                      );
                      break;
                  }
                  return content;
                }),
              );
            }),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Inline level
  // ---------------------------------------------------------------------

  static List<InlineSpan> _inlineSpans(
    BuildContext context,
    List<MdNode> nodes,
    GptMarkdownConfig config,
  ) {
    final spans = <InlineSpan>[];
    for (final node in nodes) {
      spans.add(_inline(context, node, config));
    }
    return spans;
  }

  static InlineSpan _inline(
    BuildContext context,
    MdNode node,
    GptMarkdownConfig config,
  ) {
    switch (node) {
      case MdText(:final text):
        return TextSpan(text: text, style: config.style);
      case MdLineBreak():
        return TextSpan(text: "\n", style: config.style);
      case MdBold(:final children):
        final conf = config.copyWith(
          style:
              config.style?.copyWith(fontWeight: FontWeight.bold) ??
              const TextStyle(fontWeight: FontWeight.bold),
        );
        return TextSpan(
          children: _inlineSpans(context, children, conf),
          style: conf.style,
        );
      case MdItalic(:final children):
        final conf = config.copyWith(
          style: (config.style ?? const TextStyle()).copyWith(
            fontStyle: FontStyle.italic,
          ),
        );
        return TextSpan(
          children: _inlineSpans(context, children, conf),
          style: conf.style,
        );
      case MdStrike(:final children):
        final conf = config.copyWith(
          style:
              config.style?.copyWith(
                decoration: TextDecoration.lineThrough,
                decorationColor: config.style?.color,
              ) ??
              const TextStyle(decoration: TextDecoration.lineThrough),
        );
        return TextSpan(
          children: _inlineSpans(context, children, conf),
          style: conf.style,
        );
      case MdUnderline(:final children):
        final conf = config.copyWith(
          style: (config.style ?? const TextStyle()).copyWith(
            decoration: TextDecoration.underline,
            decorationColor: config.style?.color,
          ),
        );
        return TextSpan(
          children: _inlineSpans(context, children, conf),
          style: conf.style,
        );
      case MdInlineCode(:final text):
        return _inlineCode(context, text, config);
      case MdInlineLatex(:final tex):
        return WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: _latex(context, tex, config, inline: true),
        );
      case MdLink(:final children, :final url):
        return _link(context, children, url, config);
      case MdImage():
        return _image(context, node, config);
      case MdSourceTag(:final id):
        return _sourceTag(context, id, config);
      case MdGenUi(:final payload):
        final builder = config.genUiBuilder;
        if (builder == null) {
          return TextSpan(text: payload, style: config.style);
        }
        return WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: builder(context, payload),
        );
      // Block nodes in inline position (nested content) fall back to their
      // block rendering.
      default:
        final blocks = _block(context, node, config);
        return blocks.length == 1
            ? blocks.first
            : TextSpan(children: blocks);
    }
  }

  static InlineSpan _inlineCode(
    BuildContext context,
    String text,
    GptMarkdownConfig config,
  ) {
    if (config.highlightBuilder != null) {
      return WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: config.highlightBuilder!(
          context,
          text,
          config.style ?? const TextStyle(),
        ),
      );
    }
    final style =
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
    return TextSpan(text: text, style: style);
  }

  static Widget _latex(
    BuildContext context,
    String tex,
    GptMarkdownConfig config, {
    required bool inline,
  }) {
    final workaround = config.latexWorkaround ?? (String tex) => tex;
    final builder =
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
                    workaround(tex),
                    textDirection: config.textDirection,
                    style: (config.style ?? const TextStyle()).copyWith(
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
      workaround(tex),
      config.style ?? const TextStyle(),
      inline,
    );
  }

  static InlineSpan _link(
    BuildContext context,
    List<MdNode> children,
    String url,
    GptMarkdownConfig config,
  ) {
    final linkText = _plainText(children);
    final theme = GptMarkdownTheme.of(context);
    final builder = config.linkBuilder;

    if (builder != null) {
      final linkStyle = (config.style ?? const TextStyle()).copyWith(
        color: theme.linkColor,
        decorationColor: theme.linkColor,
        decoration: TextDecoration.underline,
      );
      final linkConfig = config.copyWith(style: linkStyle);
      final linkTextSpan = TextSpan(
        children: _inlineSpans(context, children, linkConfig),
        style: linkStyle,
      );
      return WidgetSpan(
        baseline: TextBaseline.alphabetic,
        alignment: PlaceholderAlignment.baseline,
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

    return WidgetSpan(
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
        spanBuilder: (color) {
          final spanStyle = (config.style ?? const TextStyle()).copyWith(
            color: color,
            decorationColor: color,
            decoration: TextDecoration.underline,
          );
          return TextSpan(
            children: _inlineSpans(
              context,
              children,
              config.copyWith(style: spanStyle),
            ),
            style: spanStyle,
          );
        },
      ),
    );
  }

  static InlineSpan _image(
    BuildContext context,
    MdImage node,
    GptMarkdownConfig config,
  ) {
    final Widget image;
    if (config.imageBuilder != null) {
      image = config.imageBuilder!(context, node.url, node.width, node.height);
    } else {
      image = SizedBox(
        width: node.width,
        height: node.height,
        child: Image(
          image: NetworkImage(node.url),
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

  static InlineSpan _sourceTag(
    BuildContext context,
    String id,
    GptMarkdownConfig config,
  ) {
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child:
            config.sourceTagBuilder?.call(context, id, const TextStyle()) ??
            SizedBox(
              width: 20,
              height: 20,
              child: Material(
                color: Theme.of(context).colorScheme.onInverseSurface,
                shape: const OvalBorder(),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(id, textDirection: config.textDirection),
                ),
              ),
            ),
      ),
    );
  }

  static String _plainText(List<MdNode> nodes) {
    final out = StringBuffer();
    for (final n in nodes) {
      switch (n) {
        case MdText(:final text):
          out.write(text);
        case MdInlineCode(:final text):
          out.write(text);
        case MdInlineLatex(:final tex):
          out.write(tex);
        case MdSourceTag(:final id):
          out.write(id);
        case MdBold(:final children):
        case MdItalic(:final children):
        case MdStrike(:final children):
        case MdUnderline(:final children):
        case MdLink(:final children, url: _):
          out.write(_plainText(children));
        default:
          break;
      }
    }
    return out.toString();
  }
}
