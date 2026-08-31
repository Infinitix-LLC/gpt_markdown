part of '../gpt_markdown.dart';

/// The vertical space between two top-level blocks.
///
/// Approximates the "\n\n" paragraph break of the single-text pipeline: one
/// empty line of the default 1.15 line height. Scaled like the text it
/// separates, so the gap does not shrink relative to the type when a reader
/// raises their font size.
///
/// Shared, not duplicated: [_IncrementalMdView] puts it between its own
/// segments, and [GptMarkdown] hands the same value to [StreamingMarkdown] for
/// the seam between the settled prefix and the live tail. Those two have to
/// agree, or content moves when the seam does.
double blockGap(BuildContext context, GptMarkdownConfig config) {
  final scaler = config.textScaler ?? MediaQuery.textScalerOf(context);
  return scaler.scale((config.style?.fontSize ?? 14) * 1.15);
}

/// Incremental (segment-cached) Markdown view for streaming content.
///
/// The document is split into top-level segments ([splitStreamSegments]) and
/// each segment renders as its own `Text.rich` in a column, cached by its
/// source text. When streamed text is appended, only the tail segment's
/// widget is rebuilt — earlier segments keep their exact widget instances, so
/// Flutter skips rebuilding and re-laying-out everything above the tail
/// (LaTeX, tables, lists…). That keeps per-chunk cost constant instead of
/// growing with answer length.
class _IncrementalMdView extends StatefulWidget {
  const _IncrementalMdView({required this.text, required this.config});

  final String text;
  final GptMarkdownConfig config;

  @override
  State<_IncrementalMdView> createState() => _IncrementalMdViewState();
}

class _IncrementalMdViewState extends State<_IncrementalMdView> {
  final Map<String, Widget> _cache = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Theme or other inherited data changed: cached widgets baked in the old
    // values, so drop them.
    _cache.clear();
  }

  @override
  void didUpdateWidget(covariant _IncrementalMdView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.config.isSame(widget.config)) {
      _cache.clear();
    }
  }

  Widget _renderSegment(BuildContext context, String segment) {
    final spans = PlusparseRenderer.render(context, segment, widget.config);
    // Each segment is a root paragraph, not nested content. Without this the
    // text renders at `TextScaler.noScaling` and a raised system font size has
    // no effect at all.
    return widget.config.getRich(
      TextSpan(children: spans, style: widget.config.style?.copyWith()),
      isRoot: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final segments = splitStreamSegments(widget.text);
    final next = <String, Widget>{};
    final children = <Widget>[];
    final gap = blockGap(context, widget.config);
    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final child =
          next[segment] ?? _cache[segment] ?? _renderSegment(context, segment);
      next[segment] = child;
      if (i > 0) {
        children.add(SizedBox(height: gap));
      }
      children.add(child);
    }
    _cache
      ..clear()
      ..addAll(next);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}
