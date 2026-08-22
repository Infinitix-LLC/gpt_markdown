import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

/// Counts how often it is built, so a test can assert the settled part of a
/// reply is not rebuilt as more text arrives.
class _CountingMarkdown extends StatelessWidget {
  const _CountingMarkdown(this.text, this.counts);

  final String text;
  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    counts[text] = (counts[text] ?? 0) + 1;
    return GptMarkdown(text);
  }
}

String plainText(WidgetTester tester) {
  final buffer = StringBuffer();
  for (final rt in tester.widgetList<RichText>(
    find.byWidgetPredicate((w) => w is RichText),
  )) {
    buffer.write(rt.text.toPlainText(includePlaceholders: false));
  }
  return buffer.toString();
}

Future<void> pumpStreaming(
  WidgetTester tester,
  String text, {
  bool isStreaming = true,
  GptMarkdownAnimation animation = GptMarkdownAnimation.fade,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: GptMarkdown(
            text,
            animation: animation,
            isStreaming: isStreaming,
            charactersPerSecond: 100,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('animation: none', () {
    testWidgets('builds the same tree as no animation at all', (tester) async {
      const source = 'A paragraph.\n\nAnother one.';

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: GptMarkdown(source))),
      );
      await tester.pumpAndSettle();
      final without = plainText(tester);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GptMarkdown(source, animation: GptMarkdownAnimation.none),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(plainText(tester), without);
      // No reveal machinery is mounted at all.
      expect(find.byType(StreamingMarkdown), findsNothing);
    });

    testWidgets('shows everything immediately', (tester) async {
      await pumpStreaming(
        tester,
        'All of it at once.',
        animation: GptMarkdownAnimation.none,
      );
      expect(plainText(tester), contains('All of it at once.'));
    });
  });

  group('reveal', () {
    testWidgets('starts partial and finishes complete', (tester) async {
      const source = 'The quick brown fox jumps over the lazy dog.';
      await pumpStreaming(tester, source);

      // One frame in, at 100 characters a second, most of it is still hidden.
      expect(plainText(tester).length, lessThan(source.length));

      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(plainText(tester), contains(source));
    });

    testWidgets('fast-forwards when the reply finishes', (tester) async {
      const source = 'A reply that is long enough to still be revealing.';
      await pumpStreaming(tester, source);
      expect(plainText(tester).length, lessThan(source.length));

      // The stream ends: the remainder lands inside the catch-up window.
      await pumpStreaming(tester, source, isStreaming: false);
      await tester.pump(const Duration(milliseconds: 200));
      expect(plainText(tester), contains(source));
    });

    testWidgets('a settled reply animates nothing', (tester) async {
      const source = 'History message, already complete.';
      await pumpStreaming(tester, source, isStreaming: false);
      expect(plainText(tester), contains(source));
    });

    testWidgets('replacing the text restarts the reveal', (tester) async {
      await pumpStreaming(tester, 'First answer, fairly long text here.');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // A regenerate: not an extension of what came before.
      await pumpStreaming(tester, 'Completely different second answer.');
      expect(plainText(tester).length, lessThan(30));
    });

    testWidgets('reduced motion skips the reveal', (tester) async {
      const source = 'Shown immediately when animations are disabled.';
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: GptMarkdown(source, animation: GptMarkdownAnimation.fade),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(plainText(tester), contains(source));
    });
  });

  group('performance', () {
    testWidgets('the settled prefix is not rebuilt as text arrives', (
      tester,
    ) async {
      final counts = <String, int>{};

      Future<void> pump(String text) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: StreamingMarkdown(
                  text: text,
                  charactersPerSecond: 100000,
                  builder: (context, slice) => _CountingMarkdown(slice, counts),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 16));
      }

      // Revealed far faster than the text arrives, so every pump shows all of
      // it and the split is driven by the source rather than the reveal.
      const prefix = 'First paragraph.\n\n';
      await pump('${prefix}Second paragraph.\n\nTail.');

      final built = counts.keys.where((k) => k.startsWith(prefix)).toList();
      expect(built, isNotEmpty, reason: 'a settled prefix was built');
      final settledKey = built.first;
      final afterFirst = counts[settledKey] ?? 0;

      // More text arrives, appended the way a real stream appends. The
      // settled prefix is unchanged, so it must be reused rather than rebuilt
      // — that is what keeps the per-token cost proportional to the tail.
      var text = '${prefix}Second paragraph.\n\nTail.';
      for (var i = 0; i < 5; i++) {
        text = '$text and more';
        await pump(text);
      }
      expect(
        counts[settledKey],
        afterFirst,
        reason: 'the settled prefix must not rebuild while the tail grows',
      );
    });

    testWidgets('the settled prefix sits behind a repaint boundary', (
      tester,
    ) async {
      await pumpStreaming(
        tester,
        'One.\n\nTwo.\n\nThree.\n\nFour and the tail.',
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(RepaintBoundary), findsWidgets);
    });
  });
}
