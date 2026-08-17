import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

/// Regression tests for
/// https://github.com/Infinitix-LLC/gpt_markdown/issues/61.
///
/// Elements that are rendered as a [WidgetSpan] — every `BlockMd` (lists,
/// headings, ...) and links — used to apply the text scaler twice, so they grew
/// quadratically: visibly larger than the surrounding prose once the reader
/// raised the system font size, and smaller once they lowered it.
///
/// The double scaling is invisible at a scale of exactly 1.0, which is why
/// these tests assert across several scales.
void main() {
  /// The size the glyphs are actually painted at, for every run of text.
  ///
  /// This is the leaf span's font size scaled by the paragraph's own
  /// [TextScaler] *and* by the transform inherited from its ancestors. The
  /// second factor matters: Flutter magnifies a [WidgetSpan]'s child
  /// geometrically by the host paragraph's scale factor, so reading
  /// `textScaler` alone reports these elements as correct when they are
  /// visibly double-scaled.
  Map<String, double> paintedSizes(WidgetTester tester) {
    final sizes = <String, double>{};
    for (final paragraph in tester.renderObjectList<RenderParagraph>(
      find.byType(RichText),
    )) {
      final geometric = paragraph.getTransformTo(null).getMaxScaleOnAxis();
      paragraph.text.visitChildren((span) {
        final text = span is TextSpan ? span.text : null;
        if (text == null || text.trim().isEmpty) return true;
        final fontSize = span.style?.fontSize ?? paragraph.text.style?.fontSize;
        if (fontSize != null) {
          sizes[text] = paragraph.textScaler.scale(fontSize) * geometric;
        }
        return true;
      });
    }
    return sizes;
  }

  Future<Map<String, double>> pumpAtScale(
    WidgetTester tester,
    double scale,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GptMarkdown(
                'plainprose\n\n'
                '- bulletitem\n\n'
                '1. numbereditem\n\n'
                '# headingtext\n\n'
                'a [linktext](https://example.com) inline',
                style: TextStyle(fontSize: 17),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return paintedSizes(tester);
  }

  const scales = <double>[0.5, 1.0, 1.5, 2.0];

  /// Elements that must be painted at exactly the prose size.
  const sameAsProse = <String>['bulletitem', 'numbereditem', 'linktext'];

  for (final scale in scales) {
    testWidgets('issue #61: elements match prose at text scale $scale', (
      tester,
    ) async {
      final sizes = await pumpAtScale(tester, scale);

      final prose = sizes['plainprose'];
      expect(prose, isNotNull, reason: 'prose should render');
      for (final element in sameAsProse) {
        expect(
          sizes[element],
          closeTo(prose!, 0.01),
          reason: '"$element" should be painted at the same size as prose',
        );
      }
    });
  }

  testWidgets('issue #61: a heading keeps its ratio to prose across scales', (
    tester,
  ) async {
    // A heading is legitimately larger than prose, so the invariant is that the
    // ratio between them holds — the heading must not scale on top of the
    // scaling already applied to the paragraph.
    final baseline = await pumpAtScale(tester, 1);
    final baseRatio = baseline['headingtext']! / baseline['plainprose']!;
    expect(baseRatio, greaterThan(1), reason: 'a heading is larger than prose');

    for (final scale in scales) {
      final sizes = await pumpAtScale(tester, scale);
      final ratio = sizes['headingtext']! / sizes['plainprose']!;
      expect(
        ratio,
        closeTo(baseRatio, 0.01),
        reason: 'heading:prose ratio should stay $baseRatio at scale $scale',
      );
    }
  });

  testWidgets('issue #61: text still responds to the scaler', (tester) async {
    // Guards against "uniform" being achieved by pinning everything to a fixed
    // size, which would silently break accessibility instead.
    final small = await pumpAtScale(tester, 0.5);
    final large = await pumpAtScale(tester, 2);

    for (final key in ['plainprose', 'headingtext', ...sameAsProse]) {
      expect(
        large[key],
        greaterThan(small[key]!),
        reason: '"$key" should grow when the text scaler grows',
      );
    }
  });
}
