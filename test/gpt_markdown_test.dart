import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:gpt_markdown/custom_widgets/custom_divider.dart';
import 'package:gpt_markdown/custom_widgets/link_button.dart';

void main() {
  testWidgets('GptMarkdownTheme.of returns correct data', (tester) async {
    const linkColor = Colors.green;
    await tester.pumpWidget(
      MaterialApp(
        home: GptMarkdownTheme(
          gptThemeData: GptMarkdownThemeData(
            brightness: Brightness.light,
            linkColor: linkColor,
          ),
          child: Builder(
            builder: (context) {
              final theme = GptMarkdownTheme.of(context);
              if (theme.linkColor != linkColor) {
                // This print will definitely show if logic is reached
                print(
                  'TEST DEBUG: Expected $linkColor, got ${theme.linkColor}',
                );
              }
              return Text('Test', style: TextStyle(color: theme.linkColor));
            },
          ),
        ),
      ),
    );

    expect(find.text('Test'), findsOneWidget);
    final text = tester.widget<Text>(find.text('Test'));
    expect(text.style?.color, linkColor);
  });

  testWidgets('GptMarkdownTheme.of returns correct data from extension', (
    tester,
  ) async {
    const linkColor = Colors.purple;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: [
            GptMarkdownThemeData(
              brightness: Brightness.light,
              linkColor: linkColor,
            ),
          ],
        ),
        home: Builder(
          builder: (context) {
            final theme = GptMarkdownTheme.of(context);
            if (theme.linkColor != linkColor) {
              print(
                'TEST DEBUG: Expected $linkColor from extension, got ${theme.linkColor}',
              );
            }
            return Text(
              'Test Extension',
              style: TextStyle(color: theme.linkColor),
            );
          },
        ),
      ),
    );

    expect(find.text('Test Extension'), findsOneWidget);
    final text = tester.widget<Text>(find.text('Test Extension'));
    expect(text.style?.color, linkColor);
  });

  testWidgets('HrLine uses theme color even when GptMarkdown has style color', (
    tester,
  ) async {
    const hrColor = Colors.pink;
    const textColor = Colors.grey;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GptMarkdownTheme(
            gptThemeData: GptMarkdownThemeData(
              brightness: Brightness.light,
              hrLineColor: hrColor,
            ),
            child: const GptMarkdown(
              '---\n[Link](url)',
              style: TextStyle(color: textColor),
            ),
          ),
        ),
      ),
    );

    final dividerFinder = find.byType(CustomDivider);
    expect(dividerFinder, findsOneWidget);
    final divider = tester.widget<CustomDivider>(dividerFinder);
    expect(divider.color, hrColor);

    final linkButtonFinder = find.byType(LinkButton);
    expect(linkButtonFinder, findsOneWidget);
    final linkButton = tester.widget<LinkButton>(linkButtonFinder);
    // Should be default blue if not specified in theme, overriding global text color
    expect(linkButton.color, Colors.blue);
  });

  testWidgets('CodeField uses codeBlockBackgroundColor from theme', (
    tester,
  ) async {
    const codeBgColor = Colors.yellow;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GptMarkdownTheme(
            gptThemeData: GptMarkdownThemeData(
              brightness: Brightness.light,
              codeBlockBackgroundColor: codeBgColor,
            ),
            // Markdown code block syntax
            child: const GptMarkdown('```dart\ncode\n```'),
          ),
        ),
      ),
    );

    // CodeField renders a Material widget for background
    // We need to find the CodeField, then finding the Material widget inside it could be ambiguous
    // because GptMarkdown might use Material elsewhere (less likely).
    // Let's find by type CodeField from 'package:gpt_markdown/custom_widgets/code_field.dart'
    // But it's not exported.
    // However, we imported 'package:gpt_markdown/custom_widgets/code_field.dart' ?
    // Check imports. CodeField is likely not imported in the test file yet.
    // We can infer it by finding a Material with specific color if we are lazy,
    // or properly import CodeField.
    // Since CodeField is in lib/custom_widgets/code_field.dart and we can import it.

    final materialFinder = find.descendant(
      of: find.byType(
        Column,
      ), // CodeField is a Column inside Material? No, Material -> Column.
      matching: find.byType(Material),
    );
    // CodeField struct: Material -> Column.
    // So finding Material that wraps the code text.
    // Let's grab the Material widget that is the first child of the CodeField (if we could find CodeField).
    // Or just find all Material widgets and check if one has the color.

    final materials = tester.widgetList<Material>(find.byType(Material));
    // The Scaffold has Material, etc.
    // We expect one Material with our color.
    final matchingMaterial = materials.firstWhere(
      (m) => m.color == codeBgColor,
      orElse: () => throw Exception('No material with codeBgColor found'),
    );

    expect(matchingMaterial, isNotNull);
  });

  testWidgets('Table uses theme colors and HighlightedText has decoration', (
    tester,
  ) async {
    const hrColor = Colors.pink;
    const codeBgColor = Colors.green;
    const highlightColor = Colors.orange;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GptMarkdownTheme(
            gptThemeData: GptMarkdownThemeData(
              brightness: Brightness.light,
              hrLineColor: hrColor,
              codeBlockBackgroundColor: codeBgColor,
              highlightColor: highlightColor,
            ),
            child: const GptMarkdown('| Header |\n| -- |\n| Cell |\n\n`code`'),
          ),
        ),
      ),
    );

    // Verify Table Border Color
    final tableFinder = find.byType(Table);
    expect(tableFinder, findsOneWidget);
    final table = tester.widget<Table>(tableFinder);
    expect(table.border?.top.color, hrColor);

    // Verify Header Color
    // The header is a TableRow with a decoration.
    // We cannot easily inspect TableRow directly from widget tree as it is not a widget.
    // But we know Table usage: children -> TableRow.
    // tester.widget<Table> returns the Table widget which has children property which is List<TableRow>.
    expect(table.children.first.decoration, isA<BoxDecoration>());
    final decoration = table.children.first.decoration as BoxDecoration;
    expect(decoration.color, codeBgColor);

    // Verify HighlightedText decoration
    // It should be a Container with decoration inside a WidgetSpan
    // RichText -> TextSpan -> WidgetSpan -> Container
    final richTextFinder =
        find.byType(RichText).last; // Last because Table might use RichText too
    final richText = tester.widget<RichText>(richTextFinder);
    // traversing to find the WidgetSpan relative to `code`
    // Implementation: WidgetSpan child is Container.
    final containerFinder = find.byType(Container);
    // There might be multiple containers (Table uses padding etc).
    // Let's look for one with our highlight color.
    final highlightContainer = tester
        .widgetList<Container>(containerFinder)
        .firstWhere(
          (c) =>
              (c.decoration is BoxDecoration) &&
              (c.decoration as BoxDecoration).color == highlightColor,
          orElse: () => throw Exception('Highlight container not found'),
        );

    final boxDec = highlightContainer.decoration as BoxDecoration;
    expect(boxDec.borderRadius, BorderRadius.circular(4));
    expect(
      highlightContainer.padding,
      const EdgeInsets.symmetric(horizontal: 5),
    );
  });
}
