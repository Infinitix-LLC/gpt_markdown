/// Tests for the pure-Dart plusparse parser built into gpt_markdown.
///
/// Ports the full integration test suite of the original Rust plusparse
/// (`rust/tests/parser_tests.rs`) and adds extra edge cases for malformed and
/// partial (streaming) input. Pure Dart — no widget pumping needed.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_markdown/plusparse/plusparse.dart';

import 'sample_documents.dart';

MdDocument p(String s) => Plusparse.parse(s);

/// Flatten the visible text of a run of inline nodes (for assertions).
String inlineText(List<MdNode> nodes) {
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
        out.write(inlineText(children));
      default:
        break;
    }
  }
  return out.toString();
}

void main() {
  group('ported Rust parser tests', () {
    test('heading levels', () {
      final doc = p('# H1\n## H2\n###### H6\n####### not a heading');
      expect(doc.children[0], isA<MdHeading>().having((h) => h.level, 'level', 1));
      expect(doc.children[1], isA<MdHeading>().having((h) => h.level, 'level', 2));
      expect(doc.children[2], isA<MdHeading>().having((h) => h.level, 'level', 6));
      // 7 hashes is not a heading -> paragraph
      expect(doc.children[3], isA<MdParagraph>());
    });

    test('emphasis inline', () {
      final doc = p('**bold** *italic* ~~strike~~ `code` <u>under</u>');
      final para = doc.children[0] as MdParagraph;
      final kinds = para.children
          .map((n) => switch (n) {
                MdBold() => 'bold',
                MdItalic() => 'italic',
                MdStrike() => 'strike',
                MdInlineCode() => 'code',
                MdUnderline() => 'under',
                _ => null,
              })
          .nonNulls
          .toList();
      expect(kinds, ['bold', 'italic', 'strike', 'code', 'under']);
    });

    test('links, images and source tags', () {
      final doc = p('See [docs](https://x.com) and ![100x200](img.png) and [1]');
      final para = doc.children[0] as MdParagraph;

      final link = para.children.whereType<MdLink>().single;
      expect(link.url, 'https://x.com');
      expect(inlineText(link.children), 'docs');

      final img = para.children.whereType<MdImage>().single;
      expect(img.url, 'img.png');
      expect(img.width, 100.0);
      expect(img.height, 200.0);

      expect(para.children.whereType<MdSourceTag>().single.id, '1');
    });

    test('inline and block latex', () {
      final doc = p('Euler: \\( e^{i\\pi} \\)\n\n\\[\n\\int_0^1 x^2 dx\n\\]');
      final para = doc.children[0] as MdParagraph;
      expect(
        para.children.whereType<MdInlineLatex>().any(
              (n) => n.tex.contains('e^{i\\pi}'),
            ),
        isTrue,
      );
      expect(
        doc.children[1],
        isA<MdBlockLatex>().having(
          (n) => n.tex,
          'tex',
          contains('\\int_0^1'),
        ),
      );
    });

    test('code block with language', () {
      final doc = p('```rust\nfn main() {}\n```');
      final code = doc.children[0] as MdCodeBlock;
      expect(code.language, 'rust');
      expect(code.code, 'fn main() {}');
      expect(code.closed, isTrue);
    });

    test('unclosed code block is open (streaming)', () {
      final doc = p('```python\nprint(1)');
      final code = doc.children[0] as MdCodeBlock;
      expect(code.closed, isFalse);
      expect(code.language, 'python');
      expect(code.code, 'print(1)');
    });

    test('nested lists', () {
      final doc = p('- Lists:\n  1. Item 1\n  2. Item 2\n  3. Item 3');
      final list = doc.children[0] as MdUnorderedList;
      expect(list.items, hasLength(1));
      // item has inline text "Lists:" then a nested ordered list
      final nested =
          list.items[0].children.whereType<MdOrderedList>().single;
      expect(nested.start, 1);
      expect(nested.items, hasLength(3));
    });

    test('ordered list start number', () {
      final doc = p('3. three\n4. four');
      final list = doc.children[0] as MdOrderedList;
      expect(list.start, 3);
      expect(list.items, hasLength(2));
    });

    test('checkbox and radio', () {
      final doc = p('[x] done\n[ ] todo\n(x) on\n( ) off');
      expect(
        doc.children[0],
        isA<MdCheckbox>().having((n) => n.checked, 'checked', isTrue),
      );
      expect(
        doc.children[1],
        isA<MdCheckbox>().having((n) => n.checked, 'checked', isFalse),
      );
      expect(
        doc.children[2],
        isA<MdRadio>().having((n) => n.selected, 'selected', isTrue),
      );
      expect(
        doc.children[3],
        isA<MdRadio>().having((n) => n.selected, 'selected', isFalse),
      );
    });

    test('blockquote and horizontal rule', () {
      final doc = p('> quoted **text**\n\n---');
      final quote = doc.children[0] as MdBlockQuote;
      expect(quote.children[0], isA<MdParagraph>());
      expect(doc.children[1], isA<MdHorizontalRule>());
    });

    test('table with alignment', () {
      final doc = p('| Name | Age |\n|:---|---:|\n| Bob | 30 |\n| Al | 9 |');
      final table = doc.children[0] as MdTable;
      expect(table.aligns, [MdAlign.left, MdAlign.right]);
      expect(table.header.cells, hasLength(2));
      expect(table.rows, hasLength(2));
      expect(inlineText(table.header.cells[0].content), 'Name');
      expect(inlineText(table.rows[1].cells[1].content), '9');
    });

    test('dollar latex only when enabled', () {
      final off = Plusparse.parse(r'cost $5 and $7');
      final offPara = off.children[0] as MdParagraph;
      expect(offPara.children.whereType<MdInlineLatex>(), isEmpty);

      final on = Plusparse.parse(r'$x^2$', useDollarSignsForLatex: true);
      final onPara = on.children[0] as MdParagraph;
      expect(
        onPara.children.whereType<MdInlineLatex>().any((n) => n.tex == 'x^2'),
        isTrue,
      );
    });

    test('empty and whitespace input', () {
      expect(p('').children, isEmpty);
      expect(p('   \n\n  \n').children, isEmpty);
    });

    test('full ChatGPT sample parses correctly', () {
      final doc = p(sampleChatGpt);
      // Sanity: should produce a reasonable number of top-level blocks incl
      // headings.
      expect(doc.children.length, greaterThan(5));
      final headingCount = doc.children.whereType<MdHeading>().length;
      expect(headingCount, greaterThanOrEqualTo(4));
      // contains the block-latex matrix
      expect(
        doc.children.whereType<MdBlockLatex>().any(
              (n) => n.tex.contains('bmatrix'),
            ),
        isTrue,
      );
    });
  });

  group('additional edge cases', () {
    test('CRLF and CR line endings are normalized', () {
      final doc = p('# Title\r\n\r\nHello\rWorld');
      expect(doc.children[0], isA<MdHeading>());
      final para = doc.children[1] as MdParagraph;
      // CR-split lines join into one paragraph separated by a space.
      expect(inlineText(para.children), 'Hello World');
    });

    test('dollar-dollar block form', () {
      final doc = Plusparse.parse(r'$$\frac{a}{b}$$', useDollarSignsForLatex: true);
      final para = doc.children[0] as MdParagraph;
      expect(
        para.children.whereType<MdInlineLatex>().single.tex,
        r'\frac{a}{b}',
      );
    });

    test('unterminated emphasis stays literal text', () {
      for (final input in ['a *b unclosed', 'trailing stray **']) {
        final doc = p(input);
        final para = doc.children[0] as MdParagraph;
        expect(inlineText(para.children), input);
        expect(para.children.whereType<MdBold>(), isEmpty);
        expect(para.children.whereType<MdItalic>(), isEmpty);
      }
    });

    test('unclosed ** falls back to italic when a later * exists', () {
      // Mirrors the Rust parser: `**b and *c` has no closing `**`, so the
      // first `*` stays literal and `*b and *` matches as italic.
      final doc = p('a **b and *c');
      final para = doc.children[0] as MdParagraph;
      final italic = para.children.whereType<MdItalic>().single;
      expect(inlineText(italic.children), 'b and ');
      expect(inlineText(para.children), 'a *b and c');
    });

    test('unterminated link stays literal text', () {
      final doc = p('go to [broken](http://x');
      final para = doc.children[0] as MdParagraph;
      expect(para.children.whereType<MdLink>(), isEmpty);
      expect(inlineText(para.children), contains('[broken]'));
    });

    test('image size variants', () {
      double? w(String md) =>
          ((p(md).children[0] as MdParagraph).children.whereType<MdImage>().single)
              .width;
      double? h(String md) =>
          ((p(md).children[0] as MdParagraph).children.whereType<MdImage>().single)
              .height;
      expect(w('![100x](u)'), 100.0);
      expect(h('![100x](u)'), isNull);
      expect(w('![x200](u)'), isNull);
      expect(h('![x200](u)'), 200.0);
      expect(w('![logo](u)'), isNull);
      expect(h('![logo](u)'), isNull);
    });

    test('nested emphasis inside bold', () {
      final doc = p('**bold with `code` inside**');
      final para = doc.children[0] as MdParagraph;
      final bold = para.children.whereType<MdBold>().single;
      expect(bold.children.whereType<MdInlineCode>().single.text, 'code');
    });

    test('blockquote with nested list', () {
      final doc = p('> - one\n> - two');
      final quote = doc.children[0] as MdBlockQuote;
      final list = quote.children.whereType<MdUnorderedList>().single;
      expect(list.items, hasLength(2));
    });

    test('multiline block latex accumulates until closer', () {
      final doc = p('\\[\na + b\n= c\n\\]');
      final latex = doc.children[0] as MdBlockLatex;
      expect(latex.tex, 'a + b\n= c');
    });

    test('unclosed block latex consumes the rest (streaming)', () {
      final doc = p('\\[\na + b');
      final latex = doc.children[0] as MdBlockLatex;
      expect(latex.tex, 'a + b');
    });

    test('hr variants', () {
      expect(p('---').children[0], isA<MdHorizontalRule>());
      expect(p('***').children[0], isA<MdHorizontalRule>());
      expect(p('___').children[0], isA<MdHorizontalRule>());
      expect(p('- - -').children[0], isA<MdHorizontalRule>());
      expect(p('⸻').children[0], isA<MdHorizontalRule>());
      expect(p('--').children[0], isNot(isA<MdHorizontalRule>()));
    });

    test('list interrupted by different indentation ends the list', () {
      final doc = p('- a\n- b\nplain text');
      final list = doc.children[0] as MdUnorderedList;
      expect(list.items, hasLength(2));
      expect(doc.children[1], isA<MdParagraph>());
    });

    test('ordered marker with parenthesis', () {
      final doc = p('1) one\n2) two');
      final list = doc.children[0] as MdOrderedList;
      expect(list.start, 1);
      expect(list.items, hasLength(2));
    });

    test('table without body rows', () {
      final doc = p('| A | B |\n|---|---|');
      final table = doc.children[0] as MdTable;
      expect(table.header.cells, hasLength(2));
      expect(table.rows, isEmpty);
    });

    test('pipe line without separator is not a table', () {
      final doc = p('a | b\nplain');
      expect(doc.children.whereType<MdTable>(), isEmpty);
    });

    test('every streaming prefix of the ChatGPT sample parses', () {
      // Simulates token-by-token streaming: no prefix may throw.
      for (var end = 0; end <= sampleChatGpt.length; end += 7) {
        expect(
          () => p(sampleChatGpt.substring(0, end)),
          returnsNormally,
          reason: 'prefix of length $end should parse without throwing',
        );
      }
    });

    test('large document parses with expected structure', () {
      final doc = p(buildLargeDocument(repeat: 5));
      expect(doc.children.whereType<MdTable>().length, 5);
      expect(
        doc.children.whereType<MdCodeBlock>().length,
        5,
      );
      expect(doc.children.whereType<MdHorizontalRule>().length, 5);
      expect(doc.children.whereType<MdHeading>().length, greaterThan(20));
    });

    test('genui directive captures balanced JSON payload', () {
      final doc = p('Before genui{"type":"button","label":"Tap"} after');
      final para = doc.children[0] as MdParagraph;
      final genUi = para.children.whereType<MdGenUi>().single;
      expect(genUi.payload, '{"type":"button","label":"Tap"}');
      expect((para.children.first as MdText).text, 'Before ');
      expect((para.children.last as MdText).text, ' after');
    });

    test('genui payload with nested braces and braces inside strings', () {
      final doc = p(
        r'genui{"val_scene": {"id": "a}b", "frame": "wide{x}"}} tail',
      );
      final para = doc.children[0] as MdParagraph;
      final genUi = para.children.whereType<MdGenUi>().single;
      expect(genUi.payload, r'{"val_scene": {"id": "a}b", "frame": "wide{x}"}}');
    });

    test('unterminated genui stays literal text (streaming)', () {
      final doc = p('genui{"val_scene": {"id": "x"');
      final para = doc.children[0] as MdParagraph;
      expect(para.children.whereType<MdGenUi>(), isEmpty);
      expect(inlineText(para.children), 'genui{"val_scene": {"id": "x"');
    });

    test('unicode text passes through untouched', () {
      final doc = p('emoji 🎉 and **möre ünïcode** ⸺ done');
      final para = doc.children[0] as MdParagraph;
      expect(inlineText(para.children), 'emoji 🎉 and möre ünïcode ⸺ done');
      expect(inlineText(para.children.whereType<MdBold>().single.children),
          'möre ünïcode');
    });
  });
}
