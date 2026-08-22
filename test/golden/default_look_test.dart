import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

/// Locks the default appearance.
///
/// Customization work must not change how anything looks out of the box. These
/// goldens are captured before a refactor and must still pass after it without
/// `--update-goldens`. If one fails, a default moved.
const _cases = <String, String>{
  'blockquote':
      '> A quoted line with `code`, **bold** and a\n'
      '> [link](https://example.com) inside it.\n\n'
      'Text after the quote.',
  'lists': '- first item\n- second item\n\n1. one\n2. two',
  'checkbox': '- [x] done already\n- [ ] still to do',
  'headings': '# Heading one\n\n## Heading two\n\nBody text.',
  'table': '| A | B |\n|---|---|\n| 1 | 2 |',
  'code_block': '```dart\nvar x = 1;\n```',
  'inline':
      'Text with `code`, **bold**, *italic* and '
      '[a link](https://example.com).',
  'rule': 'above\n\n---\n\nbelow',
};

Future<void> _loadFonts() async {
  final home = Platform.environment['HOME'];
  if (home == null) {
    return;
  }
  final fonts = '$home/develop/flutter/bin/cache/artifacts/material_fonts';
  final directory = Directory(fonts);
  if (!directory.existsSync()) {
    return;
  }
  final loader = FontLoader('Roboto');
  for (final name in ['Roboto-Regular.ttf', 'Roboto-Bold.ttf']) {
    final file = File('$fonts/$name');
    if (file.existsSync()) {
      loader.addFont(file.readAsBytes().then(ByteData.sublistView));
    }
  }
  await loader.load();
}

void main() {
  setUpAll(_loadFonts);

  for (final entry in _cases.entries) {
    for (final brightness in Brightness.values) {
      testWidgets('${entry.key} ${brightness.name}', (tester) async {
        tester.view.physicalSize = const Size(420, 460);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              useMaterial3: true,
              brightness: brightness,
              fontFamily: 'Roboto',
              extensions: [GptMarkdownThemeData(brightness: brightness)],
            ),
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(12),
                child: GptMarkdown(entry.value),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        while (tester.takeException() != null) {}

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('defaults/${entry.key}_${brightness.name}.png'),
        );
      });
    }
  }
}
