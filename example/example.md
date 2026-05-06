# example

```dart
import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

void main() {
  runApp(const MyApp());
}

const _demoContent = '''
## Markdown & LaTeX Demo

**Bold**, *italic*, ~~strikethrough~~, and `inline code` all work out of the box.

Inline LaTeX: \$E = mc^2\$ and block LaTeX:

\$\$
\\int_0^\\infty e^{-x^2}\\,dx = \\frac{\\sqrt{\\pi}}{2}
\$\$

### Code block

```python
def greet(name: str) -> str:
    return f"Hello, {name}!"
```

### Table

| Feature     | Supported |
|-------------|-----------|
| Markdown    | ✅        |
| LaTeX       | ✅        |
| Code blocks | ✅        |
| Tables      | ✅        |
| Task lists  | ✅        |

### Task list

- [x] Install gpt_markdown
- [x] Render AI responses beautifully
- [ ] Ship to production
''';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GPT Markdown Demo',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.blue,
        extensions: [
          GptMarkdownThemeData(brightness: Brightness.light),
        ],
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.blue,
        extensions: [
          GptMarkdownThemeData(brightness: Brightness.dark),
        ],
      ),
      home: const DemoPage(),
    );
  }
}

class DemoPage extends StatelessWidget {
  const DemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GPT Markdown')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: GptMarkdown(
          _demoContent,
          onLinkTap: (url) => debugPrint('Link tapped: $url'),
        ),
      ),
    );
  }
}
```

Use `SelectableAdapter` to make any non-selectable widget selectable.

```dart
SelectableAdapter(
  selectedText: 'sin(x^2)',
  child: Math.tex('sin(x^2)'),
);
```

Use `GptMarkdownTheme` widget and `GptMarkdownThemeData` to customize the GptMarkdown.

```dart
GptMarkdownTheme(
  data: GptMarkdownThemeData.of(context).copyWith(
    highlightColor: Colors.red,
  ),
  child: GptMarkdown(text),
);
```

In theme extension you can use `GptMarkdownThemeData` to customize the GptMarkdown.

```dart
theme: ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorSchemeSeed: Colors.blue,
  extensions: [
    GptMarkdownThemeData(
      brightness: Brightness.light,
      highlightColor: Colors.red,
    ),
  ],
),
darkTheme: ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorSchemeSeed: Colors.blue,
  extensions: [
    GptMarkdownThemeData(
      brightness: Brightness.dark,
      highlightColor: Colors.red,
    ),
  ],
),
```

Use `tableBuilder` to customize table rendering:

```dart
GptMarkdown(
  markdownText,
  tableBuilder: (context, tableRows, textStyle, config) {
    return Table(
      border: TableBorder.all(width: 1, color: Colors.blue),
      children: tableRows.map((row) {
        return TableRow(
          children: row.fields.map((cell) => Text(cell.data)).toList(),
        );
      }).toList(),
    );
  },
);
```

See the [README](https://github.com/Infinitix-LLC/gpt_markdown) and try the live [playground](https://gptmarkdown.com/playground) for more details.
