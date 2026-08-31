/// Splits Markdown source into independently-parsable top-level segments,
/// used by gpt_markdown's incremental rendering mode.
///
/// Segments are separated by blank lines, except inside fenced code blocks
/// (```) and block LaTeX (`\[ ... \]`), which stay whole. Each segment can be
/// parsed and rendered on its own; during streaming only the last segment's
/// text changes, so all earlier segments' widgets can be cached and reused —
/// that caps per-chunk rebuild/layout cost at the tail instead of the whole
/// message.
///
/// Divergence from a full-document parse: a list whose items are separated by
/// blank lines becomes multiple adjacent list segments instead of one list.
/// Rendering is visually equivalent (every item is its own row widget either
/// way).
library;

List<String> splitStreamSegments(String src) {
  final normalized =
      src.contains('\r')
          ? src.replaceAll('\r\n', '\n').replaceAll('\r', '\n')
          : src;
  final lines = normalized.split('\n');
  final segments = <String>[];
  final current = <String>[];
  var inFence = false;
  var inLatex = false;

  void closeSegment() {
    if (current.isNotEmpty) {
      segments.add(current.join('\n'));
      current.clear();
    }
  }

  for (final line in lines) {
    final trimmed = line.trimLeft();

    if (inFence) {
      current.add(line);
      if (trimmed.startsWith('```')) {
        inFence = false;
      }
      continue;
    }
    if (inLatex) {
      current.add(line);
      if (line.contains('\\]')) {
        inLatex = false;
      }
      continue;
    }

    if (line.trim().isEmpty) {
      closeSegment();
      continue;
    }

    current.add(line);
    if (trimmed.startsWith('```')) {
      inFence = true;
      continue;
    }
    if (trimmed.startsWith('\\[')) {
      // Mirrors the block parser: strip leading `\[` markers, then the block
      // stays open unless the closer appears on the same line.
      var rest = trimmed;
      while (rest.startsWith('\\[')) {
        rest = rest.substring(2);
      }
      if (!rest.contains('\\]')) {
        inLatex = true;
      }
    }
  }
  closeSegment();
  return segments;
}
