import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

void main() {
  group('CheckBoxBuilder', () {
    testWidgets('checked checkbox calls builder with isChecked=true',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GptMarkdown(
              '[x] Task complete',
              checkBoxBuilder: (context, isChecked, child, config) {
                return Text('checkbox:$isChecked');
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('checkbox:true'), findsOneWidget);
    });

    testWidgets('unchecked checkbox calls builder with isChecked=false',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GptMarkdown(
              '[ ] Task pending',
              checkBoxBuilder: (context, isChecked, child, config) {
                return Text('checkbox:$isChecked');
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('checkbox:false'), findsOneWidget);
    });

    testWidgets('builder receives child widget with parsed content',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GptMarkdown(
              '[x] My task item',
              checkBoxBuilder: (context, isChecked, child, config) {
                // Return the child to verify it contains the parsed markdown
                return child;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('My task item'), findsOneWidget);
    });

    testWidgets('multiple checkboxes each call builder correctly',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GptMarkdown(
              '[x] Done\n[ ] Not done',
              checkBoxBuilder: (context, isChecked, child, config) {
                return Text('cb:$isChecked');
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('cb:true'), findsOneWidget);
      expect(find.text('cb:false'), findsOneWidget);
    });

    testWidgets('falls back to default when no builder provided',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GptMarkdown('[x] Default checkbox'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should render without error and contain the text
      expect(find.text('Default checkbox'), findsOneWidget);
      // Should not find our custom text
      expect(find.text('checkbox:true'), findsNothing);
    });
  });

  group('RadioButtonBuilder', () {
    testWidgets('selected radio calls builder with isSelected=true',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GptMarkdown(
              '(x) Option selected',
              radioButtonBuilder: (context, isSelected, child, config) {
                return Text('radio:$isSelected');
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('radio:true'), findsOneWidget);
    });

    testWidgets('unselected radio calls builder with isSelected=false',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GptMarkdown(
              '( ) Option not selected',
              radioButtonBuilder: (context, isSelected, child, config) {
                return Text('radio:$isSelected');
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('radio:false'), findsOneWidget);
    });

    testWidgets('builder receives child widget with parsed content',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GptMarkdown(
              '(x) My radio option',
              radioButtonBuilder: (context, isSelected, child, config) {
                // Return the child to verify it contains the parsed markdown
                return child;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('My radio option'), findsOneWidget);
    });

    testWidgets('multiple radio buttons each call builder correctly',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GptMarkdown(
              '(x) Selected\n( ) Not selected',
              radioButtonBuilder: (context, isSelected, child, config) {
                return Text('rb:$isSelected');
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('rb:true'), findsOneWidget);
      expect(find.text('rb:false'), findsOneWidget);
    });

    testWidgets('falls back to default when no builder provided',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GptMarkdown('(x) Default radio'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should render without error and contain the text
      expect(find.text('Default radio'), findsOneWidget);
      // Should not find our custom text
      expect(find.text('radio:true'), findsNothing);
    });
  });

  group('Combined builders', () {
    testWidgets('both builders can be used together', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GptMarkdown(
              '[x] Checkbox item\n(x) Radio item',
              checkBoxBuilder: (context, isChecked, child, config) {
                return Text('custom-cb:$isChecked');
              },
              radioButtonBuilder: (context, isSelected, child, config) {
                return Text('custom-rb:$isSelected');
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('custom-cb:true'), findsOneWidget);
      expect(find.text('custom-rb:true'), findsOneWidget);
    });

    testWidgets('builders receive config for styling', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GptMarkdown(
              '[x] Styled item',
              style: const TextStyle(fontSize: 20, color: Colors.red),
              checkBoxBuilder: (context, isChecked, child, config) {
                // Verify config has the style we passed
                final hasStyle = config.style?.fontSize == 20;
                return Text('has-style:$hasStyle');
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('has-style:true'), findsOneWidget);
    });
  });
}
