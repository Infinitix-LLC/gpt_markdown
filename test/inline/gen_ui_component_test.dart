import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

/// Passing custom components switches `GptMarkdown` off plusparse and onto the
/// regex pipeline, which is what [GenUiMd] serves.
Widget componentPipeline(
  String data, {
  Widget Function(BuildContext, String)? genUiBuilder,
}) {
  return MaterialApp(
    home: Scaffold(
      body: GptMarkdown(
        data,
        inlineDirectives:
            genUiBuilder == null ? null : [genUiDirective(genUiBuilder)],
        components: MarkdownComponent.globalComponents,
        inlineComponents: MarkdownComponent.inlineComponents,
      ),
    ),
  );
}

void main() {
  group('GenUiMd', () {
    testWidgets('passes the payload to the builder', (tester) async {
      String? captured;
      await tester.pumpWidget(
        componentPipeline(
          'Before genui{"type":"button","label":"Tap"} after',
          genUiBuilder: (context, payload) {
            captured = payload;
            return Text('GEN_UI:$payload');
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(captured, '{"type":"button","label":"Tap"}');
      expect(
        find.text('GEN_UI:{"type":"button","label":"Tap"}'),
        findsOneWidget,
      );
    });

    testWidgets('the leading star is not read as italic', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        componentPipeline(
          'genui{"a":1} and *real italic* after',
          genUiBuilder: (context, payload) {
            calls++;
            return const SizedBox.shrink();
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(calls, 1);
    });

    testWidgets('keeps nested objects and braces in strings', (tester) async {
      String? captured;
      await tester.pumpWidget(
        componentPipeline(
          r'genui{"val_scene": {"id": "a}b", "frame": {"w": 1}}}',
          genUiBuilder: (context, payload) {
            captured = payload;
            return const SizedBox.shrink();
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(captured, r'{"val_scene": {"id": "a}b", "frame": {"w": 1}}}');
    });

    testWidgets('markdown inside the payload is not parsed', (tester) async {
      String? captured;
      await tester.pumpWidget(
        componentPipeline(
          'genui{"label":"**bold** and [link](http://x.dev)"}',
          genUiBuilder: (context, payload) {
            captured = payload;
            return const SizedBox.shrink();
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(captured, '{"label":"**bold** and [link](http://x.dev)"}');
    });

    testWidgets('renders the payload as text without a builder', (
      tester,
    ) async {
      await tester.pumpWidget(componentPipeline('genui{"type":"button"}'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('{"type":"button"}', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('a missing close marker stays literal', (tester) async {
      var called = false;
      await tester.pumpWidget(
        componentPipeline(
          'genui{"type":"button"} no terminator',
          genUiBuilder: (context, payload) {
            called = true;
            return const SizedBox.shrink();
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(called, isFalse);
    });

    testWidgets('rides the generic directive component, not one of its own', (
      tester,
    ) async {
      // gen-UI is no longer a Markdown component. The parser carries any host
      // directive through one component, and gen-UI is simply a caller of it.
      expect(
        MarkdownComponent.inlineComponents.whereType<InlineDirectiveMd>(),
        isNotEmpty,
      );
    });
  });
}
