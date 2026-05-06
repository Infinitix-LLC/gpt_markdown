# 📦 GPT Markdown & LaTeX for Flutter

[![Pub Version](https://img.shields.io/pub/v/gpt_markdown)](https://pub.dev/packages/gpt_markdown)
[![Pub Points](https://img.shields.io/pub/points/gpt_markdown)](https://pub.dev/packages/gpt_markdown)
[![Pub Likes](https://img.shields.io/pub/likes/gpt_markdown)](https://pub.dev/packages/gpt_markdown)
[![GitHub](https://img.shields.io/badge/github-gpt__markdown-blue?logo=github)](https://github.com/Infinitix-LLC/gpt_markdown)

A comprehensive Flutter package for rendering rich Markdown and LaTeX content in your apps, designed for seamless integration with AI outputs like ChatGPT and Gemini.

[![gpt_markdown playground](https://github.com/Infinitix-LLC/gpt_markdown/raw/main/screenshots/playground.jpg)](https://gptmarkdown.com/playground)

🌐 [gptmarkdown.com](https://gptmarkdown.com) · 📖 [Docs](https://gptmarkdown.com/docs) · 🎮 [Live Playground](https://gptmarkdown.com/playground)

⭐ If this package saves you time, please [like it on pub.dev](https://pub.dev/packages/gpt_markdown) — it helps others find it!

---

## 🛠️ Installation

```bash
flutter pub add gpt_markdown
```

```dart
import 'package:gpt_markdown/gpt_markdown.dart';

GptMarkdown('**Hello** from _gpt_markdown_! \$E = mc^2\$')
```

That's it. Drop it in and it just works.

---

## ✨ What it renders

Everything below is rendered by `gpt_markdown` — what you see here is exactly what your users will see in your app.

---

**Bold**, *italic*, ~~strikethrough~~, `inline code`, and <u>underline</u> all work out of the box.

---

### Headings

# Heading 1
## Heading 2
### Heading 3
#### Heading 4

---

### Lists

- Unordered list item
- Another item
  - Nested item

1. Ordered list item
2. Second item
   1. Nested ordered

---

### Checkboxes & Radio Buttons

- [x] Task complete
- [ ] Task pending
- (x) Selected option
- () Unselected option

---

### Table

| Name  | Score | Grade |
|-------|-------|-------|
| Alice | 98    | A+    |
| Bob   | 87    | B+    |
| Carol | 92    | A     |

---

### Code Block

```python
def greet(name: str) -> str:
    return f"Hello, {name}!"

print(greet("gpt_markdown"))
```

---

### Blockquote

> gpt_markdown renders everything ChatGPT and Gemini throw at it — math, tables, code, lists, and more.

---

### LaTeX Math

Inline math: \( E = mc^2 \) and \( x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a} \)

Block math:

\[
\int_{-\infty}^{\infty} e^{-x^2} \, dx = \sqrt{\pi}
\]

\[
\begin{aligned}
\nabla \cdot \mathbf{E} &= \frac{\rho}{\varepsilon_0} \\
\nabla \times \mathbf{B} &= \mu_0 \mathbf{J} + \mu_0 \varepsilon_0 \frac{\partial \mathbf{E}}{\partial t}
\end{aligned}
\]

---

### Images with size control

```
![300x200 Flutter logo](https://storage.googleapis.com/cms-storage-bucket/6a07d8a62f4308d2b854.svg)
```

---

## 🤖 Streaming AI Responses

Works safely with partial / incomplete markdown — ideal for streaming LLM output token by token:

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
    widget.stream.listen((chunk) => setState(() => _text += chunk));
  }
  @override
  Widget build(BuildContext context) => GptMarkdown(_text);
}
```

---

## 🎨 Customization

Every element is overridable via builder callbacks:

| Builder | Controls |
|---|---|
| `codeBuilder` | Code blocks — add syntax highlighting, copy button |
| `latexBuilder` | LaTeX — use your own renderer or add scroll |
| `highlightBuilder` | Inline code / highlighted text |
| `linkBuilder` | Link appearance and tap handling |
| `imageBuilder` | Images — use `CachedNetworkImage`, etc. |
| `tableBuilder` | Full table widget replacement |
| `sourceTagBuilder` | AI citation markers like `[1]` |
| `orderedListBuilder` | Ordered list item rendering |
| `unOrderedListBuilder` | Unordered list item rendering |

Apply global styles via `GptMarkdownTheme`. See the full [documentation](https://gptmarkdown.com/docs) for examples of every builder.

---

## 🔄 How does it compare?

| Feature | `gpt_markdown` | `flutter_markdown_plus` |
|---|:---:|:---:|
| LaTeX / Math rendering | ✅ | ❌ |
| Streaming-safe (partial text) | ✅ | ⚠️ |
| Inline HTML (`<u>`, `<br>`, etc.) | ✅ | ❌ |
| Radio buttons & checkboxes | ✅ | ⚠️ |
| Source tag (`[1]`) support | ✅ | ❌ |
| Dollar sign LaTeX (`$...$`) | ✅ | ❌ |
| RTL text direction | ✅ | ✅ |
| Selectable text | ✅ | ✅ |
| Custom builder callbacks | ✅ | ✅ |

---

## Additional Information

- 🌐 [Website](https://gptmarkdown.com)
- 📖 [Documentation](https://gptmarkdown.com/docs)
- 🎮 [Live playground](https://gptmarkdown.com/playground)
- 📦 [pub.dev](https://pub.dev/packages/gpt_markdown)
- 🐛 [Issue tracker](https://github.com/Infinitix-LLC/gpt_markdown/issues)
- 💬 [Publisher](https://infinitix.tech)
