# 📦 GPT Markdown & LaTeX for Flutter

[![Pub Version](https://img.shields.io/pub/v/gpt_markdown)](https://pub.dev/packages/gpt_markdown) [![Pub Likes](https://img.shields.io/pub/likes/gpt_markdown)](https://pub.dev/packages/gpt_markdown) [![Pub Points](https://img.shields.io/pub/points/gpt_markdown)](https://pub.dev/packages/gpt_markdown) [![GitHub](https://img.shields.io/badge/github-gpt__markdown-blue?logo=github)](https://github.com/Infinitix-LLC/gpt_markdown)

A Flutter package for rendering rich Markdown and LaTeX in your app — built for AI outputs like ChatGPT and Gemini. Drop-in replacement for flutter_markdown with full LaTeX support and better AI integration.

🌐 [gptmarkdown.com](https://gptmarkdown.com) · 📖 [Docs](https://gptmarkdown.com/docs) · 🎮 [Live Playground](https://gptmarkdown.com/playground)

---

## 🚀 Why Use GPT Markdown?

- **Optimized for AI Outputs**: Render ChatGPT and Gemini responses flawlessly in your Flutter apps.
- **LaTeX out of the box**: No extra setup — math rendering works from the first line.
- **Rich Customization**: Easily apply custom styles using Flutter widgets like `TextStyle`.
- **Selectable Content**: Pass `selectable: true` to make text highlightable and copyable on desktop and web.
- **Seamless Integration**: Works out of the box with minimal setup.

---

## Supported Markdown & LaTeX Features
| ✨ Feature  | ✅ Supported | 🔜 Upcoming |
| --- | --- | --- |
| 💻 Code Block | ✅ |  |
| 📊 Table | ✅ |  |
| 📝 Heading | ✅ |  |
| 📌 Unordered List | ✅ |  |
| 📋 Ordered List | ✅ |  |
| 🔘 Radio Button | ✅ |  |
| ☑️ Check Box | ✅ |  |
| ➖ Horizontal Line | ✅ |  |
| 🔢 Latex Math | ✅ |  |
| ↩️ Indent | ✅ |
| 💬 BlockQuote | ✅ |
| 🖼️ Image | ✅ |
| ✨ Highlighted Text | ✅ |
| ✂️ Strike Text | ✅ |
| 🔵 Bold Text | ✅ |
| 📜 Italic Text | ✅ |
| 🔗 Links | ✅ |
| 📱 Selectable | ✅ |
| 🧩 Custom components | ✅ |  |
| 📎 Underline | ✅ |  |

## ✨ Key Features

Render a wide variety of content with full Markdown and LaTeX support, including:

- List 
```
- Unordered list item
1. Ordered list item
```

- Horizontal line
```
---
```

- Links 
```
[<text here>](<href>)
```

- Images with size 
```
![<width>x<height> someText](url)
```
- Table

```
| Name  | Roll |
|-------|------|
| sohag | 1    |

```

| Name  | Roll |
|-------|------|
| sohag | 1    |

- ~~Striked text~~
```
~~striked text~~
```

- **Bold text**
```
**Bold text**
```

- *Italic text*
```
*Italic text*
```

- <u>Underline text</u>
```
<u>Underline text</u>
```

- heading texts 

```
# Heading 1
## Heading 2
### Heading 3
#### Heading 4
##### Heading 5
###### Heading 6
```

- Latex formula `\(\frac a b\)` or `\[\frac ab\]`
```
\(\frac a b\)
```

- Radio button and checkbox

```
() Unchecked radio
(x) Checked radio
[] Unchecked checkbox
[x] Checked checkbox
```

- Enable text selection on desktop and web:

```dart
GptMarkdown(markdownText, selectable: true)
```

---

## 🛠️ Getting Started

Run this command:
```
flutter pub add gpt_markdown 
```

## 📖 Usage

Check the documentation [here.](https://gptmarkdown.com/docs)

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

## 💡 ChatGPT Response Examples

```markdown
## ChatGPT Response

Welcome to ChatGPT! Below is an example of a response with Markdown and LaTeX code:

### Markdown Example

You can use Markdown to format text easily. Here are some examples:

- **Bold Text**: **This text is bold**
- *Italic Text*: *This text is italicized*
- [Link](https://www.example.com): [This is a link](https://www.example.com)
- Lists:
  1. Item 1
  2. Item 2
  3. Item 3

### LaTeX Example

You can also use LaTeX for mathematical expressions. Here's an example:

- **Equation**: \( f(x) = x^2 + 2x + 1 \)
- **Integral**: \( \int_{0}^{1} x^2 \, dx \)
- **Matrix**:

\[
\begin{bmatrix}
1 & 2 & 3 \\
4 & 5 & 6 \\
7 & 8 & 9
\end{bmatrix}
\]

### Conclusion

Markdown and LaTeX can be powerful tools for formatting text and mathematical expressions in your Flutter app. If you have any questions or need further assistance, feel free to ask!
```
### Output from gpt_markdown

<img width="614" alt="Screenshot 2024-02-15 at 4 13 59 AM" src="https://github.com/saminsohag/flutter_packages/assets/59507062/8f4a4068-a12c-45d1-a954-ebaf3822e754">

If you're using flutter_markdown and need more customization or LaTeX support, gpt_markdown is a great alternative.

## 🔗 Autolinks

Bare URLs, `www.` hosts and email addresses become links with no pre-processing:

```dart
GptMarkdown('Ship it: https://pub.dev/packages/gpt_markdown or mail ada@example.com')
```

Bare autolinks follow the [GFM autolink extension](https://github.github.com/gfm/#autolinks-extension-),
so the fiddly cases come out right:

| Input | Link |
|---|---|
| `see https://x.com.` | `https://x.com` — the period stays outside |
| `(https://x.com)` | `https://x.com` — unbalanced `)` stays outside |
| `https://en.wikipedia.org/wiki/Foo_(bar)` | whole URL — parens balance |
| `www.example.com` | `http://www.example.com` |
| `ada@example.com` | `mailto:ada@example.com` |
| `**https://x.com**` | bold link, `**` never reaches the href |

`<https://x.com>`, `<mailto:a@b.com>` and `<a@b.com>` follow CommonMark §6.5.

### Schemes

`http`, `https`, `mailto` and `xmpp` are linked bare. Anything else is opt-in,
because a bare `myapp://thing` in prose usually is not meant as a link:

```dart
GptMarkdown(text, autolinkSchemes: const {'myapp'})
```

Angle autolinks accept **any** scheme without the allowlist — `<myapp://thing>`
works out of the box, since the author wrote the brackets deliberately.

Turn the whole thing off with `autolink: false`; explicit `[label](url)` links
keep working.

## 💬 Inline Code

Inline `` `code` `` renders as a rounded chip — monospace, tinted fill, hairline
outline — and, unlike a widget-based chip, it **wraps across lines**, stays
selectable, sits on the text baseline, and works inside links, headings and
table cells.

Restyle it with one field; everything you leave out is derived from the ambient
`ColorScheme`:

```dart
GptMarkdown(
  text,
  inlineCodeStyle: const InlineCodeStyle(
    fontFamily: 'GeistMono',
    color: Color(0xFFE01E5A),
  ),
)
```

App-wide instead of per widget:

```dart
ThemeData(
  extensions: [
    GptMarkdownThemeData(
      brightness: Brightness.light,
      inlineCode: const InlineCodeStyle(borderRadius: Radius.circular(6)),
    ),
  ],
)
```

| Field | Default |
|---|---|
| `fontFamily` | bundled JetBrains Mono, same as code blocks |
| `fontSizeFactor` | `0.94` of the surrounding text |
| `color` | `ColorScheme.onSurface` |
| `backgroundColor` | `onSurface` at 10% light / 14% dark |
| `borderColor` | `onSurface` at 28% light / 34% dark |
| `borderWidth` | `1.0` — set `0` for no outline |
| `borderRadius` | `Radius.circular(4)` |
| `padding` | `vertical: 1` — no horizontal padding |

### When styling is not enough

`inlineCodeBuilder` builds the span itself, and returns an `InlineSpan` rather
than a `Widget` — which is what keeps inline code on the baseline:

```dart
GptMarkdown(
  text,
  inlineCodeBuilder: (context, code, style, codeStyle) => CodeTextSpan(
    text: code,
    style: style,
    // Same painted chip, amber for anything that needs attention.
    codeStyle: codeStyle.copyWith(
      backgroundColor: code.startsWith('TODO') ? Colors.amber : null,
    ),
  ),
)
```

Return any other `TextSpan` to drop the chip. If the design genuinely needs a
widget, wrap it with `baselineWidgetSpan` so it still sits on the text baseline
— but a `WidgetSpan` cannot wrap across lines and is skipped by selection, so
prefer a `CodeTextSpan`.

Run `flutter run -t lib/inline_code_demo.dart` in `example/` to try the presets
and sliders live.

## 🏷️ Custom Inline Syntax (`@mention`, `#channel`, `:emoji:`)

Chat and social apps layer their own inline tokens on top of Markdown. Register
them with `inlinePatterns` — no subclassing, no reordering of component lists:

```dart
GptMarkdown(
  text,
  inlinePatterns: [
    // Only the channels the app knows about become chips, so `#2959` stays an
    // issue number instead of turning into a channel nobody has.
    InlinePattern.prefixed(
      prefix: '#',
      knownNames: myChannelNames,
      builder: (context, match, style) => WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: ChannelChip(name: match.group(0)!.substring(1)),
      ),
    ),

    // A TextSpan pattern stays selectable, wraps across lines, and sits on the
    // surrounding baseline. Prefer it whenever the design allows.
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

Patterns are matched **ahead of** the built-in components, so a pattern always
wins over the default reading of the same text.

### Nesting scopes

Markdown nests — a link label can contain bold text, a table cell can contain a
link. `MarkdownScope` says where a component applies:

| Scope | Where |
|---|---|
| `content` | ordinary document and inline text |
| `linkLabel` | inside the `label` of `[label](url)` |
| `tableCell` | inside a table cell |
| `heading` | inside a `#` heading |

`InlinePattern` defaults to `MarkdownComponent.allScopesExceptLinkLabel`. A link
label is already rendered inside the link's own `WidgetSpan`; a pattern that
returns a second `WidgetSpan` there produces a nested placeholder, which does
not paint on iOS. Opt back in when the builder returns a `TextSpan`:

```dart
InlinePattern(
  pattern: ...,
  builder: ...,
  scopes: MarkdownComponent.allScopes,
)
```

The same field exists on `MarkdownComponent`, for custom components:

```dart
class MyChipMd extends InlineMd {
  @override
  Set<MarkdownScope> get scopes => MarkdownComponent.allScopesExceptLinkLabel;
  // ...
}
```

Run `flutter run -t lib/inline_patterns_demo.dart` in `example/` for a live
editor covering all of this.



---

⭐ If you find this package helpful, please give it a like on [pub.dev](https://pub.dev/packages/gpt_markdown)! Your support means a lot! ⭐

## 🔗 Additional Information

- 🌐 [Website](https://gptmarkdown.com)
- 📖 [Documentation](https://gptmarkdown.com/docs)
- 🎮 [Live playground](https://gptmarkdown.com/playground)
- 📦 [pub.dev](https://pub.dev/packages/gpt_markdown)
- 🐛 [Issue tracker](https://github.com/Infinitix-LLC/gpt_markdown/issues)
- 💬 [Publisher](https://infinitix.tech)
