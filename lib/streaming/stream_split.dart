/// Finding a safe place to cut streaming Markdown in two.
library;

/// The offset of the last blank line that is safe to split at, or 0 when the
/// whole document has to stay together.
///
/// Everything before the split is settled: it can be rendered once and cached,
/// because appending to the end of a document cannot change it. Everything
/// after is the live tail, and is the only part re-rendered as text arrives.
/// That is what keeps the per-token cost proportional to the tail rather than
/// to the whole reply.
///
/// A blank line inside a fenced code block or block LaTeX is **not** a safe
/// split: cutting there would leave the prefix holding an unterminated
/// ``` fence, which renders as literal text until the closing fence arrives —
/// a visible flicker mid-stream. Those regions are skipped.
///
/// The last construct is never settled either, even when it is followed by a
/// blank line, because the next token may still extend it — a list gaining
/// another item, a paragraph another sentence.
int settledSplitOffset(String source) {
  var inFence = false;
  var inLatex = false;

  // Offsets of blank lines outside fences and block maths.
  final candidates = <int>[];

  var lineStart = 0;
  var index = 0;
  while (index <= source.length) {
    final atEnd = index == source.length;
    if (!atEnd && source.codeUnitAt(index) != 0x0A) {
      index++;
      continue;
    }

    final line = source.substring(lineStart, index);
    final trimmed = line.trimLeft();

    if (inFence) {
      if (trimmed.startsWith('```') || trimmed.startsWith('~~~')) {
        inFence = false;
      }
    } else if (inLatex) {
      if (trimmed.contains(r'\]')) {
        inLatex = false;
      }
    } else if (trimmed.startsWith('```') || trimmed.startsWith('~~~')) {
      inFence = true;
    } else if (trimmed.startsWith(r'\[') && !trimmed.contains(r'\]')) {
      inLatex = true;
    } else if (trimmed.isEmpty && lineStart > 0) {
      // The split goes after the blank line, so the tail starts on real
      // content rather than with leading whitespace.
      candidates.add(index + 1);
    }

    if (atEnd) {
      break;
    }
    index++;
    lineStart = index;
  }

  // Never settle the final construct: the next token may extend it.
  if (candidates.length < 2) {
    return 0;
  }
  return candidates[candidates.length - 2];
}
