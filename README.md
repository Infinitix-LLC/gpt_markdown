# ✨ gpt_markdown — Render AI Answers Beautifully in Flutter

[![CI](https://github.com/Infinitix-LLC/gpt_markdown/actions/workflows/ci.yml/badge.svg)](https://github.com/Infinitix-LLC/gpt_markdown/actions/workflows/ci.yml) [![Pub Version](https://img.shields.io/pub/v/gpt_markdown)](https://pub.dev/packages/gpt_markdown) [![Pub Likes](https://img.shields.io/pub/likes/gpt_markdown)](https://pub.dev/packages/gpt_markdown) [![Pub Points](https://img.shields.io/pub/points/gpt_markdown)](https://pub.dev/packages/gpt_markdown) [![GitHub](https://img.shields.io/badge/github-gpt__markdown-blue?logo=github)](https://github.com/Infinitix-LLC/gpt_markdown)

One native Flutter widget for the full shape of a modern AI answer: streaming
Markdown, LaTeX, code, tables, links, images, citations, task lists, and the
product-specific components your assistant needs.

Built for ChatGPT, Gemini, Claude, and any model that returns Markdown.

🌐 [gptmarkdown.com](https://gptmarkdown.com) · 📖 [Documentation](https://gptmarkdown.com/docs) · 🎮 [Live Playground](https://gptmarkdown.com/playground)

<p align="center">
  <img
    width="614"
    alt="A complete AI response rendered by gpt_markdown in Flutter"
    src="https://github.com/Infinitix-LLC/gpt_markdown/assets/59507062/8f4a4068-a12c-45d1-a954-ebaf3822e754"
  >
</p>

<p align="center"><em>Markdown, LaTeX, code, and structured content—rendered together as one native Flutter answer.</em></p>

---

## 🚀 Built for the Way AI Answers Actually Look

AI output is rarely just a paragraph. It is an explanation followed by a
formula, a table, a code block, a citation, and a checklist—often while the
answer is still arriving. `gpt_markdown` renders the whole response in one
cohesive Flutter surface.

- **Show the complete answer** — rich Markdown, math, code, tables, links,
  images, citations, and interactive task controls work together.
- **Stream without the jank** — keep the stable prefix of a reply intact while
  newly generated text reveals naturally.
- **Make it belong in your app** — use your theme, style individual components,
  or replace any piece with a custom Flutter builder.
- **Teach it your product language** — add `@mentions`, `#channels`,
  `:emoji:`, source tags, and other inline patterns without forking the parser.
- **Respect real users** — selection, RTL, text scaling, and reduced motion are
  built into the rendering experience.

---

## ✨ Everything Your Assistant Can Send

| Category | Built-in support |
| --- | --- |
| 📝 Rich text | Headings, bold, italic, strikethrough, underline, highlight, indentation, and horizontal rules |
| 📋 Structured content | Ordered lists, unordered lists, tables, block quotes, task lists, and radio options |
| 💻 Code | Fenced code blocks, language labels, copy callbacks, custom viewers, and baseline-aligned inline code |
| 🔢 Mathematics | Inline `\(...\)` and block `\[...\]` LaTeX, optional dollar delimiters, and custom math builders |
| 🔗 Connected content | Markdown links, GFM-style autolinks, email links, app URL schemes, images, and citation/source tags |
| 🧩 Product-specific UI | Custom block and inline components, `InlinePattern`, `MarkdownScope`, and component builders |
| 🌊 Streaming | Animated reveal, stable-prefix rendering, pacing, fast-forward on completion, and reduced-motion support |
| 🎨 Design control | Per-component styles, app-wide themes, callbacks, and custom Flutter builders |
| 🌍 Production details | `SelectionArea`, RTL, proportional text scaling, mobile, desktop, web, and WASM support |

---

## 🛠️ Render a Complete Answer in Minutes

```bash
flutter pub add gpt_markdown
```

```dart
import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

GptMarkdown(
  r'''
## Your release is ready

Here is the **short version**: faster answers, richer formatting, and
math that reads naturally.

\[
E = mc^2
\]

| Capability | Status |
| --- | --- |
| Streaming | Ready |
| LaTeX | Ready |
| Custom UI | Ready |

- [x] Review the response
- [ ] Share it with the team
  ''',
  onLinkTap: (url, title) => debugPrint('Open: $url'),
)
```

That single widget renders headings, emphasis, LaTeX, tables, task lists,
inline code, links, and every other supported component in the same answer.

---

## 🌊 Make Streaming Feel Native

Pass the accumulated response text as it grows. The settled portion stays
stable; only the unfinished tail needs to update. When generation stops, the
renderer fast-forwards to the complete answer.

```dart
GptMarkdown(
  accumulatedReply,
  animation: GptMarkdownAnimation.fade,
  isStreaming: isGenerating,
)
```

Streaming is opt-in, supports configurable pacing, and respects
`MediaQuery.disableAnimations` for users who prefer reduced motion.

---

## 🎨 Style It Like Your App

Use `GptMarkdownStyleSheet` to customize exactly the pieces that need your
brand. Unset fields continue to inherit from Flutter's `ColorScheme`.

```dart
GptMarkdown(
  reply,
  styleSheet: const GptMarkdownStyleSheet(
    inlineCode: InlineCodeStyle(
      fontFamily: 'JetBrainsMono',
      borderRadius: Radius.circular(6),
    ),
    blockQuote: BlockQuoteStyle(
      barWidth: 4,
      barColor: Colors.indigo,
    ),
    codeBlock: CodeBlockStyle(
      borderRadius: Radius.circular(12),
      showCopyButton: true,
    ),
    latex: LatexStyle(
      scrollBlockHorizontally: true,
    ),
  ),
)
```

Set the same defaults app-wide with `GptMarkdownThemeData`:

```dart
ThemeData(
  extensions: [
    GptMarkdownThemeData(
      brightness: Brightness.light,
      styleSheet: const GptMarkdownStyleSheet(
        link: LinkStyle(decoration: TextDecoration.none),
        table: TableStyle(cellPadding: EdgeInsets.all(10)),
      ),
    ),
  ],
)
```

Style classes cover headings, links, lists, code, tables, images, LaTeX, block
quotes, horizontal rules, task lists, radio options, source tags, and inline
code.

---

## 🧩 Go Beyond Markdown

When your answer needs product-specific interaction, keep the parser and swap
only the surface you need.

### Builders and callbacks

Use builders for custom code viewers, math renderers, links, images, tables,
headings, block quotes, lists, task controls, radio options, inline code, and
source tags. Connect the result to your product with callbacks:

```dart
GptMarkdown(
  reply,
  onLinkTap: (url, title) => openUrl(url),
  onImageTap: (url) => showImage(url),
  onSourceTagTap: (source) => openSource(source),
  onCodeCopy: (code) => copyToClipboard(code),
  onCheckboxChanged: (value) => saveTaskState(value),
)
```

### Custom inline syntax

Add the tokens your product understands—without subclassing or parser forks:

```dart
GptMarkdown(
  text,
  inlinePatterns: [
    InlinePattern.prefixed(
      prefix: '#',
      knownNames: myChannelNames,
      builder: (context, match, style) => WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: ChannelChip(
          name: match.group(0)!.substring(1),
        ),
      ),
    ),
  ],
)
```

`MarkdownScope` lets custom content behave correctly in ordinary text,
headings, tables, and link labels. Prefer `TextSpan` patterns when you want
the token to stay selectable and wrap naturally.

---

## 🔍 The Details That Make It Feel Polished

- **Autolinks that behave correctly** — bare URLs, `www.` hosts, and email
  addresses follow the GFM autolink extension; punctuation and balanced
  parentheses stay where users expect them.
- **Inline code that behaves like text** — it wraps across lines, stays
  selectable, sits on the text baseline, and works inside links, headings, and
  table cells.
- **Math that fits the answer** — use the included renderer or provide
  `latexBuilder` for a different engine.
- **Selection and accessibility** — wrap output in `SelectionArea`; text
  scales proportionally and streaming respects reduced-motion preferences.
- **RTL that stays visually correct** — inline widgets render in the intended
  visual order within mixed-direction paragraphs.
- **Safe rendering** — malformed links and unclaimed patterns stay readable
  rather than disappearing silently.

---

## 📚 Explore the Full API

- [Getting started](docs/getting-started.md) — installation, syntax, callbacks,
  LaTeX, RTL, and selection
- [Customization](docs/customization.md) — style classes, builders, and themes
- [Streaming](docs/streaming.md) — pacing, performance, and reduced motion
- [Inline syntax](docs/inline-syntax.md) — autolinks, patterns, and scopes
- [Custom components](docs/custom-components.md) — block and inline components
- [Testing](docs/testing.md) — testing rendered Markdown and custom components

---

⭐ If you find this package helpful, please give it a like on
[pub.dev](https://pub.dev/packages/gpt_markdown)! Your support means a lot. ⭐

Need help? [Open an issue](https://github.com/Infinitix-LLC/gpt_markdown/issues)
· [Publisher](https://infinitix.tech)
· [License](LICENSE)