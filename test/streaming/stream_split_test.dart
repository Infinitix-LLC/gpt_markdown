import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

/// The split decides what is cached and what is rebuilt per frame. Splitting
/// in the wrong place either costs performance (too little settled) or renders
/// broken Markdown (a fence cut in half).
void main() {
  test('a short document has nothing settled yet', () {
    expect(settledSplitOffset('Just one paragraph.'), 0);
  });

  test('the last construct is never settled', () {
    // Two paragraphs: the second may still be extended by the next token, so
    // only the first can be cached — and with only one blank line there is no
    // earlier boundary to use.
    expect(settledSplitOffset('One.\n\nTwo.'), 0);
  });

  test('settles everything but the final construct', () {
    const source = 'One.\n\nTwo.\n\nThree.';
    final offset = settledSplitOffset(source);
    expect(source.substring(0, offset), 'One.\n\n');
    expect(source.substring(offset), 'Two.\n\nThree.');
  });

  test('never splits inside a fenced code block', () {
    const source = 'Intro.\n\n```dart\nvar a = 1;\n\nvar b = 2;\n```\n\nAfter.';
    final offset = settledSplitOffset(source);
    // The blank line inside the fence must not be chosen: the prefix would
    // hold an unterminated fence and render as literal text.
    expect(source.substring(0, offset), isNot(contains('```dart')));
    expect(offset, lessThanOrEqualTo(source.indexOf('```dart')));
  });

  test('never splits inside block maths', () {
    const source = 'Intro.\n\n\\[\na^2\n\n b^2\n\\]\n\nAfter.';
    final offset = settledSplitOffset(source);
    expect(source.substring(0, offset), isNot(contains(r'\[')));
  });

  test('the two halves always rejoin to the original', () {
    const sources = [
      'One.\n\nTwo.\n\nThree.\n\nFour.',
      '# Title\n\nBody.\n\n- a\n- b\n\nEnd.',
      '```\ncode\n```\n\nAfter.\n\nMore.',
    ];
    for (final source in sources) {
      final offset = settledSplitOffset(source);
      expect(
        source.substring(0, offset) + source.substring(offset),
        source,
        reason: source,
      );
    }
  });

  test('grows as the document grows, so the tail stays small', () {
    final buffer = StringBuffer();
    var previous = 0;
    for (var i = 0; i < 20; i++) {
      buffer.write('Paragraph $i.\n\n');
      final offset = settledSplitOffset(buffer.toString());
      expect(offset, greaterThanOrEqualTo(previous));
      previous = offset;
    }
    // Most of a long document ends up settled.
    expect(previous, greaterThan(buffer.length ~/ 2));
  });

  // The test above only samples whole-paragraph boundaries, which is exactly
  // where the offset used to look well behaved. Streaming arrives a character
  // at a time, and a source ending in a newline used to count its empty last
  // line as a blank line — one candidate too many, so the split ran a
  // construct ahead and fell back the moment the next character landed.
  // Settled content unsettling is visible as a jump.
  test('never moves backward, character by character', () {
    const source = '# Title\n\nFirst paragraph.\n\nSecond paragraph.\n';
    var previous = 0;
    for (var n = 1; n <= source.length; n++) {
      final offset = settledSplitOffset(source.substring(0, n));
      expect(
        offset,
        greaterThanOrEqualTo(previous),
        reason: 'went backward at n=$n: "${source.substring(0, n)}"',
      );
      previous = offset;
    }
  });

  test('a trailing newline does not settle the final construct', () {
    const source = 'One.\n\nTwo.\n\nThree.\n\n';
    final offset = settledSplitOffset(source);
    // The tail must still hold the last construct: more may be coming.
    expect(source.substring(offset).trim(), 'Three.');
  });
}
