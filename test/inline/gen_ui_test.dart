import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

void main() {
  group('Gen UI', () {
    testWidgets('passes captured payload to builder', (tester) async {
      String? capturedPayload;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GptMarkdown(
              'Before genui{"type":"button","label":"Tap"} after',
              genUiBuilder: (context, payload) {
                capturedPayload = payload;
                return Text('GEN_UI:$payload');
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(capturedPayload, '{"type":"button","label":"Tap"}');
      expect(
        find.text('GEN_UI:{"type":"button","label":"Tap"}'),
        findsOneWidget,
      );
    });

    testWidgets('renders payload as text without a builder', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GptMarkdown('genui{"type":"button"}'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // No builder: the payload falls back to plain text.
      expect(find.byType(RichText), findsWidgets);
    });

    testWidgets('val_scene style block on its own paragraph', (tester) async {
      String? capturedPayload;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GptMarkdown(
              'Intro text\n\ngenui{"val_scene": {"id": "abc", "frame": "wide"}}\n\nOutro',
              genUiBuilder: (context, payload) {
                capturedPayload = payload;
                return const SizedBox(width: 10, height: 10);
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(capturedPayload, '{"val_scene": {"id": "abc", "frame": "wide"}}');
    });
  });
}
