# 📦 gpt_markdown

[![Pub Version](https://img.shields.io/pub/v/gpt_markdown)](https://pub.dev/packages/gpt_markdown)
[![Pub Points](https://img.shields.io/pub/points/gpt_markdown)](https://pub.dev/packages/gpt_markdown)
[![Pub Likes](https://img.shields.io/pub/likes/gpt_markdown)](https://pub.dev/packages/gpt_markdown)
[![GitHub](https://img.shields.io/badge/github-gpt__markdown-blue?logo=github)](https://github.com/Infinitix-LLC/gpt_markdown)

**Flutter's best Markdown + LaTeX renderer — built for AI-generated text.**

Render ChatGPT, Gemini, and Claude responses beautifully in your Flutter app. Drop-in replacement for `flutter_markdown` with full LaTeX support, streaming-friendly rendering, and rich customization via builder callbacks.

> 🎮 **[Try the live playground →](https://42fe2acd-b62a-4237-93d8-a26456dd8460-00-374qs6753kf2e.janeway.replit.dev)**

⭐ If this package saves you time, please [like it on pub.dev](https://pub.dev/packages/gpt_markdown) — it helps others find it!

---

## Why gpt_markdown?

| Feature | `gpt_markdown` | `flutter_markdown` |
|---|:---:|:---:|
| LaTeX / Math rendering | ✅ | ❌ |
| Streaming-safe (partial text) | ✅ | ⚠️ |
| Custom code block builder | ✅ | ✅ |
| Custom LaTeX builder | ✅ | ❌ |
| Custom link / highlight builder | ✅ | ⚠️ |
| Radio buttons & checkboxes | ✅ | ⚠️ |
| RTL text direction | ✅ | ✅ |
| Selectable text | ✅ | ✅ |
| Source tag (`[1]`) support | ✅ | ❌ |
| Dollar sign LaTeX (`$...$`) | ✅ | ❌ |

---

## Installation

```bash
flutter pub add gpt_markdown
```

---

## Quick Start

```dart
import 'package:gpt_markdown/gpt_markdown.dart';

GptMarkdown('**Hello** from _gpt_markdown_! \$E = mc^2\$')
```

That's it. LaTeX, bold, italic, tables, code blocks — all rendered automatically.

---

## Streaming AI Responses

gpt_markdown handles partial / incomplete markdown safely, making it ideal for streaming LLM output:

```dart
class StreamingMessage extends StatefulWidget {
  final Stream<String> stream;
  const StreamingMessage({required this.stream, super.key});

  @override
  State<StreamingMessage> createState() => _StreamingMessageState();
}

class _StreamingMessageState extends State<StreamingMessage> {
  String _text = '';

  @override
  void initState() {
    super.initState();
    widget.stream.listen((chunk) {
      setState(() => _text += chunk);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GptMarkdown(_text);
  }
}
```

---

## Supported Syntax

| Element | Syntax |
|---|---|
| **Bold** | `**text**` or `__text__` |
| *Italic* | `*text*` or `_text_` |
| ~~Strike~~ | `~~text~~` |
| `Inline code` | `` `code` `` |
| Underline | `<u>text</u>` |
| Highlighted | `` `=text=` `` |
| Link | `[label](url)` |
| Image | `![alt](url)` or `![WxH alt](url)` |
| Heading | `# H1` through `###### H6` |
| Unordered list | `- item` |
| Ordered list | `1. item` |
| Checkbox | `[ ] todo` / `[x] done` |
| Radio button | `() option` / `(x) selected` |
| Table | Standard GFM table |
| Code block | ```` ```lang ```` |
| Blockquote | `> text` |
| Horizontal rule | `---` |
| Inline LaTeX | `\( expression \)` or `$expression$` |
| Block LaTeX | `\[ expression \]` or `$$expression$$` |
| Source tag | `[1]` |

---

## Customization

### Theme

Override colors and styles globally via `GptMarkdownTheme`:

```dart
GptMarkdownTheme(
  gptThemeData: GptMarkdownThemeData(
    highlightColor: Colors.amber,
    hrLineColor: Colors.grey,
    hrLinePadding: const EdgeInsets.symmetric(vertical: 8),
    autoAddDividerLineAfterH1: true,
    // h1–h6 styles via Flutter's TextTheme
  ),
  child: GptMarkdown(data),
)
```

---

### Code Blocks

Add syntax highlighting, a copy button, or any custom widget:

```dart
GptMarkdown(
  data,
  codeBuilder: (context, language, code, closed) {
    return MyCodeHighlighter(language: language, code: code);
  },
)
```

---

### LaTeX

Use your own LaTeX renderer or add scroll/copy behavior:

```dart
GptMarkdown(
  data,
  latexBuilder: (context, tex, textStyle, inline) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Math.tex(tex, textStyle: textStyle),
    );
  },
  // Clean up model output before rendering
  latexWorkaround: (tex) => tex.replaceAll('align*', 'aligned'),
)
```

Enable `$...$` / `$$...$$` syntax (off by default to avoid conflicts):

```dart
GptMarkdown(data, useDollarSignsForLatex: true)
```

---

### Links

```dart
GptMarkdown(
  data,
  onLinkTap: (url, title) => launchUrl(Uri.parse(url)),
  linkBuilder: (context, label, url, style) {
    return Text.rich(label, style: style.copyWith(color: Colors.blue));
  },
)
```

---

### Images

```dart
GptMarkdown(
  data,
  imageBuilder: (context, url) {
    return CachedNetworkImage(imageUrl: url);
  },
)
```

---

### Lists

```dart
GptMarkdown(
  data,
  orderedListBuilder: (context, index, child) {
    return Row(children: [
      Text('${index + 1}. ', style: const TextStyle(fontWeight: FontWeight.bold)),
      Expanded(child: child),
    ]);
  },
  unOrderedListBuilder: (context, depth, child) {
    return Row(children: [
      Text(['•', '◦', '▪'][depth % 3] + ' '),
      Expanded(child: child),
    ]);
  },
)
```

---

### Tables

```dart
GptMarkdown(
  data,
  tableBuilder: (context, rows, textStyle, config) {
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      children: rows.map((row) => TableRow(
        children: row.fields.map((cell) => Padding(
          padding: const EdgeInsets.all(8),
          child: GptMarkdown(cell.data),
        )).toList(),
      )).toList(),
    );
  },
)
```

---

### Highlighted / Inline Code

```dart
GptMarkdown(
  data,
  highlightBuilder: (context, text, style) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: style.copyWith(fontFamily: 'monospace')),
    );
  },
)
```

---

### Source Tags

Render AI citation markers like `[1]` as custom widgets:

```dart
GptMarkdown(
  data,
  sourceTagBuilder: (context, index, textStyle) {
    return GestureDetector(
      onTap: () => openSource(int.parse(index)),
      child: Chip(label: Text(index)),
    );
  },
)
```

---

### Selectable Text

Wrap in Flutter's standard `SelectionArea`:

```dart
SelectionArea(
  child: GptMarkdown(data),
)
```

---

### Custom Components

Disable built-in components or inject your own parsers:

```dart
GptMarkdown(
  data,
  components: [
    CodeBlockMd(),
    TableMd(),
    HTag(),
    BoldMd(),
    ItalicMd(),
    LatexMath(),
    // ... pick only what you need
  ],
)
```

---

## Migration from flutter_markdown

`gpt_markdown` is a drop-in replacement. The key differences:

```dart
// flutter_markdown
MarkdownBody(data: text, onTapLink: (text, href, title) { })

// gpt_markdown — same result + LaTeX support
GptMarkdown(text, onLinkTap: (url, title) { })
```

---

## Full Example

```dart
import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: GptMarkdown(
            r'''
## Hello from gpt_markdown!

Here is the quadratic formula: \( x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a} \)

| Name  | Score |
|-------|-------|
| Alice | 98    |
| Bob   | 87    |

```python
def greet(name):
    print(f"Hello, {name}!")
```
            ''',
            onLinkTap: (url, title) => debugPrint('Tapped: $url'),
          ),
        ),
      ),
    );
  }
}
```

---

## Additional Information

- 📦 [pub.dev](https://pub.dev/packages/gpt_markdown)
- 🐛 [Issue tracker](https://github.com/Infinitix-LLC/gpt_markdown/issues)
- 💬 [Publisher](https://infinitix.tech)
- 🎮 [Live playground](https://42fe2acd-b62a-4237-93d8-a26456dd8460-00-374qs6753kf2e.janeway.replit.dev)
