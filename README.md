# ✨ GPT Markdown for Flutter — AI-Ready Markdown & LaTeX

[![CI](https://github.com/Infinitix-LLC/gpt_markdown/actions/workflows/ci.yml/badge.svg)](https://github.com/Infinitix-LLC/gpt_markdown/actions/workflows/ci.yml) [![Pub Version](https://img.shields.io/pub/v/gpt_markdown)](https://pub.dev/packages/gpt_markdown) [![Pub Likes](https://img.shields.io/pub/likes/gpt_markdown)](https://pub.dev/packages/gpt_markdown) [![Pub Points](https://img.shields.io/pub/points/gpt_markdown)](https://pub.dev/packages/gpt_markdown) [![GitHub](https://img.shields.io/badge/github-gpt__markdown-blue?logo=github)](https://github.com/Infinitix-LLC/gpt_markdown)

A production-ready Flutter renderer for the complete shape of an AI answer.
Render rich Markdown, LaTeX, code, tables, links, images, citations, and
interactive lists from ChatGPT, Gemini, Claude, or any model that speaks
Markdown—all in one native Flutter surface.

Use it as a drop-in alternative to `flutter_markdown` when your app needs
first-class LaTeX, smooth streaming, deep visual control, and AI-oriented
interactions without stitching together multiple renderers.

🌐 [gptmarkdown.com](https://gptmarkdown.com) · 📖 [Documentation](https://gptmarkdown.com/docs) · 🎮 [Live Playground](https://gptmarkdown.com/playground)

---

## 🚀 Why Use GPT Markdown?

- **Made for AI output**: Render the rich mixture of text, math, code, tables,
  links, citations, and checklists that AI assistants produce.
- **LaTeX from the first line**: Render inline and block mathematics without
  building a separate math surface.
- **Beautiful while streaming**: Reveal a growing response smoothly while
  keeping the settled part of the document stable.
- **Complete Markdown support**: Headings, emphasis, lists, tables, block
  quotes, images, links, code blocks, task lists, radio options, and more.
- **Your design system, not ours**: Start with your `ColorScheme`, tune each
  component through the style sheet, or replace any part with a Flutter builder.
- **Your product language**: Add `@mentions`, `#channels`, `:emoji:`, source
  tags, and other inline patterns without forking the parser.
- **Ready for real users**: Work with `SelectionArea`, RTL content, text
  scaling, and reduced-motion preferences.
- **Ready for every Flutter surface**: Mobile, desktop, web, and WASM support
  without platform plugins.

---

## Supported Markdown & LaTeX Features

| ✨ Feature | ✅ Supported | 🔜 Upcoming |
| --- | --- | --- |
| 💻 Inline and fenced code | ✅ | |
| 📊 Table | ✅ | |
| 📝 Heading | ✅ | |
| 📌 Unordered List | ✅ | |
| 📋 Ordered List | ✅ | |
| 🔘 Radio Button | ✅ | |
| ☑️ Check Box and task list | ✅ | |
| ➖ Horizontal Line | ✅ | |
| 🔢 Inline and block LaTeX math | ✅ | |
| ↩️ Indent | ✅ | |
| 💬 BlockQuote | ✅ | |
| 🖼️ Image with optional dimensions | ✅ | |
| ✨ Highlighted Text | ✅ | |
| ✂️ Strike Text | ✅ | |
| 🔵 Bold Text | ✅ | |
| 📜 Italic Text | ✅ | |
| 🔗 Links and automatic links | ✅ | |
| 📱 Selectable content | ✅ | |
| 🧩 Custom components | ✅ | |
| 🌊 Streaming reveal | ✅ | |
| 🎨 Per-component styles and builders | ✅ | |
| 🌍 RTL and text scaling | ✅ | |

## ✨ Key Features

Render a complete AI response—not just isolated Markdown fragments—with full
Markdown and LaTeX support in one cohesive Flutter surface.

### Lists, rules, links, and images

```markdown
- Unordered list item
1. Ordered list item

---

[Read the documentation](https://gptmarkdown.com/docs)

![100x200 image description](https://example.com/image.png)
```

Images can include dimensions in the alt text, and their rendering can be
replaced with `imageBuilder` when your app needs its own image provider,
placeholder, or viewer.

### Tables

```markdown
| Name  | Score |
|-------|-------|
| Alice | 98    |
| Bob   | 87    |
```

### Text formatting

```markdown
~~Strikethrough~~
**Bold text**
*Italic text*
<u>Underline text</u>
```

### Headings

```markdown
# Heading 1
## Heading 2
### Heading 3
#### Heading 4
##### Heading 5
###### Heading 6
```

### LaTeX formulas

Use inline `\(\frac a b\)` or block `\[\frac ab\]` expressions beside ordinary
Markdown:

```markdown
Inline: \( E = mc^2 \)

\[
x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}
\]
```

### Radio buttons and checkboxes

```markdown
() Unchecked radio
(x) Checked radio
[] Unchecked checkbox
[x] Checked checkbox
```

Task-list checkboxes can be connected to application state with
`onCheckboxChanged` and `CheckboxStyle(interactive: true)`.

### Selectable content

Enable highlighting and copying with Flutter's selection system:

```dart
SelectionArea(
  child: GptMarkdown(markdownText),
)
```

### Output from gpt_markdown

<p align="center">
  <img width="614" alt="A complete AI response rendered by gpt_markdown in Flutter" src="https://github.com/Infinitix-LLC/gpt_markdown/assets/59507062/8f4a4068-a12c-45d1-a954-ebaf3822e754">
</p>

See the Markdown, LaTeX, code, tables, links, and structured content above
rendered together as one polished Flutter response.

---

## 🛠️ Getting Started

Run this command:

```bash
flutter pub add gpt_markdown
```

## 📖 Usage

This example combines the formats an AI assistant commonly returns:

```dart
import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

GptMarkdown(
  r'''
## Hello from gpt_markdown!

Render **bold**, *italic*, ~~strikethrough~~, `inline code`, and <u>underline</u>.

Inline LaTeX: \( E = mc^2 \) and block math:

\[
x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}
\]

| Name  | Score |
|-------|-------|
| Alice | 98    |
| Bob   | 87    |

- [x] Task complete
- [ ] Task pending
  ''',
  onLinkTap: (url, title) => debugPrint('Tapped: $url'),
)
```

For the complete walkthrough, see the
[documentation](https://gptmarkdown.com/docs).

## 💡 ChatGPT Response Examples

`gpt_markdown` is made for the kind of rich answer users expect from an AI
assistant:

```markdown
## ChatGPT Response

Here is a clear answer with Markdown, LaTeX, and structured content:

### Markdown Example

- **Bold Text** for important ideas
- *Italic Text* for emphasis
- [Links](https://www.example.com) users can open
- Ordered and unordered lists for step-by-step answers

### LaTeX Example

The quadratic function is \( f(x) = x^2 + 2x + 1 \).

\[
\begin{bmatrix}
1 & 2 & 3 \\
4 & 5 & 6 \\
7 & 8 & 9
\end{bmatrix}
\]

### Conclusion

Markdown and LaTeX can live naturally inside the same Flutter conversation.
```

## 🌊 Streaming AI Responses

Pass the accumulated response text as it grows. The stable prefix stays
intact while the unfinished tail is revealed, and the renderer fast-forwards
to the complete answer when generation ends.

```dart
GptMarkdown(
  accumulatedReply,
  animation: GptMarkdownAnimation.fade,
  isStreaming: isGenerating,
)
```

Streaming is opt-in, supports configurable pacing, and respects
`MediaQuery.disableAnimations` for users who prefer reduced motion.

See the [streaming guide](docs/streaming.md) for pacing, completion, and
integration patterns.

## 🎨 Make It Look Like Your Product

Start with your Flutter `ColorScheme`, then customize only what needs to be
different. `GptMarkdownStyleSheet` gives you focused control over each rendered
component, while unset values continue to inherit naturally from your theme.

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

Set consistent defaults app-wide with `GptMarkdownThemeData`, or provide a
`styleSheet` to one widget for a local override:

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

The style system covers the whole response:

| Rendered part | Customize with |
|---|---|
| Headings | `HeadingStyle` |
| Paragraph links | `LinkStyle` |
| Ordered and unordered lists | `ListStyle` |
| Tables | `TableStyle` |
| Fenced code | `CodeBlockStyle` |
| Inline code | `InlineCodeStyle` |
| LaTeX blocks | `LatexStyle` |
| Images | `ImageStyle` |
| Block quotes and rules | `BlockQuoteStyle`, `HrStyle` |
| Checkboxes and radio options | `CheckboxStyle` |
| Citations and source tags | `SourceTagStyle` |

You can also control the widget itself with `style`, `textDirection`,
`textAlign`, `textScaler`, `maxLines`, `overflow`, `followLinkColor`, and
`useDollarSignsForLatex`.

## 🧩 Builders and Callbacks

When styling is not enough, take ownership of exactly the part of the response
your product needs to own. Keep the built-in rendering everywhere else:

- `codeBuilder` for a custom code viewer
- `latexBuilder` for a different math renderer
- `linkBuilder` and `imageBuilder` for product-specific interactions
- `tableBuilder` for a custom data table
- `headingBuilder`, `blockQuoteBuilder`, and `hrBuilder` for branded structure
- `orderedListBuilder` and `unOrderedListBuilder` for custom list layouts
- `checkboxBuilder` and `radioOptionBuilder` for interactive controls
- `inlineCodeBuilder` for custom inline code spans
- `sourceTagBuilder` for citations and references
- `components` and `inlineComponents` for custom block and inline Markdown
  components

Callbacks include `onLinkTap`, `onImageTap`, `onCodeCopy`, `onSourceTagTap`,
and `onCheckboxChanged`, so rendered content can open links, preview images,
copy code, navigate to sources, or update application state.

---

## 🔗 Autolinks

Bare URLs, `www.` hosts, and email addresses become links with no preprocessing:

```dart
GptMarkdown(
  'Ship it: https://pub.dev/packages/gpt_markdown or mail ada@example.com',
)
```

Bare autolinks follow the [GFM autolink extension](https://github.github.com/gfm/#autolinks-extension-), so punctuation and balanced parentheses are handled correctly:

| Input | Link |
|---|---|
| `see https://x.com.` | `https://x.com` — the period stays outside |
| `(https://x.com)` | `https://x.com` — the unbalanced `)` stays outside |
| `https://en.wikipedia.org/wiki/Foo_(bar)` | The whole URL — parentheses balance |
| `www.example.com` | `http://www.example.com` |
| `ada@example.com` | `mailto:ada@example.com` |
| `**https://x.com**` | A bold link — `**` never reaches the URL |

`<https://x.com>`, `<mailto:a@b.com>`, and `<a@b.com>` follow CommonMark §6.5.

### Schemes

`http`, `https`, `mailto`, and `xmpp` are linked bare. Anything else is opt-in
because a bare `myapp://thing` in prose may not be intended as a link:

```dart
GptMarkdown(text, autolinkSchemes: const {'myapp'})
```

Angle autolinks accept any scheme without the allowlist because the author
wrote the brackets deliberately. Turn automatic linking off with
`autolink: false`; explicit `[label](url)` links continue to work.

## 💬 Inline Code

Inline `` `code` `` renders as a rounded, tinted monospace chip. Unlike a
widget-based chip, it wraps across lines, stays selectable, sits on the text
baseline, and works inside links, headings, and table cells.

Restyle it with one field; everything you leave out is derived from the ambient
`ColorScheme`:

```dart
GptMarkdown(
  text,
  inlineCodeStyle: const InlineCodeStyle(
    fontFamily: 'JetBrainsMono',
    color: Color(0xFFE01E5A),
  ),
)
```

Set the same style app-wide with `GptMarkdownThemeData.inlineCode`:

```dart
ThemeData(
  extensions: [
    GptMarkdownThemeData(
      brightness: Brightness.light,
      inlineCode: const InlineCodeStyle(
        borderRadius: Radius.circular(6),
      ),
    ),
  ],
)
```

| Field | Default |
|---|---|
| `fontFamily` | Bundled JetBrains Mono, shared with code blocks |
| `fontSizeFactor` | `0.94` of the surrounding text |
| `color` | `ColorScheme.onSurface` |
| `backgroundColor` | `onSurface` at 10% light / 14% dark |
| `borderColor` | `onSurface` at 28% light / 34% dark |
| `borderWidth` | `1.0` — set `0` for no outline |
| `borderRadius` | `Radius.circular(4)` |
| `padding` | `vertical: 1` — no horizontal padding |

### When styling is not enough

`inlineCodeBuilder` returns an `InlineSpan`, keeping inline code on the
baseline, selectable, and able to wrap across lines:

```dart
GptMarkdown(
  text,
  inlineCodeBuilder: (context, code, style, codeStyle) => CodeTextSpan(
    text: code,
    style: style,
    codeStyle: codeStyle.copyWith(
      backgroundColor: code.startsWith('TODO') ? Colors.amber : null,
    ),
  ),
)
```

Return another `TextSpan` to remove the chip. If the design genuinely needs a
widget, use `baselineWidgetSpan`; a `WidgetSpan` cannot wrap across lines and
is skipped by selection, so prefer a `CodeTextSpan` where possible.

## 🏷️ Custom Inline Syntax (`@mention`, `#channel`, `:emoji:`)

Chat and social apps layer their own inline tokens on top of Markdown. Register
them with `inlinePatterns`—no subclassing and no parser fork:

```dart
GptMarkdown(
  text,
  inlinePatterns: [
    // Only known channels become chips, so #2959 can remain an issue number.
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

    // TextSpan patterns remain selectable and wrap like ordinary text.
    InlinePattern(
      pattern: RegExp(r'(?<![\w-])GH-(\d+)\b'),
      builder: (context, match, style) => TextSpan(
        text: match.group(0),
        style: style.copyWith(fontWeight: FontWeight.w600),
        recognizer: TapGestureRecognizer()
          ..onTap = () => openIssue(match.group(1)!),
      ),
    ),
  ],
)
```

Patterns are matched **ahead of** built-in components, so your app-specific
syntax can take precedence when it needs to.

### Nesting scopes

Markdown nests—link labels can contain bold text and table cells can contain
links. `MarkdownScope` lets a component declare where it applies:

| Scope | Where |
|---|---|
| `content` | Ordinary document and inline text |
| `linkLabel` | Inside the label of `[label](url)` |
| `tableCell` | Inside a table cell |
| `heading` | Inside a heading |

By default, `InlinePattern` applies everywhere except link labels. This keeps
custom `WidgetSpan`s from becoming nested placeholders that cannot paint on
iOS. Opt into all scopes when your builder returns a `TextSpan`:

```dart
InlinePattern(
  pattern: ...,
  builder: ...,
  scopes: MarkdownComponent.allScopes,
)
```

The same scope controls are available on custom `MarkdownComponent`s.

---

## 🌍 Built for Real Flutter Interfaces

- **RTL support**: Inline widgets render in the correct visual order in mixed
  direction paragraphs.
- **Text scaling**: Components scale proportionally with the user's text size.
- **Reduced motion**: Streaming animation respects
  `MediaQuery.disableAnimations`.
- **Selection**: Answers can participate in Flutter's `SelectionArea`.
- **Web and WASM**: No platform plugins are required.
- **Safe rendering**: Malformed links and unclaimed patterns stay readable
  rather than disappearing silently.

---

## 🔗 Additional Information

- 🐛 [Issue tracker](https://github.com/Infinitix-LLC/gpt_markdown/issues)
- 💬 [Publisher](https://infinitix.tech)
- 📄 [License](LICENSE)

⭐ If you find this package helpful, please give it a like on
[pub.dev](https://pub.dev/packages/gpt_markdown)! Your support means a lot. ⭐