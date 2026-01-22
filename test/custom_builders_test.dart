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

  group('rawText in config', () {
    testWidgets('checkbox builder receives rawText in config', (tester) async {
      String? capturedRawText;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GptMarkdown(
              '[x] Task complete',
              checkBoxBuilder: (context, isChecked, child, config) {
                capturedRawText = config.rawText;
                return Text('rawText:${config.rawText}');
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(capturedRawText, equals('Task complete'));
      expect(find.text('rawText:Task complete'), findsOneWidget);
    });

    testWidgets('radio button builder receives rawText in config',
        (tester) async {
      String? capturedRawText;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GptMarkdown(
              '(x) Option selected',
              radioButtonBuilder: (context, isSelected, child, config) {
                capturedRawText = config.rawText;
                return Text('rawText:${config.rawText}');
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(capturedRawText, equals('Option selected'));
      expect(find.text('rawText:Option selected'), findsOneWidget);
    });

    testWidgets('rawText contains markdown formatting', (tester) async {
      String? capturedRawText;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GptMarkdown(
              '[x] **Bold** task',
              checkBoxBuilder: (context, isChecked, child, config) {
                capturedRawText = config.rawText;
                return Text('captured');
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // rawText should contain the original markdown formatting
      expect(capturedRawText, equals('**Bold** task'));
    });

    testWidgets('multiple checkboxes each have correct rawText',
        (tester) async {
      final capturedTexts = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GptMarkdown(
              '[x] First task\n[ ] Second task',
              checkBoxBuilder: (context, isChecked, child, config) {
                capturedTexts.add(config.rawText ?? '');
                return Text('item:${config.rawText}');
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(capturedTexts, contains('First task'));
      expect(capturedTexts, contains('Second task'));
      expect(find.text('item:First task'), findsOneWidget);
      expect(find.text('item:Second task'), findsOneWidget);
    });

    testWidgets('rawText can be used for toggle identification',
        (tester) async {
      // Simulates the use case of toggling a checkbox by its text
      final toggledItems = <String, bool>{};

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GptMarkdown(
              '[x] Buy milk\n[ ] Walk dog',
              checkBoxBuilder: (context, isChecked, child, config) {
                final rawText = config.rawText!;
                return GestureDetector(
                  onTap: () {
                    toggledItems[rawText] = !isChecked;
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(isChecked
                          ? Icons.check_box
                          : Icons.check_box_outline_blank),
                      child,
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on "Buy milk" checkbox
      await tester.tap(find.text('Buy milk'));
      await tester.pumpAndSettle();

      // Verify the correct item was identified for toggling
      expect(toggledItems['Buy milk'], equals(false)); // was checked, now false
    });
  });
}
