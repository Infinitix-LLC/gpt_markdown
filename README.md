<p align="center">
  <img src="assets/gpt-mark.png" width="112" alt="gpt_markdown logo">
</p>

<h1 align="center">gpt_markdown</h1>

<p align="center"><strong>The Flutter renderer for AI output.</strong></p>

<p align="center">
  Production-grade Markdown and LaTeX rendering for streaming Flutter AI interfaces.<br>
  Render rich assistant replies, math, code, tables, citations, images, and custom inline UI in one widget.
</p>

<p align="center">
  <a href="https://pub.dev/packages/gpt_markdown"><img src="https://img.shields.io/pub/v/gpt_markdown" alt="Pub Version"></a>
  <a href="https://img.shields.io/pub/likes/gpt_markdown"><img src="https://img.shields.io/pub/likes/gpt_markdown" alt="Pub Likes"></a>
  <a href="https://img.shields.io/pub/points/gpt_markdown"><img src="https://img.shields.io/pub/points/gpt_markdown" alt="Pub Points"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-BSD--3--Clause-blue.svg" alt="BSD-3-Clause license"></a>
</p>

<p align="center">
  <a href="https://gptmarkdown.com">🌐 Website</a> ·
  <a href="https://gptmarkdown.com/docs">📖 Documentation</a> ·
  <a href="https://gptmarkdown.com/playground">🎮 Live Playground</a> ·
  <a href="https://pub.dev/packages/gpt_markdown">📦 pub.dev</a>
</p>

---

## ✨ Why gpt_markdown?

- **Built for AI output** — Markdown, LaTeX, code blocks, tables, citations, images, task lists, and mixed rich content in one response.
- **Streaming that stays fast** — only the live tail rebuilds while settled content is cached, keeping the rendering cost stable as replies grow.
- **Production-level control** — style sheets, Flutter theme extensions, component builders, callbacks, and custom components.
- **Extensible inline UI** — add `@mentions`, `#channels`, `:emoji:`, issue references, and product-specific syntax without forking the renderer.
- **Designed for real-world edge cases** — RTL, text scaling, selection, malformed Markdown, autolinks, nested content, reduced motion, Flutter web, and WASM.

## 🧩 Everything AI output needs

| | Rendering | | Production experience | | Extensibility |
|---|---|---|---|---|---|
| 📝 | Rich Markdown | ⚡ | Adaptive streaming | 🎨 | Component style sheet |
| ∑ | Inline and block LaTeX | 🚀 | Stable per-token cost | 🧱 | Structural builders |
| 💻 | Inline and fenced code | ♿ | Selection and text scaling | 🏷️ | Mentions, channels, and emoji |
| 📊 | Tables and aligned columns | 🌍 | RTL, web, and WASM | 🧩 | Custom components and scopes |
| 🔗 | Links, autolinks, and images | 🌓 | Theme-aware rendering | 👆 | Interaction callbacks |
| ☑️ | Lists, tasks, and citations | 🛡️ | Graceful malformed input | 📱 | Custom URL schemes |

## 🖼️ What it renders

Every image is one `GptMarkdown` widget with no styling applied — the defaults, in a dark theme. Click any of them for full size.

|  |  |  |
|:--|:--|:--|
| <img alt="Rich text rendered by gpt_markdown" src="https://raw.githubusercontent.com/Infinitix-LLC/gpt_markdown/main/screenshots/rich-text.png?v=2"><br>**Rich text**<br>Headings, emphasis, lists, quotes, rules, autolinks. | <img alt="LaTeX rendered by gpt_markdown" src="https://raw.githubusercontent.com/Infinitix-LLC/gpt_markdown/main/screenshots/math.png?v=2"><br>**LaTeX**<br>Inline and display equations, on the text baseline. | <img alt="Tables rendered by gpt_markdown" src="https://raw.githubusercontent.com/Infinitix-LLC/gpt_markdown/main/screenshots/tables.png?v=2"><br>**Tables**<br>Per-column alignment, Markdown inside cells. |
| <img alt="Code rendered by gpt_markdown" src="https://raw.githubusercontent.com/Infinitix-LLC/gpt_markdown/main/screenshots/code.png?v=2"><br>**Code**<br>Fenced blocks with a language header, wrapping inline code. | <img alt="Task lists rendered by gpt_markdown" src="https://raw.githubusercontent.com/Infinitix-LLC/gpt_markdown/main/screenshots/lists.png?v=2"><br>**Task lists**<br>Checkboxes, ordered and nested lists, citation tags. | <img alt="Inline patterns rendered by gpt_markdown" src="https://raw.githubusercontent.com/Infinitix-LLC/gpt_markdown/main/screenshots/inline-patterns.png?v=2"><br>**Inline patterns**<br>Mentions, channels, shortcodes. `#2959` stays text. |

## 🛠️ Quick start

```bash
flutter pub add gpt_markdown
```

```dart
import 'package:gpt_markdown/gpt_markdown.dart';

GptMarkdown(
  reply,
  onLinkTap: (url, title) => openUrl(url),
)
```

The widget sizes itself to its content. Place it inside your preferred scrollable chat or document surface.

## ⚡ Streaming AI responses

Rebuild `GptMarkdown` with the complete text received so far. The settled prefix is cached and only the part that can still change is rebuilt.

```dart
GptMarkdown(
  streamedReply,
  animation: GptMarkdownAnimation.fade,
  isStreaming: stillGenerating,
  charactersPerSecond: 300,
)
```

The reveal adapts when tokens arrive quickly, fast-forwards when generation finishes, avoids unsafe splits inside code fences and block math, and automatically respects reduced-motion settings.

## 📝 Markdown, LaTeX, and rich AI output

````dart
GptMarkdown(
  r'''
## Revenue forecast

The projected growth is **18%**, based on:

\[
R_{next} = R_{current} \times (1 + 0.18)
\]

| Quarter | Revenue |
|:-------:|--------:|
| Q1      | $120K   |
| Q2      | $142K   |

```dart
final growth = currentRevenue * 1.18;
```

- [x] Validate the assumptions
- [ ] Review the final forecast

Sources: [1] [2]
  ''',
  onLinkTap: (url, title) => openUrl(url),
  onSourceTagTap: (source) => openSource(source),
)
````

Supported output includes:

- Headings, bold, italic, strikethrough, underline, and inline code
- Ordered, unordered, nested, task, and radio lists
- Links, bare URLs, email autolinks, images, and citations
- Tables with column alignment and horizontal overflow
- Inline and block LaTeX using `\( ... \)` and `\[ ... \]`
- Optional dollar-sign LaTeX through `useDollarSignsForLatex: true`
- Fenced code blocks with language labels, copy controls, and open-fence streaming support

Wrap the renderer with `SelectionArea` when selectable output is needed:

```dart
SelectionArea(
  child: GptMarkdown(reply),
)
```

## 🎨 Make it match your product

Use style objects for appearance and builders when you need to replace structure.

```dart
GptMarkdown(
  reply,
  styleSheet: const GptMarkdownStyleSheet(
    blockQuote: BlockQuoteStyle(
      barWidth: 4,
      barColor: Colors.indigo,
    ),
    inlineCode: InlineCodeStyle(
      fontFamily: 'GeistMono',
      borderRadius: Radius.circular(6),
    ),
    codeBlock: CodeBlockStyle(
      borderRadius: Radius.circular(12),
      showCopyButton: true,
    ),
    table: TableStyle(
      cellPadding: EdgeInsets.all(10),
    ),
  ),
  onCodeCopy: (code) => trackCopy(code),
  onImageTap: (url) => openImage(url),
)
```

Set the same styles app-wide with `GptMarkdownThemeData`, or use builders such as `codeBuilder`, `tableBuilder`, `headingBuilder`, `blockQuoteBuilder`, and `imageBuilder` for full structural control.

## 🏷️ App-specific inline UI

Render mentions, channels, emoji, issue references, and other product syntax alongside Markdown:

```dart
GptMarkdown(
  reply,
  inlinePatterns: [
    InlinePattern.prefixed(
      prefix: '#',
      knownNames: channelNames,
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

Known names are matched longest-first, and patterns do not claim link labels by default. This prevents ambiguous tokens such as `#2959` from becoming channels and avoids nested inline widgets that do not paint correctly on iOS.

For deeper integrations, use `MarkdownComponent`, `InlineMd`, and `BlockMd`. Components can declare support for `content`, `linkLabel`, `tableCell`, and `heading` scopes.

## 🔗 Autolinks

Bare URLs, `www.` hosts, email addresses, and CommonMark angle autolinks work without preprocessing:

```dart
GptMarkdown(
  'Visit https://gptmarkdown.com or email hello@example.com',
)
```

Autolinks follow GFM trimming rules, preserve balanced parentheses, and avoid leaking surrounding Markdown into the URL. Add app-specific schemes or turn bare autolinking off when needed:

```dart
GptMarkdown(
  reply,
  autolinkSchemes: const {'myapp'},
  // autolink: false,
)
```

Explicit `[label](url)` links continue working when `autolink` is disabled.

## 🚀 New in 1.2.0

- Adaptive streaming reveal with split-document caching
- `GptMarkdownStyleSheet` and twelve per-component style classes
- Builders and callbacks for every major output component
- Selectable, wrapping, baseline-aligned inline-code chips
- `InlinePattern` for product-specific inline syntax
- `MarkdownScope` for safe nested rendering
- GFM and CommonMark autolinking
- Correct RTL inline-widget ordering
- Proportional accessibility text scaling
- Theme and runtime configuration rebuild fixes
- Safer malformed-Markdown and component dispatch behavior

Upgrading from 1.1.x? Read the [migration guide](MIGRATION.md).

## 📚 Documentation

| Guide | Covers |
|---|---|
| [Getting started](docs/getting-started.md) | Installation, syntax, taps, LaTeX, RTL, and selection |
| [Customization](docs/customization.md) | Style classes, themes, builders, and callbacks |
| [Streaming](docs/streaming.md) | Pacing, performance, accessibility, and limitations |
| [Inline syntax](docs/inline-syntax.md) | Autolinks, mentions, channels, and scopes |
| [Custom components](docs/custom-components.md) | Block and inline extensions |
| [Migration](MIGRATION.md) | Changes from 1.1.x to 1.2.0 |

## 💬 Community

Issues and pull requests are welcome on [GitHub](https://github.com/Infinitix-LLC/gpt_markdown). If the package helps your project, consider giving it a like on [pub.dev](https://pub.dev/packages/gpt_markdown) or a star on GitHub.

## 📄 License

BSD 3-Clause — see [LICENSE](LICENSE).
