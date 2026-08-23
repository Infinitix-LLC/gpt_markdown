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
      case MdHeading(:final level, :final children):
        return [
          _blockSpan(
            headingWidget(
              context,
              config,
              level: level,
              buildChildren: (conf) => _inlineSpans(context, children, conf),
            ),
          ),
        ];
      case MdHorizontalRule():
        return [_blockSpan(hrWidget(context, config))];
      case MdCodeBlock(:final language, :final code, :final closed):
        return [
          _blockSpan(
            codeBlockWidget(
              context,
              config,
              name: language,
              code: code,
              closed: closed,
            ),
          ),
        ];
      case MdBlockLatex(:final tex):
        return [
          _blockSpan(latexWidget(context, config, tex: tex, inline: false)),
        ];
      case MdBlockQuote(:final children):
        return [
          blockQuoteSpan(
            context,
            config,
            buildContent:
                (conf) => conf.getRich(
                  TextSpan(children: _blockSpans(context, children, conf)),
                ),
          ),
        ];
      case MdCheckbox(:final checked, :final children):
        return [
          _blockSpan(
            checkboxWidget(
              context,
              config,
              checked: checked,
              label: config.getRich(
                TextSpan(children: _inlineSpans(context, children, config)),
              ),
            ),
          ),
        ];
      case MdRadio(:final selected, :final children):
        return [
          _blockSpan(
            radioWidget(
              context,
              config,
              selected: selected,
              label: config.getRich(
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
        spans.add(_blockSpan(orderedListItem(context, config, no, itemChild)));
      } else {
        spans.add(_blockSpan(unorderedListItem(context, config, itemChild)));
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
            data:
                col < row.cells.length
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

    final tableStyle = (resolvedStyleSheet(context, config).table ??
            const TableStyle())
        .resolve(Theme.of(context).colorScheme);
    final tableRadius = tableStyle.borderRadius;
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
              width: tableStyle.borderWidth ?? 1,
              color:
                  tableStyle.borderColor ??
                  Theme.of(context).colorScheme.onSurface,
              borderRadius:
                  tableRadius == null
                      ? BorderRadius.zero
                      : BorderRadius.all(tableRadius),
            ),
            children: List<TableRow>.generate(rows.length, (index) {
              final row = rows[index];
              return TableRow(
                decoration:
                    index == 0
                        ? BoxDecoration(
                          color:
                              tableStyle.headerBackground ??
                              Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                        )
                        : null,
                children: List<Widget>.generate(maxCol, (col) {
                  final cell = col < row.cells.length ? row.cells[col] : null;
                  if (cell == null || cell.content.isEmpty) {
                    return const SizedBox();
                  }
                  Widget content = Padding(
                    padding:
                        tableStyle.cellPadding ??
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

  /// Runs a run of plain text through the consumer-facing inline syntaxes:
  /// [GptMarkdownConfig.inlinePatterns] first, then autolinking.
  ///
  /// Both are regex components, so they are dispatched by
  /// [MarkdownComponent.generate] with a component list holding nothing else —
  /// which is what keeps their scope filtering, boundary rules and precedence
  /// identical to the regex pipeline instead of reimplemented here.
  static List<InlineSpan> _textSpans(
    BuildContext context,
    String text,
    GptMarkdownConfig config,
  ) {
    final patterns = config.inlinePatterns;
    final hasPatterns = patterns != null && patterns.isNotEmpty;
    if (!hasPatterns && !config.autolink) {
      return [TextSpan(text: text, style: config.style)];
    }
    return MarkdownComponent.generate(
      context,
      text,
      config.copyWith(inlineComponents: [if (config.autolink) AutolinkMd()]),
      false,
    );
  }

  static InlineSpan _inline(
    BuildContext context,
    MdNode node,
    GptMarkdownConfig config,
  ) {
    // Contexts a placeholder must not appear in. A link label is already
    // rendered inside the link's own `WidgetSpan`, and a second one nested in
    // it does not paint on iOS.
    if (config.scope == MarkdownScope.linkLabel) {
      switch (node) {
        case MdImage(:final alt, :final url):
          return TextSpan(text: '![$alt]($url)', style: config.style);
        case MdLink(:final children):
          // CommonMark forbids a link inside a link label; render the label's
          // own content and drop the nested link.
          return TextSpan(
            children: _inlineSpans(context, children, config),
            style: config.style,
          );
        default:
          break;
      }
    }

    switch (node) {
      case MdText(:final text):
        return TextSpan(
          children: _textSpans(context, text, config),
          style: config.style,
        );
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
        return inlineCodeSpan(context, text, config);
      case MdInlineLatex(:final tex):
        return WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: latexWidget(context, config, tex: tex, inline: true),
        );
      case MdLink(:final children, :final url):
        return _link(context, children, url, config);
      case MdImage(:final url, :final width, :final height):
        return imageSpan(
          context,
          config,
          url: url,
          width: width,
          height: height,
        );
      case MdSourceTag(:final id):
        return sourceTagSpan(context, id, config);
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
        return blocks.length == 1 ? blocks.first : TextSpan(children: blocks);
    }
  }

  static InlineSpan _link(
    BuildContext context,
    List<MdNode> children,
    String url,
    GptMarkdownConfig config,
  ) {
    return buildLinkSpan(
      context,
      config,
      url: url,
      label: _plainText(children),
      buildLabelSpans: (conf) => _inlineSpans(context, children, conf),
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
