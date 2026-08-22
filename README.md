# gpt_markdown

## Make AI answers feel native in Flutter

[![CI](https://github.com/Infinitix-LLC/gpt_markdown/actions/workflows/ci.yml/badge.svg)](https://github.com/Infinitix-LLC/gpt_markdown/actions/workflows/ci.yml) [![Pub Version](https://img.shields.io/pub/v/gpt_markdown)](https://pub.dev/packages/gpt_markdown) [![Pub Downloads](https://img.shields.io/pub/dm/gpt_markdown)](https://pub.dev/packages/gpt_markdown) [![Pub Likes](https://img.shields.io/pub/likes/gpt_markdown)](https://pub.dev/packages/gpt_markdown) [![Pub Points](https://img.shields.io/pub/points/gpt_markdown)](https://pub.dev/packages/gpt_markdown) [![GitHub](https://img.shields.io/badge/github-gpt__markdown-blue?logo=github)](https://github.com/Infinitix-LLC/gpt_markdown)

`gpt_markdown` is a production-ready Flutter renderer for the complete shape of
an AI response: Markdown, LaTeX, fenced code, tables, links, images, citations,
task lists, radio options, and app-specific inline components.

Give it the text your model returns and get a native, themeable Flutter
experience that works while the answer is still arriving.

[Website](https://gptmarkdown.com) · [Documentation](https://gptmarkdown.com/docs) · [Live Playground](https://gptmarkdown.com/playground) · [pub.dev](https://pub.dev/packages/gpt_markdown)

---

## Why `gpt_markdown`?

AI output is not just a paragraph. A single response can move from an
explanation to a formula, then to a code block, a table, a citation, and an
interactive checklist. `gpt_markdown` renders that whole conversation in one
widget instead of forcing your app to stitch together separate renderers.

- **Built for model output** — render the formats ChatGPT, Gemini, Claude, and
  your own models naturally produce.
- **Beautiful while streaming** — reveal a growing answer smoothly without
  rebuilding the settled part of the document on every token.
- **LaTeX included** — render inline and block mathematics immediately, or
  connect your own math renderer when your product needs one.
- **Flutter-native customization** — style every major component or replace its
  rendering with a builder, without forking the parser.
- **Your app's language, too** — add `@mentions`, `#channels`, `:emoji:`,
  citations, and other inline patterns alongside Markdown.
- **Ready for real interfaces** — links, copyable code, selectable text,
  interactive checkboxes, RTL content, text scaling, reduced motion, web, and
  WASM are all part of the rendering experience.

---

## Install

```bash
flutter pub add gpt_markdown
```

Then import the package:

```dart
import 'package:gpt_markdown/gpt_markdown.dart';
```

## Quick start

Pass the response text directly to `GptMarkdown`:

```dart
SingleChildScrollView(
  padding: const EdgeInsets.all(16),
  child: GptMarkdown(
    reply,
    onLinkTap: (url, title) {
      // Open the URL with the launcher used by your app.
    },
  ),
)
```

The widget renders headings, emphasis, links, lists, code, tables, task lists,
and LaTeX without a separate preprocessing step.

---

## One widget for the complete AI response

### Markdown that reads like a real answer

```dart
GptMarkdown(
  '''
## Shipping summary

The new release is **faster**, easier to theme, and ready for your next
Flutter AI interface.

- **Bold** and *italic* emphasis
- [Links](https://gptmarkdown.com)
- `inline code`
- [x] Completed work
- [ ] Next step

| Capability | Status |
| --- | --- |
| Streaming | Ready |
| LaTeX | Ready |
| Custom components | Ready |
''',
)
```

### Mathematics without extra plumbing

Inline expressions such as `\(E = mc^2\)` and block expressions such as the
following render as part of the same document:

```markdown
\[
\int_{0}^{1} x^2 \, dx = \frac{1}{3}
\]
```

The package includes a default renderer through `flutter_math_fork`. If your
application needs a different math engine, provide a `latexBuilder`:

```dart
import 'package:flutter_math_fork/flutter_math.dart';

GptMarkdown(
  reply,
  latexBuilder: (context, tex, style, isInline) {
    return Math.tex(
      tex,
      textStyle: style,
      onErrorFallback: (error) => Text(tex, style: style),
    );
  },
)
```

Dollar-sign delimiters are available when your model uses them:

```dart
GptMarkdown(
  reply,
  useDollarSignsForLatex: true,
)
```

### Code that is useful, not just formatted

Fenced code blocks support language labels, copy actions, custom rendering, and
streaming-aware completion. Inline code is rendered as a baseline-aligned
monospace chip that remains selectable and wraps across lines.

```dart
GptMarkdown(
  reply,
  onCodeCopy: (code, language) {
    // Put the code on the clipboard or show your own confirmation.
  },
)
```

### Links, images, citations, and actions

Connect rendered content to your product with callbacks for links, images,
source tags, code, and interactive controls:

```dart
GptMarkdown(
  reply,
  onLinkTap: (url, title) => openUrl(url),
  onImageTap: showImage,
  onSourceTagTap: openSource,
  onCodeCopy: copyCode,
  onCheckboxChanged: saveTaskState,
)
```

Set `CheckboxStyle(interactive: true)` in the style sheet when task-list
checkboxes should accept taps.

---

## Designed for streaming AI output

Give `GptMarkdown` the accumulated text received so far. While the model is
generating, the renderer keeps the stable prefix intact and reveals the
unfinished tail. When generation ends, it fast-forwards to the complete
response.

```dart
GptMarkdown(
  accumulatedReply,
  animation: GptMarkdownAnimation.fade,
  isStreaming: isGenerating,
)
```

Streaming is opt-in, so static Markdown has no animation overhead. The reveal
also respects `MediaQuery.disableAnimations`, making the experience comfortable
for users who prefer reduced motion.

See the [streaming guide](docs/streaming.md) for pacing, completion, and
integration patterns.

---

## Every part of the output is configurable

### Style without rebuilding the renderer

`GptMarkdownStyleSheet` gives you focused style classes for headings, links,
lists, block quotes, code, tables, images, LaTeX, checkboxes, source tags,
horizontal rules, and inline code. Set only what you want to change:

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

For consistent app-wide styling, use the theme extension:

```dart
MaterialApp(
  theme: ThemeData(
    extensions: [
      GptMarkdownThemeData(
        brightness: Brightness.light,
        styleSheet: const GptMarkdownStyleSheet(
          link: LinkStyle(decoration: TextDecoration.none),
          table: TableStyle(cellPadding: EdgeInsets.all(10)),
        ),
      ),
    ],
  ),
)
```

Unset fields inherit the surrounding Flutter `ColorScheme`, so your Markdown
automatically belongs to the rest of the application.

### Builders when style is not enough

Replace individual components with your own Flutter widgets while keeping the
package's parsing and layout behavior:

- `codeBlockBuilder` for custom code viewers
- `latexBuilder` for a different math engine
- `linkBuilder` and `imageBuilder` for product-specific interactions
- `tableBuilder` for a custom data table
- `headingBuilder`, `blockQuoteBuilder`, and `hrBuilder` for branded structure
- `orderedListBuilder`, `unOrderedListBuilder`, and list styles for custom lists
- `checkboxBuilder` and `radioOptionBuilder` for interactive controls
- `inlineCodeBuilder` for inline presentation
- `sourceTagBuilder` for citations and references

Callbacks such as `onLinkTap`, `onImageTap`, `onCodeCopy`, `onSourceTagTap`, and
`onCheckboxChanged` connect the rendered answer to your application logic.

---

## Extend Markdown with your product's inline language

Chat applications often need tokens that are not part of standard Markdown.
Register them with `inlinePatterns`—no parser fork and no component-list
reordering:

```dart
GptMarkdown(
  message,
  inlinePatterns: [
    InlinePattern.prefixed(
      prefix: '#',
      knownNames: knownChannels,
      builder: (context, match, style) {
        return WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: ChannelChip(
            name: match.group(0)!.substring(1),
          ),
        );
      },
    ),
  ],
)
```

Patterns can return `TextSpan` or `WidgetSpan`, and can be limited to specific
nesting contexts with `MarkdownScope`. This lets the same token behave
correctly in ordinary text, headings, tables, and link labels.

Autolinking is enabled by default:

- Bare `https://` and `http://` URLs
- `www.` hosts
- Email addresses
- Angle autolinks such as `<https://example.com>`
- Optional app schemes through `autolinkSchemes`

Disable it with `autolink: false` when your product handles links separately.

---

## Complete capability map

| Capability | Included behavior and control |
| --- | --- |
| Headings | `#` through `######`, with per-level styles and builders |
| Emphasis | Bold, italic, strikethrough, underline, and highlighted text |
| Inline code | Monospace chip, baseline alignment, wrapping, selection |
| Fenced code | Language labels, copy button, custom builder, streaming state |
| Tables | Markdown tables, alignment, styling, custom builder, horizontal scrolling |
| Lists | Ordered and unordered lists with custom builders and styles |
| Task lists | `- [x]` and `- [ ]`, optionally interactive |
| Radio options | `(x)` and `( )` with customizable controls |
| Block quotes | `>` with bar, background, style, and builder |
| Horizontal rules | `---` with color, thickness, padding, and builder |
| Links | Markdown links, callbacks, custom link widgets, and autolinks |
| Images | Alt text, parsed dimensions, styling, callbacks, and builders |
| LaTeX | Inline and block delimiters, default renderer, custom builder |
| Dollar math | Optional `$...$` and `$$...$$` delimiters |
| Citations | Source-tag chips and `onSourceTagTap` |
| Inline patterns | App-specific `@mention`, `#channel`, emoji, and tokens |
| Custom components | Block and inline components with scoped matching |
| Streaming | Animated reveal, stable-prefix rendering, pacing, fast-forward |
| Selection | Works with Flutter's `SelectionArea` |
| RTL | Correct visual order for inline widgets in mixed-direction text |
| Accessibility | Text scaling and reduced-motion support |
| Platforms | Flutter mobile, desktop, web, and WASM without platform plugins |

---

## Documentation

- [Getting started](docs/getting-started.md) — installation, syntax, callbacks,
  LaTeX, RTL, and selection
- [Customization](docs/customization.md) — style classes, builders, and themes
- [Streaming](docs/streaming.md) — pacing, performance, and reduced motion
- [Inline syntax](docs/inline-syntax.md) — autolinks, patterns, and scopes
- [Custom components](docs/custom-components.md) — block and inline components
- [Testing](docs/testing.md) — testing rendered Markdown and custom components
- [Migration guide](MIGRATION.md) — upgrading from 1.1.x to 1.2.0
- [Live Playground](https://gptmarkdown.com/playground) — try the renderer in
  your browser

---

## Requirements

- Flutter `>=3.0.0`
- Dart `>=3.7.0 <4.0.0`

## Contributing

Issues, ideas, and pull requests are welcome on
[GitHub](https://github.com/Infinitix-LLC/gpt_markdown/issues).

## License

MIT — see [LICENSE](LICENSE).