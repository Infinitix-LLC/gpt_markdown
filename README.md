# 📦 gpt_markdown

[![Pub Version](https://img.shields.io/pub/v/gpt_markdown)](https://pub.dev/packages/gpt_markdown)
[![Pub Points](https://img.shields.io/pub/points/gpt_markdown)](https://pub.dev/packages/gpt_markdown)
[![Pub Likes](https://img.shields.io/pub/likes/gpt_markdown)](https://pub.dev/packages/gpt_markdown)
[![GitHub](https://img.shields.io/badge/github-gpt__markdown-blue?logo=github)](https://github.com/Infinitix-LLC/gpt_markdown)

A Flutter package for rendering rich Markdown and LaTeX content, designed for seamless integration with AI outputs like ChatGPT and Gemini.

> 🎮 **[Try the live playground →](https://infinitix-llc.github.io/gpt_markdown/)**

⭐ If you find this package helpful, please give it a like on [pub.dev](https://pub.dev/packages/gpt_markdown)!

---

## Supported Features

| Feature | Supported |
|---|:---:|
| Headings (H1–H6) | ✅ |
| Bold, Italic, Strikethrough | ✅ |
| Underline (`<u>`) | ✅ |
| Inline & block LaTeX | ✅ |
| Code blocks | ✅ |
| Tables | ✅ |
| Ordered & unordered lists | ✅ |
| Blockquotes & indents | ✅ |
| Links | ✅ |
| Images (with size) | ✅ |
| Highlighted text | ✅ |
| Radio buttons & checkboxes | ✅ |
| Horizontal rule | ✅ |
| Selectable content | ✅ |
| Custom components | ✅ |

---

## Getting Started

```
flutter pub add gpt_markdown
```

```dart
import 'package:gpt_markdown/gpt_markdown.dart';

GptMarkdown(
  '**Hello** from *gpt_markdown*! \( E = mc^2 \)',
)
```

For more examples, see the [Example tab](https://pub.dev/packages/gpt_markdown/example) on pub.dev or the [live playground](https://infinitix-llc.github.io/gpt_markdown/).

---

## Key Parameters

| Parameter | Type | Description |
|---|---|---|
| `style` | `TextStyle?` | Base text style |
| `textDirection` | `TextDirection` | LTR or RTL |
| `useDollarSignsForLatex` | `bool` | Enable `$...$` LaTeX syntax |
| `onLinkTap` | `Function?` | Link tap callback |
| `latexBuilder` | `Widget Function?` | Custom LaTeX renderer |
| `codeBuilder` | `Widget Function?` | Custom code block renderer |
| `highlightBuilder` | `Widget Function?` | Custom inline code renderer |

---

## How does it compare?

`gpt_markdown` vs `flutter_markdown_plus` — the current community-maintained alternative:

| Feature | `gpt_markdown` | `flutter_markdown_plus` |
|---|:---:|:---:|
| LaTeX math (built-in) | ✅ | ❌ (separate package) |
| Inline HTML (`<u>`, etc.) | ✅ | ❌ |
| AI output optimized | ✅ | ❌ |
| Custom builder callbacks | ✅ | ✅ |
| Selectable text | ✅ | ✅ |
| RTL support | ✅ | ❌ |
| Radio & checkbox inputs | ✅ | ❌ |

---

## Additional Information

- 📦 [pub.dev](https://pub.dev/packages/gpt_markdown)
- 🐛 [Issue tracker](https://github.com/Infinitix-LLC/gpt_markdown/issues)
- 💬 [Publisher](https://infinitix.tech)
- 🎮 [Live playground](https://infinitix-llc.github.io/gpt_markdown/)
- 🌐 [Website](https://gptmarkdown.com/)
