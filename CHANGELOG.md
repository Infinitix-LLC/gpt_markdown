## Unreleased

### Added

* Per-character streaming reveal. `animation:` now takes
  `GptMarkdownAnimation.typewriter`, `.fade`, `.blurIn` and `.wave` alongside
  `.none`. Each character is stamped with the time it arrived and styled by how
  far through its entrance it is, so the head of the stream is a soft ramp
  rather than a hard cut with a gradient over the bottom of the box.
* `blockAnimation:` — `GptMarkdownBlockAnimation.fadeIn`, `.growIn`, `.slideUp`,
  `.scaleIn`, `.none`. How a table, fence, rule or block-maths enters once it is
  complete. Separate from `animation:` on purpose: how a letter appears and how
  a table appears are different questions, and one combined preset would need a
  new value for every pairing. Only `.growIn` changes the space a block takes
  while it plays; the rest animate paint alone, so content below them holds
  still.
* `revealFadeSeconds:`, `blockAnimationDuration:` and `blockAnimationCurve:` for
  tuning both axes.
* `RevealEngine.progressFor`, `.tailStillFading` and a `fadeSeconds` constructor
  argument. Stamps live in a fixed ring, so memory does not grow with the reply
  and a fast-forward that lands thousands of characters in one frame stamps only
  the ones that can still be animating.
* `applyReveal` / `countRevealCharacters` — the reveal applied to spans that are
  already built, and `GptMarkdownBlockEntrance`.

### Changed

* The reveal is applied to spans instead of by re-slicing the Markdown source.
  The document is now rendered once per *text* change rather than once per
  frame, and a frame restyles at most 64 characters in the one segment holding
  the head. This also removes the settled/tail seam entirely on the plusparse
  path. Custom `components`/`inlineComponents` still take the older
  source-slicing path, which has no spans to restyle.
* Content beyond the reveal head is no longer built, so nothing appears below
  the reading position before it is meant to be seen.
* The character reveal now reaches inside block constructs. Headings, ordered
  and unordered lists, task lists, checkboxes, radios and block quotes are
  rendered as widgets — text with a marker, an indent or a rule around it — and
  a widget is one opaque character to a span-level reveal, so they used to
  arrive whole however `animation:` was set. `RevealableSpan` publishes the text
  inside the widget and rebuilds it around revealed spans, so those constructs
  reveal character by character like a paragraph does. Tables, fenced code,
  block maths and rules stay atomic — they have no meaningful half-state — and
  are what `blockAnimation:` is for.
* `RevealEngine.tick` now keeps returning true until the last character has
  finished its entrance, not merely until the reveal has caught up. Stopping at
  the former froze the final characters part-way through.
* Inline parsing is roughly 2–3x faster on documents and streaming: runs of text
  that cannot begin a construct are found with a lookup table and copied in one
  piece, a run with no markup at all skips the buffer and the delimiter tables
  entirely, the bracket and parenthesis tables are built in one pass instead of
  two, and CRLF normalization is skipped when the source has no `\r`.

### Fixed

* A `|` inside inline maths, a code span, or escaped as `\|` no longer ends a
  table cell. `| Modulus (\(|z|\)) |` was three columns.
* The incremental path no longer forces its content to the full width it is
  offered. The segment column stretched its children, so a two-word answer laid
  claim to the whole column while the single-text pipeline sized to its content.
  Both now size the same, and constructs that genuinely fill the width — a
  heading, a quote, a fence, a rule — still do.
* Block maths in a list item renders as maths. `1. \[` with the body on the
  lines below left the `\[` as literal text and leaked the body out of the list
  as a paragraph trailing a stray `\]` — an equation's body is opaque, like a
  fence, so it is now claimed regardless of indentation.
* `\[ ... \]` is recognised in an inline position too, and still renders as a
  block. The block parser only ever claimed it when it opened a line, so block
  maths written mid-sentence — `1. Result: \[ x^2 \]`, or anywhere inside a
  paragraph — stayed literal text. Text on either side of it is preserved.
* GFM task lists — `- [x] done` — render as checkboxes on the plusparse path.
  A checkbox is a block-level node and a list item's content is parsed inline,
  so the marker used to survive as the literal text `[x] done`. Applies to
  `- ( ) choice` radios and to ordered items too. The bare `[x] done` form was
  never affected. A list item's nested blocks were also always preceded
  by a line break, which put a task list's checkbox on the line below its own
  bullet — one blank line per item. The break is now emitted only when there is
  inline content to separate it from, so list layout matches the regex pipeline
  exactly.
* The streaming reveal no longer shifted content down by one block gap when the
  settled/tail seam advanced past it, and again when the reply completed.
* `settledSplitOffset` no longer moves backward as text arrives. A source ending
  in a newline counted its empty last line as a blank line, so the split ran one
  construct ahead and fell back on the next character.

## 1.2.1

### Changed

* Radio list markers use `RadioGroup` instead of `Radio.groupValue` and
  `Radio.onChanged`, which Flutter deprecated in 3.32. No visual or behavioural
  change — the marker looks and responds exactly as before.
* Minimum Flutter is now **3.32.0**, the release `RadioGroup` was added in.

### Added

* `InlinePattern.delimited` for tokens that open and close, such as `:emoji:`,
  `::spoiler::` or `{{token}}` — the counterpart to `InlinePattern.prefixed`,
  which cannot express a closing delimiter. The token name is the named group
  `name`. See [docs/inline-syntax.md](docs/inline-syntax.md).

## 1.2.0

Upgrading from 1.1.x? See [MIGRATION.md](MIGRATION.md).

### Changed

* Deprecated `highlightBuilder`. Use `inlineCodeStyle` for appearance, or
  `inlineCodeBuilder` for full control. It still works, is now aligned on the
  text baseline, and will be removed in 2.0.0.
* Inline code renders as a monospace chip that wraps across lines. Restyle with
  `inlineCodeStyle`.
* Autolinking is on by default. Disable with `autolink: false`, and remove any
  pre-processor that rewrites bare URLs.
* `ImageMd`, `TableMd` and `ATagMd` no longer render inside link labels. Custom
  components opt out with `scopes`.
* Malformed links and unclaimed matches render as plain text instead of being
  dropped silently.
* Component dispatch is anchored as `^(?:pattern)$`, so a pattern containing a
  top-level `|` no longer claims matches it does not cover.
* Case-insensitive component patterns now match.
* Tests using `find.byType(RichText)` need
  `find.byWidgetPredicate((w) => w is RichText)` — some paragraphs render as a
  `RichText` subclass.

### Added

* Streaming reveal for generated replies, off by default:
  `GptMarkdown(text, animation: GptMarkdownAnimation.fade, isStreaming: true)`.
  Only the part of the reply that can still change is rebuilt, so the cost per
  token stays flat as the reply grows. The reveal keeps up with a fast model,
  fast-forwards when `isStreaming` turns false, and honours reduced motion.
  See [docs/streaming.md](docs/streaming.md).
* `GptMarkdownStyleSheet` with twelve per-component style classes, settable per
  widget or app-wide on `GptMarkdownThemeData`. Unset fields keep the previous
  defaults.
* Builders for every component: `blockQuoteBuilder`, `headingBuilder`,
  `checkboxBuilder`, `radioOptionBuilder`, `hrBuilder`.
* Callbacks `onCheckboxChanged`, `onCodeCopy`, `onImageTap`, `onSourceTagTap`.
* `InlinePattern` for app-specific inline syntax such as `@mention`,
  `#channel` and `:emoji:`, with `InlinePattern.prefixed` for the common case.
* `MarkdownScope` and `MarkdownComponent.scopes` — components declare which
  nesting contexts they render in.
* Autolinks following the GFM autolink extension and CommonMark §6.5, with
  `autolinkSchemes` for app schemes.
* `GptMarkdownConfig` and the builder typedefs are exported from the main
  import.

### Fixed

* Text scaling: components rendered through a `WidgetSpan` reserved up to 39x
  the space they needed at a 2x system font setting. Every component now scales
  proportionally.
* Theme changes did not repaint — colours are resolved when spans are built,
  and the cache was not invalidated.
* `GptMarkdownConfig.isSame` ignored several fields, so runtime changes to
  components, inline patterns and styles did nothing.
* Inline widgets in right-to-left paragraphs render in visual order
  ([flutter#54400](https://github.com/flutter/flutter/issues/54400)).
* `GptMarkdownConfig.getRich` returns `Widget` instead of `Text`.

## 1.1.8

* 🔗 Fixed consecutive links separated by single newlines not rendering ([#142](https://github.com/Infinitix-LLC/gpt_markdown/issues/142)).

## 1.1.7

* Added/updated the interactive playground and pub.dev example flow, with `playground.dart` as a dedicated playground entry and improved demo content for links, lists, blockquotes, tables, and LaTeX.
* Updated package metadata: bumped to `1.1.7`, set `homepage` to [gptmarkdown.com](https://gptmarkdown.com), and added `repository` + `issue_tracker`.
* Bumped `flutter_math_fork` to `^0.7.4` for Flutter 3.35+ compatibility.
* Fixed bold markdown rendering across newlines by enabling `dotAll` in `BoldMd`.
* Fixed link styling so underline/color (including hover color) apply consistently across nested inline spans (bold/italic) inside links via `LinkSpanBuilder`.
* Extended `imageBuilder` to receive parsed size metadata from markdown image syntax (`context, imageUrl, width, height`).
* Resolved deprecated radio API usage by wrapping `Radio<bool>` with `RadioGroup` in custom radio rendering.
* Cleaned up and corrected docs/example markdown content for the updated API and examples.

## 1.1.6

* Added `hrLinePadding` to `GptMarkdownThemeData` (default `EdgeInsets.zero`), wired through the public factory, `copyWith`, and `lerp`, for padding around horizontal rules and the optional line after `#` headings.
* Added `autoAddDividerLineAfterH1` to `GptMarkdownThemeData` (default `true`), with the same factory / `copyWith` / `lerp` support, so the extra divider after a level-1 heading can be toggled from theme data.
* Added `padding` to `CustomDivider` (default `EdgeInsets.zero`); the render object lays out and paints the stroke inside those insets and uses the constrained width when drawing.
* Added `GptMarkdownThemeData.isSame` to compare every field on the theme data type.
* `HTag` and `HrLine` use `hrLineColor`, `hrLinePadding`, and `autoAddDividerLineAfterH1` from `GptMarkdownTheme.of(context)` for the horizontal line widgets.

## 1.1.5

* Fixed block latex markdown syntax.

## 1.1.4

* 🔗 Fixed vertical alignment issue with link text rendering ([#92](https://github.com/Infinitix-LLC/gpt_markdown/issues/92))
* 📝 Resolved "null" rendering issue in ordered lists with multiple spaces and line breaks ([#89](https://github.com/Infinitix-LLC/gpt_markdown/issues/89))
* 🧹 Removed erroneous `trim()` from `CodeBlockMd` to preserve necessary whitespace in code blocks ([#99](https://github.com/Infinitix-LLC/gpt_markdown/issues/99))
* 🎨 Fixed heading style customization issue where custom colors in heading styles were not being applied ([#95](https://github.com/Infinitix-LLC/gpt_markdown/issues/95))

## 1.1.3

* Added `RadioGroup` widget for managing radio buttons.
* Updated to align with Flutter 3.35 by resolving the deprecations of `Radio.groupValue` and `Radio.onChanged`.

## 1.1.2

* 📊 Fixed table column alignment support ([#65](https://github.com/Infinitix-LLC/gpt_markdown/issues/65))
* 🎨 Added `tableBuilder` parameter to customize table rendering
* 🔗 Fixed text decoration color of link markdown component

## 1.1.1

* 🖼️ Fixed issue where images wrapped in links (e.g. `[![](img)](url)`) were not rendering properly (#72)
* 🔗 Resolved parsing errors for consecutive inline links without spacing (e.g. `[a](url)[b](url)`) (#34)

## 1.1.0

* Changed `onLinkTab` to `onLinkTap` fixed issues of newLine issues.

## 1.0.20

* Fix: support balanced parentheses in image and link URLs. [#68](https://github.com/Infinitix-LLC/gpt_markdown/pull/68)

## 1.0.19

* Performance improvements.

## 1.0.18

* dollarSignForLatex is added and by default it is false.

## 1.0.17

* Bloc components rendering inside table.

## 1.0.16

* `IndentMd` and `BlockQuote` fixed.
* Baseline of bloc type component is fixed.
* block quote support improved.
* custom components support added.
* `Table` syntax improved.

## 1.0.15

* Performance improvements.

## 1.0.14

* Added `orderedListBuilder` and `unOrderedListBuilder` parameters to customize list rendering.

## 1.0.13

* Fixed issue [#49](https://github.com/Infinitix-LLC/gpt_markdown/issues/49).

## 1.0.12

* imageBuilder parameter added.

## 1.0.11

* dart format.

## 1.0.10

* pubspec flutter version updated.

## 1.0.9

* Fixed issues with flutter 3.29.0.
* Fixed > syntax render issue.

## 1.0.8

* Extra lines inside block latex removed and $$..$$ syntax works with \(..\) syntax.

## 1.0.7

* `closed` parameter added to `codeBuilder`.

## 1.0.6

* `_italic_` and `>Indentation` syntax added.
* `linkBuilder` and `highlightBuilder` added [f45132b](https://github.com/Infinitix-LLC/gpt_markdown/commit/f45132b2cd4b069d3e5703561deb5c7e51d3c560).

## 1.0.5

* Fixed the order of inline and block latex in markdown.

## 1.0.4

* Fixing latex issue for block syntax.

## 1.0.3

* Multiline latex syntax bug fix.

## 1.0.2

* Readme updated.

## 1.0.1

* Indentation fixed
* `ATag` syntax fixed
* Documentation improved in readme and example.

## 1.0.0

* `TexMarkdown` is renamed to `GptMarkdown`.
* `h1` to `h6` style added to `GptMarkdownThemeData` class. 
* `hrLineThickness` value added to `GptMarkdownThemeData` class. 
* `hrLineColor` Color added to `GptMarkdownThemeData` class. 
* `linkColor` Color added to `GptMarkdownThemeData` class. 
* `linkHoverColor` Color added to `GptMarkdownThemeData` class. 
* Indentation improved. 
* Math equations are now default selectable. 
* `SelectableAdapter` Widget added to make any widget selectable.

## 0.1.15

* `CodeBlock` is moved out of `gpt_markdown.dart` library.

## 0.1.14

* Changed `withOpacity` to `withAlpha` in `theme.dart` for highlightColor.

## 0.1.13

* `GptMarkdownTheme` and `GptMarkdownThemeData` class moved to `gpt_markdown.dart` library.

## 0.1.12

* Fixed the indentation syntex of regex.

## 0.1.11

* `GptMarkdownTheme` and `GptMarkdownThemeData` classes added.

## 0.1.10

* components are now selectable.

## 0.1.9

* source config added.

## 0.1.8

* unordered list bullet color fixed.

## 0.1.7

* ordered list color fixed.

## 0.1.6

* `overflow` perameter added.

## 0.1.5

* Some color changes and highlighted text style changed.

## 0.1.4

* `[source]` format added.

## 0.1.3

* `maxLines` Parameter added.

## 0.1.2

* `textStyle` Parameter added to the latexBuilder function.

## 0.1.1

* Fixed hitTest essue.

## 0.1.0

* Inline Latex Builder added and Link are now Clickable and Latex Error Color changed to null for debug mode.

* `textScaleFector` is removed and `textScaler` added

## 0.0.12

* codeBuilder method added [[#6](https://github.com/saminsohag/flutter_packages/issues/6)], and maked the table scrollable.

## 0.0.11

* New syntex added for codes and highlight.

## 0.0.10

* `$$_$$` syntex fixes.

## 0.0.9

* `$_$` syntex added for latex with a gard condition for `\(_\)`.

## 0.0.8

* `$_$` syntex added for latex with a gard condition for `\(_\)`.

## 0.0.6

* Fixed textScaler problem by removeing that and added textScaleFector.

## 0.0.5

* Latex table workarround added.

## 0.0.4

* Customizable latex and workarround added.

## 0.0.3

* Some latex related fixes.

## 0.0.2

* TextScaler and TextAlign added.

## 0.0.1

* This package will render response of chatGPT in flutter app.
