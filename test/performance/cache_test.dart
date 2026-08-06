import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

void main() {
  group('Markdown render caches', () {
    setUp(() {
      MdWidget.debugClearParseCache();
      MarkdownComponent.debugClearMatcherCache();
    });

    testWidgets(
      'reuses parsed spans and component regexes for identical input',
      (tester) async {
        await _pumpMarkdown(tester, const GptMarkdown('Hello **world**'));

        final parseCacheLength = MdWidget.debugParseCacheLength;
        final matcherCacheLength = MarkdownComponent.debugMatcherCacheLength;

        expect(parseCacheLength, greaterThan(0));
        expect(matcherCacheLength, greaterThan(0));

        await _pumpMarkdown(tester, const GptMarkdown('Hello **world**'));

        expect(MdWidget.debugParseCacheLength, parseCacheLength);
        expect(MarkdownComponent.debugMatcherCacheLength, matcherCacheLength);
      },
    );

    testWidgets('invalidates parsed span cache when render signature changes', (
      tester,
    ) async {
      await _pumpMarkdown(tester, const GptMarkdown('Hello **world**'));

      final parseCacheLength = MdWidget.debugParseCacheLength;

      await _pumpMarkdown(
        tester,
        const GptMarkdown(
          'Hello **world**',
          textDirection: TextDirection.rtl,
        ),
      );

      expect(MdWidget.debugParseCacheLength, greaterThan(parseCacheLength));
    });

    testWidgets('tracks local h1 rendering options in parse cache signature', (
      tester,
    ) async {
      await _pumpMarkdown(tester, const GptMarkdown('# Title'));

      final parseCacheLength = MdWidget.debugParseCacheLength;

      await _pumpMarkdown(
        tester,
        const GptMarkdown(
          '# Title',
          addNewLineAfterH1: false,
        ),
      );

      expect(MdWidget.debugParseCacheLength, greaterThan(parseCacheLength));
    });
  });
}

Future<void> _pumpMarkdown(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
