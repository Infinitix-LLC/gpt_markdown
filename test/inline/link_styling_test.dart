import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:gpt_markdown/custom_widgets/link_button.dart';

void main() {
  group('Link Styling', () {
    testWidgets('applies default blue color when no style is passed', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GptMarkdown('[click here](https://example.com)'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the LinkButton widget
      final linkButtonFinder = find.byType(LinkButton);
      expect(linkButtonFinder, findsOneWidget);

      final linkButton = tester.widget<LinkButton>(linkButtonFinder);
      
      // Verify default blue color is applied to the LinkButton
      expect(linkButton.color, Colors.blue);
      expect(linkButton.hoverColor, Colors.red);
    });

    testWidgets('uses custom style when style is passed (respects user customization)', (tester) async {
      const customStyle = TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.purple,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GptMarkdown(
              '[click here](https://example.com)',
              style: customStyle,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the LinkButton's child RichText to check the style
      final linkButtonFinder = find.byType(LinkButton);
      expect(linkButtonFinder, findsOneWidget);

      // Find the Text widget inside the LinkButton
      final textFinder = find.descendant(
        of: linkButtonFinder,
        matching: find.byType(Text),
      );
      expect(textFinder, findsOneWidget);

      final text = tester.widget<Text>(textFinder);
      final textSpan = text.textSpan as TextSpan;
      
      // The parent span should have the custom style (purple, not blue)
      expect(textSpan.style?.color, Colors.purple);
      expect(textSpan.style?.fontSize, 20);
      expect(textSpan.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('custom style with explicit color is respected (not overridden to blue)', (tester) async {
      const customStyle = TextStyle(
        color: Colors.green,
        decoration: TextDecoration.none,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GptMarkdown(
              '[click here](https://example.com)',
              style: customStyle,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the Text widget inside the LinkButton
      final linkButtonFinder = find.byType(LinkButton);
      final textFinder = find.descendant(
        of: linkButtonFinder,
        matching: find.byType(Text),
      );
      expect(textFinder, findsOneWidget);

      final text = tester.widget<Text>(textFinder);
      final textSpan = text.textSpan as TextSpan;

      // Custom green color should be preserved (not overridden to blue)
      expect(textSpan.style?.color, Colors.green);
      // Custom decoration (none) should be preserved
      expect(textSpan.style?.decoration, TextDecoration.none);
    });

    testWidgets('default styling includes underline decoration when no style passed', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GptMarkdown('[click here](https://example.com)'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the Text widget inside the LinkButton
      final linkButtonFinder = find.byType(LinkButton);
      final textFinder = find.descendant(
        of: linkButtonFinder,
        matching: find.byType(Text),
      );
      expect(textFinder, findsOneWidget);

      final text = tester.widget<Text>(textFinder);
      final textSpan = text.textSpan as TextSpan;

      // Default styling should include underline and blue color
      expect(textSpan.style?.decoration, TextDecoration.underline);
      expect(textSpan.style?.color, Colors.blue);
    });
  });
}
