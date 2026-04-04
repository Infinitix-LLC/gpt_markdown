import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:gpt_markdown/custom_widgets/markdown_config.dart';

void main() {
  group('ListGroupMd', () {
    testWidgets('multiple consecutive list items are grouped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GptMarkdown('- Item 1\n- Item 2\n- Item 3'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should find Column widget containing the grouped items
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('single list item is NOT grouped (handled by UnOrderedList)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GptMarkdown('- Single item'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Single item should still render (using UnOrderedList, not ListGroupMd)
      expect(find.textContaining('Single item'), findsOneWidget);
    });

    testWidgets('listGroupBuilder callback is called with correct items',
        (tester) async {
      List<ListGroupItem>? capturedItems;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GptMarkdown(
                '- First\n- Second\n- Third',
                listGroupBuilder: (context, items, config) {
                  capturedItems = items;
                  return Column(
                    children: items
                        .map((item) => Text('Custom: ${item.rawText}'))
                        .toList(),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify callback was called with correct items
      expect(capturedItems, isNotNull);
      expect(capturedItems!.length, equals(3));
      expect(capturedItems![0].index, equals(0));
      expect(capturedItems![0].rawText, equals('First'));
      expect(capturedItems![1].index, equals(1));
      expect(capturedItems![1].rawText, equals('Second'));
      expect(capturedItems![2].index, equals(2));
      expect(capturedItems![2].rawText, equals('Third'));

      // Verify custom rendering was applied
      expect(find.text('Custom: First'), findsOneWidget);
      expect(find.text('Custom: Second'), findsOneWidget);
      expect(find.text('Custom: Third'), findsOneWidget);
    });

    testWidgets('fallback rendering when listGroupBuilder is null',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GptMarkdown('- Alpha\n- Beta'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should render items individually (fallback behavior)
      expect(find.textContaining('Alpha'), findsOneWidget);
      expect(find.textContaining('Beta'), findsOneWidget);
    });

    testWidgets('mixed dash and asterisk markers are grouped together',
        (tester) async {
      List<ListGroupItem>? capturedItems;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GptMarkdown(
                '- Dash item\n* Asterisk item',
                listGroupBuilder: (context, items, config) {
                  capturedItems = items;
                  return Column(
                    children:
                        items.map((item) => Text(item.rawText)).toList(),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(capturedItems, isNotNull);
      expect(capturedItems!.length, equals(2));
      expect(capturedItems![0].rawText, equals('Dash item'));
      expect(capturedItems![1].rawText, equals('Asterisk item'));
    });

    testWidgets('ListGroupItem.content contains rendered widget',
        (tester) async {
      List<ListGroupItem>? capturedItems;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GptMarkdown(
                '- Item A\n- Item B',
                listGroupBuilder: (context, items, config) {
                  capturedItems = items;
                  // Use the pre-rendered content widgets
                  return Column(
                    children: items.map((item) => item.content).toList(),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(capturedItems, isNotNull);
      expect(capturedItems!.length, equals(2));
      // Content should be Widget instances
      expect(capturedItems![0].content, isA<Widget>());
      expect(capturedItems![1].content, isA<Widget>());
    });

    testWidgets('unOrderedListBuilder is used in fallback when set',
        (tester) async {
      bool customBuilderCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GptMarkdown(
                '- Test item\n- Another item',
                unOrderedListBuilder: (context, child, config) {
                  customBuilderCalled = true;
                  return Container(
                    color: Colors.blue,
                    child: child,
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // unOrderedListBuilder should be called for fallback rendering
      expect(customBuilderCalled, isTrue);
    });

    testWidgets('items with styled content preserve formatting',
        (tester) async {
      List<ListGroupItem>? capturedItems;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GptMarkdown(
                '- **Bold** text\n- *Italic* text',
                listGroupBuilder: (context, items, config) {
                  capturedItems = items;
                  return Column(
                    children: items.map((item) => item.content).toList(),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(capturedItems, isNotNull);
      expect(capturedItems!.length, equals(2));
      // Raw text should contain the markdown formatting
      expect(capturedItems![0].rawText, equals('**Bold** text'));
      expect(capturedItems![1].rawText, equals('*Italic* text'));
    });
  });
}
