part of 'gpt_markdown.dart';

/// It creates a markdown widget closed to each other.
class MdWidget extends StatefulWidget {
  const MdWidget(
    this.context,
    this.exp,
    this.includeGlobalComponents, {
    super.key,
    required this.config,
    this.isRoot = false,
  });

  /// isRoot
  final bool isRoot;

  /// The expression to be displayed.
  final String exp;
  final BuildContext context;

  /// Whether to include global components.
  final bool includeGlobalComponents;

  /// The configuration of the markdown widget.
  final GptMarkdownConfig config;

  @override
  State<MdWidget> createState() => _MdWidgetState();
}

class _MdWidgetState extends State<MdWidget> {
  List<InlineSpan> list = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Colours are resolved while the spans are built, not while they are
    // painted: link colours come from `GptMarkdownTheme`, inline code and
    // headings from the ambient `ColorScheme`. So an inherited change — a
    // light/dark switch, a new `GptMarkdownTheme`, a text-direction change —
    // has to regenerate them. Without this the widget rebuilds happily and
    // keeps painting the previous theme's colours.
    //
    // This also covers the first build: `didChangeDependencies` runs after
    // `initState` and before `build`.
    _generate();
  }

  @override
  void didUpdateWidget(covariant MdWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exp != widget.exp ||
        !oldWidget.config.isSame(widget.config)) {
      _generate();
    }
  }

  /// Regenerates the spans.
  ///
  /// Uses this element's own `context`, not [MdWidget.context]. Components
  /// resolve their colours through the context handed to them, and an
  /// inherited lookup registers the dependency on *that* element — so passing
  /// an ancestor's context would mean this widget is never notified when the
  /// theme changes.
  void _generate() {
    list = MarkdownComponent.generate(
      context,
      widget.exp,
      widget.config,
      widget.includeGlobalComponents,
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.config.getRich(
      TextSpan(children: list, style: widget.config.style?.copyWith()),
      isRoot: widget.isRoot,
    );
  }
}

/// A custom table column width.
class CustomTableColumnWidth extends TableColumnWidth {
  @override
  double maxIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) {
    double width = 50;
    for (var each in cells) {
      each.layout(const BoxConstraints(), parentUsesSize: true);
      width = max(width, each.size.width);
    }
    return min(containerWidth, width);
  }

  @override
  double minIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) {
    return 50;
  }
}
