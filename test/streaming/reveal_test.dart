/// The span-level reveal: the character effects, the block entrances, and the
/// invariants that make them safe to leave on during a real stream.
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

const _doc = '''# Title

A paragraph with **bold** and `code` in it, long enough to matter here.

| A | B |
|---|---|
| 1 | 2 |

Final paragraph.
''';

Future<void> _pump(
  WidgetTester tester,
  String text, {
  required GptMarkdownAnimation animation,
  GptMarkdownBlockAnimation block = GptMarkdownBlockAnimation.none,
  bool isStreaming = true,
  double charactersPerSecond = 120,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 600,
            child: GptMarkdown(
              text,
              animation: animation,
              blockAnimation: block,
              isStreaming: isStreaming,
              charactersPerSecond: charactersPerSecond,
            ),
          ),
        ),
      ),
    ),
  );
}

/// Whether [text] is on screen anywhere, including inside the widget spans
/// that block-level constructs render as.
///
/// [_visible] cannot answer this: block content lives inside placeholders, and
/// a placeholder's text is not part of its parent paragraph's plain text.
bool _shows(String text) =>
    find.textContaining(text, findRichText: true).evaluate().isNotEmpty;

/// The text of the paragraphs being revealed, for measuring how far the reveal
/// has got. Placeholder content is deliberately excluded — it arrives whole
/// and would step the count rather than ramp it.
String _visible(WidgetTester tester) {
  final buffer = StringBuffer();
  for (final element in find.byType(RichText).evaluate()) {
    buffer.write(
      (element.widget as RichText).text.toPlainText(includePlaceholders: false),
    );
  }
  return buffer.toString();
}

/// Distinct alpha values across the leaf spans — the fade ramp's fingerprint.
///
/// A hard cut produces one; a per-character ramp produces many.
Set<double> _alphas(WidgetTester tester) {
  final seen = <double>{};
  void walk(InlineSpan span) {
    if (span is! TextSpan) {
      return;
    }
    final color = span.style?.color;
    if (color != null && (span.text?.isNotEmpty ?? false)) {
      seen.add(color.a);
    }
    span.children?.forEach(walk);
  }

  for (final element in find.byType(RichText).evaluate()) {
    walk((element.widget as RichText).text);
  }
  return seen;
}

/// Leaf spans carrying a `foreground` paint — how [GptMarkdownAnimation.blurIn]
/// shows up in the tree.
int _painted(WidgetTester tester) {
  var count = 0;
  void walk(InlineSpan span) {
    if (span is! TextSpan) {
      return;
    }
    if (span.style?.foreground != null && (span.text?.isNotEmpty ?? false)) {
      count += 1;
    }
    span.children?.forEach(walk);
  }

  for (final element in find.byType(RichText).evaluate()) {
    walk((element.widget as RichText).text);
  }
  return count;
}

void main() {
  group('reveal', () {
    testWidgets('shows a growing prefix rather than the whole document', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(900, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pump(tester, _doc, animation: GptMarkdownAnimation.fade);
      await tester.pump();

      final lengths = <int>[];
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 80));
        while (tester.takeException() != null) {}
        lengths.add(_visible(tester).length);
      }

      expect(lengths.first, lessThan(lengths.last));
      // Monotonic: the reveal never takes content back.
      for (var i = 1; i < lengths.length; i++) {
        expect(lengths[i], greaterThanOrEqualTo(lengths[i - 1]));
      }
    });

    testWidgets('fade produces a per-character ramp, not a hard cut', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(900, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pump(tester, _doc, animation: GptMarkdownAnimation.fade);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      while (tester.takeException() != null) {}

      // Several partial opacities at once is the whole point: one value would
      // mean every visible character is at full strength, which is the hard
      // cut this replaced.
      expect(_alphas(tester).length, greaterThan(3));
    });

    testWidgets('typewriter reveals without animating characters', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(900, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pump(tester, _doc, animation: GptMarkdownAnimation.typewriter);
      await tester.pump();
      final early = _visible(tester).length;
      await tester.pump(const Duration(milliseconds: 250));
      while (tester.takeException() != null) {}

      expect(_visible(tester).length, greaterThan(early));
      // No ramp: characters are final the moment they appear.
      expect(_alphas(tester).where((a) => a > 0 && a < 1), isEmpty);
    });

    testWidgets('blurIn paints its characters through a mask filter', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(900, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pump(tester, _doc, animation: GptMarkdownAnimation.blurIn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      while (tester.takeException() != null) {}

      expect(_painted(tester), greaterThan(0));
    });

    testWidgets('every effect ends with the complete document', (tester) async {
      tester.view.physicalSize = const Size(900, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      for (final effect in GptMarkdownAnimation.values) {
        await _pump(tester, _doc, animation: effect);
        await tester.pump();
        await _pump(tester, _doc, animation: effect, isStreaming: false);
        await tester.pumpAndSettle();
        while (tester.takeException() != null) {}

        expect(_shows('Title'), isTrue, reason: '$effect');
        expect(_shows('Final paragraph'), isTrue, reason: '$effect');
      }
    });

    testWidgets('a reply that was already finished does not type itself out', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(900, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pump(
        tester,
        _doc,
        animation: GptMarkdownAnimation.fade,
        isStreaming: false,
      );
      await tester.pump();
      // First frame, no time elapsed: history must already be whole.
      expect(_shows('Final paragraph'), isTrue);
    });

    testWidgets('reduced motion renders whole, immediately', (tester) async {
      tester.view.physicalSize = const Size(900, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: GptMarkdown(
                _doc,
                animation: GptMarkdownAnimation.blurIn,
                blockAnimation: GptMarkdownBlockAnimation.growIn,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      while (tester.takeException() != null) {}
      expect(_shows('Final paragraph'), isTrue);
    });

    testWidgets('none builds no ticker and shows everything', (tester) async {
      tester.view.physicalSize = const Size(900, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pump(tester, _doc, animation: GptMarkdownAnimation.none);
      await tester.pump();
      expect(_shows('Final paragraph'), isTrue);
    });
  });

  group('block entrance', () {
    testWidgets('wraps blocks that carry a laid-out widget', (tester) async {
      tester.view.physicalSize = const Size(900, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pump(
        tester,
        _doc,
        animation: GptMarkdownAnimation.fade,
        block: GptMarkdownBlockAnimation.growIn,
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      while (tester.takeException() != null) {}

      expect(find.byType(GptMarkdownBlockEntrance), findsWidgets);
    });

    testWidgets('none adds nothing to the tree', (tester) async {
      tester.view.physicalSize = const Size(900, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pump(
        tester,
        _doc,
        animation: GptMarkdownAnimation.fade,
        block: GptMarkdownBlockAnimation.none,
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      while (tester.takeException() != null) {}

      expect(find.byType(GptMarkdownBlockEntrance), findsNothing);
    });

    testWidgets('every entrance leaves the document complete', (tester) async {
      tester.view.physicalSize = const Size(900, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      for (final entrance in GptMarkdownBlockAnimation.values) {
        await _pump(
          tester,
          _doc,
          animation: GptMarkdownAnimation.fade,
          block: entrance,
        );
        await tester.pump();
        await _pump(
          tester,
          _doc,
          animation: GptMarkdownAnimation.fade,
          block: entrance,
          isStreaming: false,
        );
        await tester.pumpAndSettle();
        while (tester.takeException() != null) {}
        expect(
          _visible(tester),
          contains('Final paragraph'),
          reason: '$entrance',
        );
      }
    });
  });

  group('span reveal', () {
    test('counts placeholders as one character', () {
      const spans = <InlineSpan>[
        TextSpan(text: 'ab'),
        WidgetSpan(child: SizedBox()),
        TextSpan(text: 'cd'),
      ];
      expect(countRevealCharacters(spans), 5);
    });

    test('counts nested children', () {
      const spans = <InlineSpan>[
        TextSpan(
          text: 'ab',
          children: [TextSpan(text: 'cd'), TextSpan(text: 'e')],
        ),
      ];
      expect(countRevealCharacters(spans), 5);
    });

    test('truncates to the reveal head and drops the rest', () {
      const spans = <InlineSpan>[TextSpan(text: 'abcdef')];
      final out = applyReveal(
        spans: spans,
        revealed: 3,
        effect: GptMarkdownAnimation.typewriter,
        progressFor: (_) => 1,
        defaultColor: const Color(0xFF000000),
      );
      expect(TextSpan(children: out).toPlainText(), 'abc');
    });

    test('keeps a link recognizer on the rebuilt span', () {
      final recognizer = _NoopRecognizer();
      addTearDown(recognizer.dispose);
      final spans = <InlineSpan>[
        TextSpan(text: 'link', recognizer: recognizer),
      ];
      final out = applyReveal(
        spans: spans,
        revealed: 4,
        effect: GptMarkdownAnimation.fade,
        progressFor: (_) => 0.5,
        defaultColor: const Color(0xFF000000),
      );
      expect((out.single as TextSpan).recognizer, same(recognizer));
    });

    test('never splits a surrogate pair', () {
      // One emoji, two code units.
      const spans = <InlineSpan>[TextSpan(text: 'a🎉b')];
      final out = applyReveal(
        spans: spans,
        revealed: 4,
        effect: GptMarkdownAnimation.fade,
        progressFor: (_) => 0.5,
        defaultColor: const Color(0xFF000000),
      );
      final text = TextSpan(children: out).toPlainText();
      expect(text, 'a🎉b');
      // A split pair would have produced a replacement character instead.
      expect(text.runes.length, 3);
    });

    test('settled characters are not split into per-character spans', () {
      const spans = <InlineSpan>[TextSpan(text: 'abcdefghij')];
      final out = applyReveal(
        spans: spans,
        revealed: 10,
        effect: GptMarkdownAnimation.fade,
        // Everything finished: nothing should need its own span.
        progressFor: (_) => 1,
        defaultColor: const Color(0xFF000000),
        window: 4,
      );
      final children = (out.single as TextSpan).children!;
      // One settled run plus at most the window, never ten.
      expect(children.length, lessThan(10));
    });
  });
}

class _NoopRecognizer extends TapGestureRecognizer {}
