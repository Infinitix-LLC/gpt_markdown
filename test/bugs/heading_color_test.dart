// Bug test: Heading text colors should adapt to light/dark theme
//
// Issue: Headings (h1-h6) were rendering with incorrect colors that
// didn't adapt to the theme brightness, causing poor contrast
// (e.g., dark text on dark background in dark mode).
//
// Expected: Headings should use onSurface color from the theme
// (black in light mode, white in dark mode).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

void main() {
  group('Heading text colors with GptMarkdownThemeData', () {
    Future<Color?> getHeadingColor(
      WidgetTester tester,
      String markdown,
      Brightness brightness,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: brightness,
            colorScheme: brightness == Brightness.dark
                ? const ColorScheme.dark()
                : const ColorScheme.light(),
            extensions: [
              GptMarkdownThemeData(brightness: brightness),
            ],
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: GptMarkdown(markdown),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final richTextFinder = find.byType(RichText);
      expect(richTextFinder, findsWidgets);

      final richText = tester.widget<RichText>(richTextFinder.first);
      final textSpan = richText.text as TextSpan;

      Color? extractColor(InlineSpan span) {
        if (span is TextSpan) {
          if (span.style?.color != null) {
            return span.style!.color;
          }
          if (span.children != null) {
            for (final child in span.children!) {
              final color = extractColor(child);
              if (color != null) return color;
            }
          }
        }
        return null;
      }

      return extractColor(textSpan);
    }

    // Expected colors from ColorScheme.onSurface
    const expectedLightColor = Colors.black;
    const expectedDarkColor = Colors.white;

    testWidgets('h1 is black in light mode', (tester) async {
      final color = await getHeadingColor(tester, '# Heading 1', Brightness.light);
      expect(color, equals(expectedLightColor));
    });

    testWidgets('h1 is white in dark mode', (tester) async {
      final color = await getHeadingColor(tester, '# Heading 1', Brightness.dark);
      expect(color, equals(expectedDarkColor));
    });

    testWidgets('h2 is black in light mode', (tester) async {
      final color = await getHeadingColor(tester, '## Heading 2', Brightness.light);
      expect(color, equals(expectedLightColor));
    });

    testWidgets('h2 is white in dark mode', (tester) async {
      final color = await getHeadingColor(tester, '## Heading 2', Brightness.dark);
      expect(color, equals(expectedDarkColor));
    });

    testWidgets('h3 is black in light mode', (tester) async {
      final color = await getHeadingColor(tester, '### Heading 3', Brightness.light);
      expect(color, equals(expectedLightColor));
    });

    testWidgets('h3 is white in dark mode', (tester) async {
      final color = await getHeadingColor(tester, '### Heading 3', Brightness.dark);
      expect(color, equals(expectedDarkColor));
    });

    testWidgets('h4 is black in light mode', (tester) async {
      final color = await getHeadingColor(tester, '#### Heading 4', Brightness.light);
      expect(color, equals(expectedLightColor));
    });

    testWidgets('h4 is white in dark mode', (tester) async {
      final color = await getHeadingColor(tester, '#### Heading 4', Brightness.dark);
      expect(color, equals(expectedDarkColor));
    });

    testWidgets('h5 is black in light mode', (tester) async {
      final color = await getHeadingColor(tester, '##### Heading 5', Brightness.light);
      expect(color, equals(expectedLightColor));
    });

    testWidgets('h5 is white in dark mode', (tester) async {
      final color = await getHeadingColor(tester, '##### Heading 5', Brightness.dark);
      expect(color, equals(expectedDarkColor));
    });

    testWidgets('h6 is black in light mode', (tester) async {
      final color = await getHeadingColor(tester, '###### Heading 6', Brightness.light);
      expect(color, equals(expectedLightColor));
    });

    testWidgets('h6 is white in dark mode', (tester) async {
      final color = await getHeadingColor(tester, '###### Heading 6', Brightness.dark);
      expect(color, equals(expectedDarkColor));
    });
  });
}
