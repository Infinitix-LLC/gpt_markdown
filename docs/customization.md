# Customization

Two ways to change what you see, and they never overlap:

| | Use it for | Example |
|---|---|---|
| **Style object** | Appearance — colours, sizes, padding, fonts | `BlockQuoteStyle(barWidth: 4)` |
| **Builder** | Structure — replace the widget entirely | `blockQuoteBuilder: …` |

Every component supports both.

> [!TIP]
> If you are reaching for a builder to change a colour, stop — there is a style
> field for it. Builders lose the default structure, and with it every future
> improvement to that component.

---

## Where a style goes

The same object is accepted in two places.

**One widget:**

```dart
GptMarkdown(
  text,
  styleSheet: const GptMarkdownStyleSheet(
    blockQuote: BlockQuoteStyle(barWidth: 4),
  ),
)
```

**The whole app:**

```dart
MaterialApp(
  theme: ThemeData(
    extensions: [
      GptMarkdownThemeData(
        brightness: Brightness.light,
        styleSheet: const GptMarkdownStyleSheet(
          blockQuote: BlockQuoteStyle(barColor: Colors.indigo),
          codeBlock: CodeBlockStyle(borderRadius: Radius.circular(12)),
        ),
      ),
      // Dark needs its own — the extension is per ThemeData.
    ],
  ),
)
```

### The merge is per field

With both of the above in force, the quote gets `barWidth: 4` from the widget
**and** `barColor: Colors.indigo` from the theme.

```
widget field  →  theme field  →  package default
```

Overriding one value never discards the rest.

> [!NOTE]
> Every field is optional, and anything left unset resolves to the value the
> package used before it was configurable. **Adding a style sheet never changes
> how existing content looks.** A golden suite covering eight constructs in
> light and dark enforces that on every commit.

---

## HeadingStyle

`textStyle` · `padding` · `showDivider` · `dividerColor` · `dividerThickness` ·
`dividerPadding`

```dart
GptMarkdown(
  text,
  styleSheet: const GptMarkdownStyleSheet(
    heading: HeadingStyle(
      textStyle: TextStyle(letterSpacing: -0.5),
      padding: EdgeInsets.only(top: 8, bottom: 4),
      showDivider: false,
    ),
  ),
)
```

`textStyle` is merged **over** the per-level style, so you change one property
without restating the size. Per-level sizes still come from the theme:

```dart
GptMarkdownThemeData(
  brightness: Brightness.light,
  h1: Theme.of(context).textTheme.headlineMedium,
  h2: Theme.of(context).textTheme.titleLarge,
)
```

`showDivider: false` removes the rule an `h1` draws by default. Leave it null
to keep following `autoAddDividerLineAfterH1`.

**Restructure with a builder** — for example, anchors on every heading:

```dart
GptMarkdown(
  text,
  headingBuilder: (context, level, content, style) => Row(
    crossAxisAlignment: CrossAxisAlignment.baseline,
    textBaseline: TextBaseline.alphabetic,
    children: [
      Flexible(child: content),
      IconButton(icon: const Icon(Icons.link), onPressed: () {}),
    ],
  ),
)
```

`level` is 1–6, so one builder handles all six.

---

## LinkStyle

`color` · `hoverColor` · `decoration` · `decorationThickness` · `fontWeight`

```dart
styleSheet: const GptMarkdownStyleSheet(
  link: LinkStyle(
    color: Color(0xFF0B57D0),
    hoverColor: Color(0xFF0842A0),
    decoration: TextDecoration.none,
    fontWeight: FontWeight.w500,
  ),
),
```

> [!IMPORTANT]
> Links do nothing on tap unless you handle them. The package deliberately does
> not depend on a URL launcher.

```dart
GptMarkdown(text, onLinkTap: (url, title) => launchUrlString(url))
```

`title` is the label text, which is useful for confirmation dialogs:

```dart
onLinkTap: (url, title) async {
  final ok = await confirm('Open "$title"?\n$url');
  if (ok) await launchUrlString(url);
},
```

---

## InlineCodeStyle

`fontFamily` · `fontFamilyPackage` · `fontFamilyFallback` · `fontSizeFactor` ·
`fontWeight` · `color` · `backgroundColor` · `borderColor` · `borderWidth` ·
`borderRadius` · `padding` · `boxHeightStyle`

**Your app's mono font:**

```dart
styleSheet: const GptMarkdownStyleSheet(
  inlineCode: InlineCodeStyle(fontFamily: 'GeistMono'),
),
```

**A GitHub-ish chip:**

```dart
inlineCode: InlineCodeStyle(
  backgroundColor: const Color(0x14656D76),
  borderColor: Colors.transparent,
  borderRadius: const Radius.circular(6),
  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
),
```

**No chip at all, just monospace:**

```dart
inlineCode: InlineCodeStyle(
  backgroundColor: Colors.transparent,
  borderWidth: 0,
  padding: EdgeInsets.zero,
),
```

> [!TIP]
> `fontSizeFactor` is a factor, not a size, so inline code scales with whatever
> it sits in — a heading, a table cell, body text. Setting an absolute size
> breaks that.

Inline code is a real `TextSpan` with the chip painted underneath, once per
line fragment. It wraps across lines, stays selectable, sits on the baseline,
and works inside a link label — none of which a widget-based chip can do.

**Per-code styling** needs the builder:

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

Returning `CodeTextSpan` keeps the painted chip. Return a plain `TextSpan` to
drop it.

---

## ListStyle

`bulletSize` · `bulletColor` · `bulletShape` · `markerTextStyle` · `indent` ·
`gapAfterMarker`

```dart
styleSheet: const GptMarkdownStyleSheet(
  list: ListStyle(
    bulletSize: 5,
    bulletColor: Colors.indigo,
    bulletShape: BoxShape.rectangle,
    indent: 12,
    gapAfterMarker: 12,
    markerTextStyle: TextStyle(fontWeight: FontWeight.w600),
  ),
),
```

`markerTextStyle` is the `1.` on an ordered list. `bulletSize` and
`bulletColor` default to values derived from the surrounding text, so they
track your font size unless you pin them.

> [!NOTE]
> Bullets and numbers keep separate spacing defaults — 7/10 for bullets, 6/6
> for numbers. Setting `indent` or `gapAfterMarker` applies to both.

---

## CheckboxStyle

`size` · `checkedColor` · `uncheckedColor` · `checkColor` · `borderRadius` ·
`gapAfterBox` · `interactive`

Applies to both `- [x]` task lists and `(x)` radio options.

```dart
styleSheet: const GptMarkdownStyleSheet(
  checkbox: CheckboxStyle(
    size: 18,
    checkedColor: Colors.green,
    borderRadius: Radius.circular(4),
    gapAfterBox: 8,
  ),
),
```

> [!WARNING]
> Checkboxes are **read-only by default**. A Markdown checkbox renders the
> source text — ticking it does not change the text, so the change would be
> lost on the next rebuild.

To make them interactive you must opt in *and* persist the result yourself:

```dart
GptMarkdown(
  markdown,
  styleSheet: const GptMarkdownStyleSheet(
    checkbox: CheckboxStyle(interactive: true),
  ),
  onCheckboxChanged: (value) {
    // Rewrite the source, or the tick reverts on the next build.
    setState(() => markdown = toggleFirstUnchecked(markdown));
  },
)
```

---

## BlockQuoteStyle

`barWidth` · `barColor` · `barRadius` · `backgroundColor` · `padding` ·
`margin` · `textStyle`

```dart
styleSheet: const GptMarkdownStyleSheet(
  blockQuote: BlockQuoteStyle(
    barWidth: 4,
    barColor: Color(0xFF6366F1),
    barRadius: Radius.circular(2),
    backgroundColor: Color(0x0A6366F1),
    padding: EdgeInsetsDirectional.only(start: 12, top: 8, bottom: 8),
    margin: EdgeInsets.symmetric(vertical: 8),
    textStyle: TextStyle(fontStyle: FontStyle.italic),
  ),
),
```

A background is only drawn when you ask for one — no extra widget in the tree
otherwise.

**A callout style with a builder:**

```dart
GptMarkdown(
  text,
  blockQuoteBuilder: (context, content, style) => Card(
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    child: Padding(padding: const EdgeInsets.all(12), child: content),
  ),
)
```

---

## CodeBlockStyle

`backgroundColor` · `borderColor` · `borderWidth` · `borderRadius` · `padding` ·
`headerPadding` · `fontFamily` · `fontFamilyPackage` · `fontSize` ·
`textColor` · `showLanguageLabel` · `languageStyle` · `showCopyButton` ·
`copyLabel` · `copiedLabel`

```dart
styleSheet: const GptMarkdownStyleSheet(
  codeBlock: CodeBlockStyle(
    backgroundColor: Color(0xFF1E1E1E),
    textColor: Color(0xFFD4D4D4),
    borderRadius: Radius.circular(12),
    padding: EdgeInsets.all(20),
    fontFamily: 'GeistMono',
    showLanguageLabel: true,
    showCopyButton: true,
  ),
),
```

**Localise the copy button** without replacing the block:

```dart
codeBlock: CodeBlockStyle(
  copyLabel: AppLocalizations.of(context).copyCode,
  copiedLabel: AppLocalizations.of(context).copied,
),
```

**React to a copy:**

```dart
GptMarkdown(text, onCodeCopy: (code) => analytics.log('code_copied'))
```

> [!WARNING]
> Code lines do not wrap. On a phone at a raised text scale a long line
> overflows horizontally. The block scrolls sideways, but if you need it to
> wrap, replace it:

```dart
GptMarkdown(
  text,
  codeBuilder: (context, name, code, closed) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    child: SelectableText(code, style: const TextStyle(fontFamily: 'monospace')),
  ),
)
```

`closed` is false while a fence is still being streamed — useful for showing a
"generating" state.

---

## TableStyle

`borderColor` · `borderWidth` · `borderRadius` · `cellPadding` ·
`headerBackground` · `headerTextStyle` · `rowStripeColor`

```dart
styleSheet: const GptMarkdownStyleSheet(
  table: TableStyle(
    borderColor: Color(0x1F000000),
    borderWidth: 1,
    borderRadius: Radius.circular(8),
    cellPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    headerBackground: Color(0x0A000000),
    headerTextStyle: TextStyle(fontWeight: FontWeight.w600),
  ),
),
```

Tables already scroll horizontally when they exceed the available width.

---

## ImageStyle

`borderRadius` · `padding` · `fit` · `maxWidth` · `maxHeight`

```dart
styleSheet: const GptMarkdownStyleSheet(
  image: ImageStyle(
    borderRadius: Radius.circular(8),
    padding: EdgeInsets.symmetric(vertical: 8),
    maxHeight: 320,
  ),
),
```

**Cached network images**, with a placeholder and error state:

```dart
GptMarkdown(
  text,
  imageBuilder: (context, url, width, height) => CachedNetworkImage(
    imageUrl: url,
    width: width,
    height: height,
    placeholder: (context, _) => const SizedBox(
      height: 120,
      child: Center(child: CircularProgressIndicator()),
    ),
    errorWidget: (context, _, __) => const Icon(Icons.broken_image),
  ),
  onImageTap: (url) => openLightbox(url),
)
```

`width` and `height` come from the alt text when written as `WxH`.

---

## HrStyle

`thickness` · `color` · `padding`

```dart
styleSheet: const GptMarkdownStyleSheet(
  hr: HrStyle(
    thickness: 2,
    color: Color(0x1F000000),
    padding: EdgeInsets.symmetric(vertical: 16),
  ),
),
```

**A dotted rule:**

```dart
GptMarkdown(
  text,
  hrBuilder: (context, style) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 12),
    child: DottedLine(),
  ),
)
```

---

## SourceTagStyle

`backgroundColor` · `textStyle` · `size` · `shape` · `padding`

The chip drawn for a `[1]` citation, common in RAG answers.

```dart
styleSheet: const GptMarkdownStyleSheet(
  sourceTag: SourceTagStyle(
    size: 18,
    backgroundColor: Color(0xFFE8DEF8),
    shape: BoxShape.rectangle,
    textStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
  ),
),

GptMarkdown(text, onSourceTagTap: (content) => showSource(content))
```

---

## LatexStyle

`textStyle` · `padding` · `backgroundColor` · `borderRadius` ·
`scrollBlockHorizontally`

```dart
styleSheet: const GptMarkdownStyleSheet(
  latex: LatexStyle(
    scrollBlockHorizontally: true,
    padding: EdgeInsets.symmetric(vertical: 8),
    backgroundColor: Color(0x08000000),
    borderRadius: Radius.circular(6),
  ),
),
```

> [!WARNING]
> Rendered maths cannot wrap. Without `scrollBlockHorizontally: true`, a wide
> formula overflows on a phone. This is the single most common LaTeX
> complaint.

Maths still needs a renderer — see [getting started](getting-started.md#latex).

---

## Builders

Each builder receives the **fully resolved** style, so it never has to guess a
default or restate a theme colour.

| Builder | Signature |
|---|---|
| `headingBuilder` | `(context, int level, Widget content, HeadingStyle style)` |
| `blockQuoteBuilder` | `(context, Widget content, BlockQuoteStyle style)` |
| `checkboxBuilder` | `(context, bool checked, Widget content, CheckboxStyle style)` |
| `radioOptionBuilder` | `(context, bool selected, Widget content, CheckboxStyle style)` |
| `hrBuilder` | `(context, HrStyle style)` |
| `codeBuilder` | `(context, String name, String code, bool closed)` |
| `tableBuilder` | `(context, rows, TextStyle style, GptMarkdownConfig config)` |
| `imageBuilder` | `(context, String url, double? width, double? height)` |
| `latexBuilder` | `(context, String tex, TextStyle style, bool inline)` |
| `linkBuilder` | `(context, InlineSpan label, String url, TextStyle style)` |
| `inlineCodeBuilder` | `(context, String code, TextStyle style, InlineCodeStyle codeStyle)` |
| `sourceTagBuilder` | `(context, String content, TextStyle style)` |
| `orderedListBuilder` | `(context, String no, Widget child, GptMarkdownConfig config)` |
| `unOrderedListBuilder` | `(context, Widget child, GptMarkdownConfig config)` |

Reuse the style you are given rather than hard-coding:

```dart
blockQuoteBuilder: (context, content, style) => DecoratedBox(
  decoration: BoxDecoration(
    border: BorderDirectional(
      start: BorderSide(
        // Follows the theme, because the resolved style is passed in.
        color: style.barColor ?? Colors.grey,
        width: style.barWidth ?? 3,
      ),
    ),
  ),
  child: content,
),
```

### inlineCodeBuilder returns a span, not a widget

Deliberate. A `Widget` has to be wrapped in a `WidgetSpan`, which cannot wrap
across lines, is skipped by text selection, and sits off the baseline.

If you genuinely need a widget:

```dart
inlineCodeBuilder: (context, code, style, codeStyle) =>
    baselineWidgetSpan(MyChip(code: code, style: style)),
```

`baselineWidgetSpan` aligns it on the text baseline and handles text-scale
compensation. A bare `WidgetSpan` does neither.

---

## Callbacks

```dart
GptMarkdown(
  text,
  onLinkTap: (url, title) => launchUrlString(url),
  onImageTap: (url) => openLightbox(url),
  onCodeCopy: (code) => analytics.log('code_copied'),
  onSourceTagTap: (content) => showSource(content),
  onCheckboxChanged: (value) => persist(value),  // needs interactive: true
)
```

---

## Theme animation

Every style class implements `lerp`, so a theme transition animates rather than
snapping — colours, widths, radii and padding all interpolate. Nothing to
configure; it follows `ThemeData` like any other extension.

---

## Common mistakes

> [!WARNING]
> **Changing a builder at runtime does nothing.**
> `GptMarkdownConfig.isSame` decides whether spans are regenerated, and it
> cannot compare closures — any consumer writing them inline creates a new one
> every build, so comparing them would defeat the cache entirely.
>
> Give the widget a `key` that changes with the builder, or set it once.
> Styles, patterns and component lists *are* compared and do update live.

> [!WARNING]
> **A raw `WidgetSpan` scales twice.**
> A paragraph lays inline children out in scaled space and multiplies their
> reported size back. A child that also scales its own text reserves far more
> room than it needs at a raised system font setting.
>
> Use `baselineWidgetSpan`, or wrap the child in
> `MediaQuery.withNoTextScaling`.

> [!NOTE]
> **Dark mode needs its own extension.** `GptMarkdownThemeData` lives on
> `ThemeData`, so `theme:` and `darkTheme:` each need one — with
> `brightness:` set to match, or the derived defaults will be wrong.
