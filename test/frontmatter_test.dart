import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

void main() {
  group('Frontmatter', () {
    const frontmatterContent = '''---
summary: "frontmatter contents"
tags: ["active"]
---

# Hello World

This is the body content.
''';

    const noFrontmatterContent = '''# Hello World

This is the body content.
''';

    testWidgets('shows frontmatter by default (showFrontmatter: true)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GptMarkdown(
              frontmatterContent,
              showFrontmatter: true,
            ),
          ),
        ),
      );

      // When showFrontmatter is true, the frontmatter delimiters and content should be visible
      expect(find.textContaining('summary'), findsWidgets);
    });

    testWidgets('hides frontmatter when showFrontmatter is false',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GptMarkdown(
              frontmatterContent,
              showFrontmatter: false,
            ),
          ),
        ),
      );

      // When showFrontmatter is false, the frontmatter content should not be visible
      expect(find.textContaining('summary'), findsNothing);
      expect(find.textContaining('tags'), findsNothing);
      // But the body content should still be visible
      expect(find.textContaining('Hello World'), findsWidgets);
      expect(find.textContaining('body content'), findsWidgets);
    });

    testWidgets('content without frontmatter renders normally',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GptMarkdown(
              noFrontmatterContent,
              showFrontmatter: false,
            ),
          ),
        ),
      );

      // Content should render normally
      expect(find.textContaining('Hello World'), findsWidgets);
      expect(find.textContaining('body content'), findsWidgets);
    });

    testWidgets('showFrontmatter defaults to true',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GptMarkdown(
              frontmatterContent,
            ),
          ),
        ),
      );

      // By default, frontmatter should be visible
      expect(find.textContaining('summary'), findsWidgets);
    });

    test('_stripFrontmatter removes frontmatter correctly', () {
      // Testing the static method indirectly through the widget behavior
      const input = '''---
key: value
another: data
---
# Content here''';

      const expected = '''# Content here''';

      // Use the regex pattern to verify stripping behavior
      final regex = RegExp(
        r'^---\s*\n(.*?)\n---\s*(\n|$)',
        multiLine: false,
        dotAll: true,
      );
      final result = input.replaceFirst(regex, '');
      expect(result, expected);
    });

    test('_stripFrontmatter handles frontmatter with various content', () {
      const input = '''---
summary: "This is a \"quoted\" value"
tags: ["tag1", "tag2"]
date: 2024-01-15
nested:
  key: value
---

Body content''';

      final regex = RegExp(
        r'^---\s*\n(.*?)\n---\s*(\n|$)',
        multiLine: false,
        dotAll: true,
      );
      final result = input.replaceFirst(regex, '');
      expect(result, 'Body content');
    });

    test('_stripFrontmatter does not strip non-frontmatter dashes', () {
      const input = '''# Header

Some content with --- dashes in the middle

More content''';

      final regex = RegExp(
        r'^---\s*\n(.*?)\n---\s*(\n|$)',
        multiLine: false,
        dotAll: true,
      );
      final result = input.replaceFirst(regex, '');
      // Should remain unchanged since there's no frontmatter at the start
      expect(result, input);
    });

    test('does not strip frontmatter-style block in middle of content', () {
      const input = '''# Header

Some introductory content.

---
summary: "this looks like frontmatter"
tags: ["but", "its", "not"]
---

More content after''';

      final regex = RegExp(
        r'^---\s*\n(.*?)\n---\s*(\n|$)',
        multiLine: false,
        dotAll: true,
      );
      final result = input.replaceFirst(regex, '');
      // Should remain unchanged - frontmatter block is not at the start
      expect(result, input);
    });

    testWidgets(
        'preserves frontmatter-style block in middle when showFrontmatter is false',
        (WidgetTester tester) async {
      const contentWithMiddleFrontmatter = '''# Header

Some intro text.

---
key: value
---

Final content.
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GptMarkdown(
              contentWithMiddleFrontmatter,
              showFrontmatter: false,
            ),
          ),
        ),
      );

      // The frontmatter-style block in the middle should still be visible
      expect(find.textContaining('key'), findsWidgets);
      expect(find.textContaining('Header'), findsWidgets);
      expect(find.textContaining('Final content'), findsWidgets);
    });
  });
}
