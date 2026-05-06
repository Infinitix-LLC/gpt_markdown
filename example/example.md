# example

```dart
import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

void main() {
  runApp(const MyApp());
}

const _demoContent = \'\'\'
# GPT Markdown Demo

**Bold**, *italic*, ~~strikethrough~~, and `inline code` all work out of the box.

[Visit pub.dev](https://pub.dev/packages/gpt_markdown)

> Block quotes are supported too — great for AI-generated citations.

---

### Lists

Unordered:

- Flutter
- Dart
- gpt_markdown

Ordered:

1. Install the package
2. Pass your markdown string
3. Profit 🎉

### LaTeX

Inline: \\(E = mc^2\\) and block:

\\[
\\int_0^\\infty e^{-x^2}\\,dx = \\frac{\\sqrt{\\pi}}{2}
\\]

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
| Links       | ✅        |

### Task list

- [x] Install gpt\_markdown
- [x] Render AI responses beautifully
- [ ] Ship to production
\'\'\';

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
        extensions: [GptMarkdownThemeData(brightness: Brightness.light)],
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.blue,
        extensions: [GptMarkdownThemeData(brightness: Brightness.dark)],
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
          selectable: true,
          onLinkTap: (url, title) => debugPrint('Link tapped: $url'),
        ),
      ),
    );
  }
}
```

Enable text selection on desktop and web with `selectable: true`:

```dart
GptMarkdown(
  markdownText,
  selectable: true,
)
```

Customize colours with `GptMarkdownTheme`:

```dart
GptMarkdownTheme(
  gptThemeData: GptMarkdownThemeData.of(context).copyWith(
    highlightColor: Colors.amber,
    linkColor: Colors.blue,
  ),
  child: GptMarkdown(markdownText),
)
```

Use `tableBuilder` to fully control table rendering:

```dart
GptMarkdown(
  markdownText,
  tableBuilder: (context, tableRows, textStyle, config) {
    return Table(
      border: TableBorder.all(color: Colors.grey),
      children: tableRows.map((row) {
        return TableRow(
          decoration: row.isHeader
              ? const BoxDecoration(color: Color(0xFFEEEEEE))
              : null,
          children: row.fields
              .map((cell) => Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(cell.data, textAlign: cell.alignment),
                  ))
              .toList(),
        );
      }).toList(),
    );
  },
)
```

See the [README](https://github.com/Infinitix-LLC/gpt_markdown) and try the live [playground](https://gptmarkdown.com/playground) for more.
