# gpt_markdown

[![Pub Version](https://img.shields.io/pub/v/gpt_markdown)](https://pub.dev/packages/gpt_markdown)
[![Pub Points](https://img.shields.io/pub/points/gpt_markdown)](https://pub.dev/packages/gpt_markdown)
[![Pub Likes](https://img.shields.io/pub/likes/gpt_markdown)](https://pub.dev/packages/gpt_markdown)
[![GitHub](https://img.shields.io/badge/github-gpt__markdown-blue?logo=github)](https://github.com/Infinitix-LLC/gpt_markdown)

**Markdown and LaTeX renderer for Flutter — built for AI-generated content.**

Render ChatGPT, Gemini, and Claude responses beautifully in your Flutter app. Supports the full Markdown spec plus inline and block LaTeX math, with a simple drop-in widget.

🌐 [gptmarkdown.com](https://gptmarkdown.com) · 📖 [Docs](https://gptmarkdown.com/docs) · 🎮 [Playground](https://gptmarkdown.com/playground)

---

## Installation

```
flutter pub add gpt_markdown
```

## Usage

```dart
import 'package:gpt_markdown/gpt_markdown.dart';

GptMarkdown(
  r'**Hello!** Here is the quadratic formula: \( x = \frac{-b \pm \sqrt{b^2-4ac}}{2a} \)',
)
```

That's it. LaTeX, bold, italic, tables, code blocks, and more all work out of the box.

---

## Supported Features

| Feature | Supported |
|---|:---:|
| Headings (H1–H6) | ✅ |
| Bold, italic, strikethrough | ✅ |
| Underline (`<u>`) | ✅ |
| Inline & block LaTeX math | ✅ |
| Code blocks | ✅ |
| Tables | ✅ |
| Ordered & unordered lists | ✅ |
| Blockquotes & indents | ✅ |
| Links | ✅ |
| Images (with size) | ✅ |
| Highlighted text | ✅ |
| Radio buttons & checkboxes | ✅ |
| Horizontal rule | ✅ |
| Selectable text | ✅ |
| Custom components | ✅ |

---

## Key Parameters

| Parameter | Type | Description |
|---|---|---|
| `style` | `TextStyle?` | Base text style |
| `textDirection` | `TextDirection` | LTR or RTL support |
| `useDollarSignsForLatex` | `bool` | Enable `$...$` LaTeX syntax |
| `onLinkTap` | `Function?` | Handle link taps |
| `latexBuilder` | `Widget Function?` | Custom LaTeX renderer |
| `codeBuilder` | `Widget Function?` | Custom code block renderer |
| `highlightBuilder` | `Widget Function?` | Custom inline code renderer |

---

## How does it compare?

| Feature | `gpt_markdown` | `flutter_markdown_plus` |
|---|:---:|:---:|
| LaTeX math (built-in) | ✅ | ❌ |
| Inline HTML (`<u>`, etc.) | ✅ | ❌ |
| AI output optimized | ✅ | ❌ |
| Custom builder callbacks | ✅ | ✅ |
| Selectable text | ✅ | ✅ |
| RTL support | ✅ | ❌ |
| Radio & checkbox inputs | ✅ | ❌ |

---

## Additional Information

- 🌐 [Website](https://gptmarkdown.com)
- 📖 [Documentation](https://gptmarkdown.com/docs)
- 🎮 [Live playground](https://gptmarkdown.com/playground)
- 📦 [pub.dev](https://pub.dev/packages/gpt_markdown)
- 🐛 [Issue tracker](https://github.com/Infinitix-LLC/gpt_markdown/issues)
- 💬 [Publisher](https://infinitix.tech)

