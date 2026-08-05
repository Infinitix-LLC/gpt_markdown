part of '../gpt_markdown.dart';

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
    return widget.config.getRich(
      TextSpan(children: spans, style: widget.config.style?.copyWith()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final segments = splitStreamSegments(widget.text);
    final next = <String, Widget>{};
    final children = <Widget>[];
    // Approximates the "\n\n" paragraph break of the single-text pipeline:
    // one empty line of the default 1.15 line height.
    final gap = (widget.config.style?.fontSize ?? 14) * 1.15;
    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final child =
          next[segment] ??
          _cache[segment] ??
          _renderSegment(context, segment);
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
