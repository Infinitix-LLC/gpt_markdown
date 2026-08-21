import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

/// Renders [markdown] with [patterns] applied.
Future<void> pumpWithPatterns(
  WidgetTester tester,
  String markdown,
  List<InlinePattern> patterns,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: GptMarkdown(markdown, inlinePatterns: patterns),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// A pattern whose chip is trivially findable in the widget tree.
InlinePattern chipPattern(RegExp pattern, {Set<MarkdownScope>? scopes}) {
  return InlinePattern(
    pattern: pattern,
    scopes: scopes ?? MarkdownComponent.allScopesExceptLinkLabel,
    builder:
        (context, match, style) => WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: Text('CHIP:${match.group(0)}'),
        ),
  );
}

/// Concatenates the text of every [RichText] on screen.
String allRichText(WidgetTester tester) {
  final buffer = StringBuffer();
  for (final rt in tester.widgetList<RichText>(find.byType(RichText))) {
    buffer.write(rt.text.toPlainText(includePlaceholders: false));
  }
  return buffer.toString();
}

void main() {
  group('InlinePattern', () {
    testWidgets('renders in ordinary content', (tester) async {
      await pumpWithPatterns(tester, 'Go to #general now', [
        chipPattern(RegExp(r'#[a-z]+')),
      ]);
      expect(find.text('CHIP:#general'), findsOneWidget);
    });

    testWidgets('wins over the built-in components', (tester) async {
      // `**bold**` would normally be claimed by BoldMd.
      await pumpWithPatterns(tester, 'a **bold** b', [
        chipPattern(RegExp(r'\*\*bold\*\*')),
      ]);
      expect(find.text('CHIP:**bold**'), findsOneWidget);
    });

    testWidgets('does not render inside a link label by default', (
      tester,
    ) async {
      await pumpWithPatterns(tester, 'See [#2959](https://x.com/i/2959).', [
        chipPattern(RegExp(r'#[0-9a-z]+')),
      ]);
      expect(find.text('CHIP:#2959'), findsNothing);
      expect(allRichText(tester), contains('#2959'));
    });

    testWidgets('renders inside a link label when opted in', (tester) async {
      await pumpWithPatterns(tester, 'See [#2959](https://x.com/i/2959).', [
        chipPattern(RegExp(r'#[0-9a-z]+'), scopes: MarkdownComponent.allScopes),
      ]);
      expect(find.text('CHIP:#2959'), findsOneWidget);
    });

    testWidgets('renders inside a heading', (tester) async {
      await pumpWithPatterns(tester, '# Welcome to #general', [
        chipPattern(RegExp(r'#general')),
      ]);
      expect(find.text('CHIP:#general'), findsOneWidget);
    });

    testWidgets('renders inside a table cell', (tester) async {
      await pumpWithPatterns(
        tester,
        '| Channel | Note |\n|---|---|\n| #general | main |',
        [chipPattern(RegExp(r'#general'))],
      );
      expect(find.text('CHIP:#general'), findsOneWidget);
    });

    testWidgets('a TextSpan builder stays inside the paragraph', (
      tester,
    ) async {
      await pumpWithPatterns(tester, 'ping @ada please', [
        InlinePattern(
          pattern: RegExp(r'@[a-z]+'),
          builder:
              (context, match, style) => TextSpan(
                text: match.group(0),
                style: style.copyWith(fontWeight: FontWeight.bold),
              ),
        ),
      ]);
      // One paragraph, no placeholder — text and mention in the same RichText.
      final rt = tester.widget<RichText>(find.byType(RichText).first);
      expect(rt.text.toPlainText(), 'ping @ada please');
    });
  });

  group('InlinePattern.prefixed', () {
    testWidgets('matches known names', (tester) async {
      await pumpWithPatterns(tester, 'see #general', [
        InlinePattern.prefixed(
          prefix: '#',
          knownNames: const ['general', 'random'],
          builder:
              (context, match, style) =>
                  WidgetSpan(child: Text('CHIP:${match.group(0)}')),
        ),
      ]);
      expect(find.text('CHIP:#general'), findsOneWidget);
    });

    testWidgets('matches known names case-insensitively', (tester) async {
      await pumpWithPatterns(tester, 'see #General', [
        InlinePattern.prefixed(
          prefix: '#',
          knownNames: const ['general'],
          builder:
              (context, match, style) =>
                  WidgetSpan(child: Text('CHIP:${match.group(0)}')),
        ),
      ]);
      expect(find.text('CHIP:#General'), findsOneWidget);
    });

    testWidgets('leaves unknown tokens alone without a generic fallback', (
      tester,
    ) async {
      await pumpWithPatterns(tester, 'fixes #2959 today', [
        InlinePattern.prefixed(
          prefix: '#',
          knownNames: const ['general'],
          builder:
              (context, match, style) =>
                  WidgetSpan(child: Text('CHIP:${match.group(0)}')),
        ),
      ]);
      expect(find.text('CHIP:#2959'), findsNothing);
      expect(allRichText(tester), contains('#2959'));
    });

    testWidgets('claims unknown tokens when a generic fallback is given', (
      tester,
    ) async {
      await pumpWithPatterns(tester, 'fixes #2959 today', [
        InlinePattern.prefixed(
          prefix: '#',
          knownNames: const ['general'],
          genericTokenPattern: r'[A-Za-z0-9_][A-Za-z0-9_-]*',
          builder:
              (context, match, style) =>
                  WidgetSpan(child: Text('CHIP:${match.group(0)}')),
        ),
      ]);
      expect(find.text('CHIP:#2959'), findsOneWidget);
    });

    testWidgets('does not claim an @ inside an email address', (tester) async {
      await pumpWithPatterns(tester, 'mail ada@example.com now', [
        InlinePattern.prefixed(
          prefix: '@',
          genericTokenPattern: r'[A-Za-z0-9_]+',
          builder:
              (context, match, style) =>
                  WidgetSpan(child: Text('CHIP:${match.group(0)}')),
        ),
      ]);
      expect(find.textContaining('CHIP:'), findsNothing);
    });

    testWidgets('prefers the longest known name', (tester) async {
      await pumpWithPatterns(tester, 'see #design-review here', [
        InlinePattern.prefixed(
          prefix: '#',
          knownNames: const ['design', 'design-review'],
          builder:
              (context, match, style) =>
                  WidgetSpan(child: Text('CHIP:${match.group(0)}')),
        ),
      ]);
      expect(find.text('CHIP:#design-review'), findsOneWidget);
    });

    testWidgets('never matches when there is nothing to match', (tester) async {
      await pumpWithPatterns(tester, 'plain #text stays plain', [
        InlinePattern.prefixed(
          prefix: '#',
          builder:
              (context, match, style) =>
                  WidgetSpan(child: Text('CHIP:${match.group(0)}')),
        ),
      ]);
      expect(find.textContaining('CHIP:'), findsNothing);
      expect(allRichText(tester), contains('#text'));
    });
  });
}
