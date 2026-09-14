## Unreleased

### Added

* Modern `blockComponents` registration: pure-Dart block syntax, immutable
  payloads, prefix dispatch, and independent Flutter renderers. Includes
  `FencedBlockSyntax` for custom containers. Legacy component APIs retain
  precedence and remain supported.
* `SliverGptMarkdown` for viewport-lazy rendering of long documents.
* `PlusparseRenderer.renderDocument` for rendering retained ASTs.
* Optional fixed table widths and deferred code highlighting via
  `TableStyle.columnWidth` and `CodeBlockStyle.highlightWhileStreaming`.

### Compatibility

* Existing widget and legacy-component integrations keep their APIs. Direct AST
  consumers with exhaustive `MdNode` switches must handle `MdCustomBlock`.

### Performance and fixes

* The code block's copy button is a real button from the first build again. It
  had been drawn as a plain icon until a pointer reached it, which saved ~340 us
  per code block and broke three things: a keyboard user could never reach it
  (the cheap form was not in the tab order, and neither way of promoting it can
  be triggered by a key), the first stylus contact was swallowed and copied
  nothing, and press-and-hold meant copy before promotion and tooltip-with-no-copy
  after. On touch the first tap also had no ripple. It now also carries an
  accessible name and button role, which `InkWell` and `Tooltip` do not supply
  on their own.
* Fix the code block's copy button changing size and position when hovered.
  The cheap resting form and the interactive one both asked for 32 by 32, but
  `IconButton` folds `visualDensity` into the constraints and reserves its own
  tap target, so it resolved to a 24-pixel circle in a 40-pixel box: the button
  shrank by 8 pixels and slid 4 the moment a pointer reached it. Both forms are
  now drawn by the same code.
* Drop the alignment box around left-aligned table cells, which is the default
  and most columns. Content-sized columns lay every cell out twice, so the
  redundant box cost two layout passes per cell; a table drops from 397 render
  objects to 274 for 123 cells. The column's own alignment now wins over an
  ambient `textAlign`, which the box used to mask.
* Stop measuring a column once it has already reached the width it will be
  clamped to.
* Draw list markers in a single hanging-indent render object instead of a row
  of padded boxes, and skip the flex wrapper for blocks rendered directly as
  siblings. A bullet item drops from ~10 render objects to ~3 with every
  measured size unchanged, which roughly halves what a list costs to paint on
  every frame of a streaming reply.
* A reply that is still arriving now exposes itself to assistive technology as
  a single live block of text rather than re-publishing every block's
  accessibility node on every frame. The whole text received so far remains
  readable as that block's label, and the full structure — headings, links,
  list items as separate nodes — returns as soon as the text goes quiet. This
  roughly halves the per-chunk cost of a long streaming reply when an assistive
  service is attached. The behaviour keys on text actually arriving, never on
  `isStreaming`, which defaults to `true`.
* Build nested quote and heading content once, including during reveal.
* Retain hidden spans; cache segmentation, ASTs, character counts, and offsets
  outside animation ticks. Notify only the active reveal window.
* Re-split only the previous tail on append; preserve parsing across theme changes.
* Share parsed syntax but keep rendered instances separate for repeated blocks.
* Preserve table scroll controllers across updates and dispose them on unmount.
* Keep default table sizing compatible with layout-dependent custom cells;
  fixed column policies bypass that measurement work.
* Cache anchored regex dispatch in the legacy parser too.

## 1.3.0

### Added

* `BlockWidgetSpan`, marking a placeholder that holds a *block* rather than an
  inline construct. The two are not distinguishable by shape — an image and a
  block quote are both a lone bottom-aligned `WidgetSpan` — so telling them
  apart by looking silently swallowed every image in the document.
* `GptMarkdownConfig.blocksRenderDirectly` and `GptMarkdownConfig.getRich`'s
  `ambientScaling`, which together let a block that has been lifted out of its
  paragraph scale from the ambient `MediaQuery`. Handing it `textScaler`
  instead applies the scale twice — once to the glyphs, once to the width it
  wraps into — which measured 4x the correct height on a bullet list.
* `inlineLinkBuilder` and `inlineSourceTagBuilder` — span-returning
  replacements for `linkBuilder` and `sourceTagBuilder`. A span link sits on
  the text baseline, wraps across lines, is selectable, and reveals character
  by character while streaming; the `WidgetSpan` the old builders force can do
  none of those. Both receive a details object (`LinkBuildDetails`,
  `SourceTagBuildDetails`) rather than positional arguments, so a later release
  can hand them more information without breaking any builder. Call
  `details.defaultSpan()` to keep the stock rendering and change one thing, or
  `details.asWidgetSpan(widget)` when a widget is genuinely required.
* `TappableTextSpan` and `LinkTextSpan` — text spans that answer a tap without
  carrying a `GestureRecognizer`, plus `collectInlineTapRuns` and the
  `InlineTapTargets` render mixin that resolve those taps by text range. A
  recognizer only fires on a span that carries its own `text`, so a recognizer
  on a wrapper span — which is what a parsed link label is — never fires. These
  make a wrapper as tappable as a leaf, and make a placeholder inside a label
  tappable too.
* Fenced code blocks now highlight recognized language tags with comprehensive
  built-in light and dark palettes. Common aliases such as `js`, `ts`, `py`,
  `python3`, `c++`, `sh`, and `yml` are supported; unknown or omitted languages
  continue to render as plain code.
* The default fenced-code panel now uses one seamless rounded surface with a
  compact language pill and icon-only copy action—there is no divider competing
  with chat-bubble layouts. The copy icon briefly changes to a check mark, and
  existing copy labels remain accessible, localisable tooltips.
  The action ignores taps while copying and for the full check-mark state—while
  retaining its normal colour—so rapid taps cannot queue duplicate clipboard
  writes or callbacks.
  Unlabelled fences display `Code` in the language pill instead of leaving it
  visually empty.
* **A new parser.** `GptMarkdown(text, incremental: true)` renders through
  plusparse — a single-pass character scanner producing a real AST — instead of
  the recursive combined-regex pipeline. Same widgets, same theming, same
  builder hooks; the two are kept in step by a parity test suite. Measured
  against the regex pipeline on the same input: **20x** on a line of dense
  inline syntax, **32x** on a typical reply, **54x** on a 35 KB document, and
  **69x** re-parsing a reply as it streams.
* **Segment caching for streaming.** In `incremental` mode a document is split
  at blank lines and each segment is cached, so appending to a reply rebuilds
  only the tail. Rebuild cost stops growing with the answer: **4.6x** less work
  over 30 appends, and flat rather than rising.
* **Character-level reveal animations.** `animation:` takes
  `GptMarkdownAnimation.typewriter`, `.fade`, `.blurIn` and `.wave` beside
  `.none`. Each character is stamped when it arrives and styled by how far
  through its entrance it is, so the head of the stream is a soft ramp.
* **Block entrance animations.** `blockAnimation:` takes
  `GptMarkdownBlockAnimation.fadeIn`, `.growIn`, `.slideUp`, `.scaleIn` and
  `.none`, for constructs with no half-state to reveal — tables, fenced code,
  block maths, rules. Separate from `animation:` so the two compose. Only
  `.growIn` changes the space a block occupies while it plays.
* `revealFadeSeconds:`, `blockAnimationDuration:` and `blockAnimationCurve:` to
  tune both axes.
* `InlineDirective` — a delimited region the parser does not look inside, for
  host content that is not Markdown. Unlike `InlinePattern`, which matches over
  the text a parse produced, a directive is lifted out before parsing, so a
  payload containing `**`, backticks, `~~` or `[…](…)` arrives verbatim.

### Changed

* **Block constructs render as sibling widgets rather than as placeholders
  inside a paragraph.** A heading, list item, table, fence, quote or block
  equation used to be a `WidgetSpan` holding a second `Text.rich`; the
  paragraph had to lay each one out as its own `RenderBox` before it could
  shape a line, and the nested paragraph was a second full text-shaping pass.
  Measured against the same document forced down the old path: headings 1.92x,
  and a mixed answer 1.65x faster than the previous release.

  Two consequences to know about. Documents with `maxLines` set keep the old
  single-paragraph rendering, because N paragraphs cannot share one line
  budget. And a list is about 0.5 px per item shorter, because stacking items
  no longer pays the line-break leading between them — always tighter, never
  taller.
* **The default link rendering is now a span, not a widget.** A link used to
  be a `LinkButton` inside a `WidgetSpan`; it is a `LinkTextSpan` now. Visible
  consequences, all of them the point: a long link label **wraps mid-label**
  instead of jumping whole to the next line, the label is **selectable and
  copied** with the sentence around it, it **reveals character by character**
  while streaming instead of appearing whole, and it sits on the text baseline.
  Hover is resolved once per paragraph rather than by a `StatefulWidget` per
  link. Measured at cold first paint: ~170 µs per link before, below the
  measurement noise floor after.
* Deprecated `LinkButton` and `LinkSpanBuilder`. Nothing in the package builds
  them any more. They still work and will be removed in 2.0.0.
* The link url is now reachable from the rendered tree. `LinkButton.url` was
  never populated, so the url existed only inside the tap closure; a
  `LinkTextSpan` carries it as a field, and the test serialiser emits it in the
  `LINK("label", url="…")` form `test/README.md` always documented.
* A second finger going down while a link is held can no longer redirect the
  first finger's tap. The paragraph allocates a recognizer per gesture instead
  of recycling one, for the same reason as above.
* The whole line box of a link answers a tap, not just the tight glyph boxes.
  The leading and trailing band of a line showed a pointing-hand cursor and did
  nothing.
* Hover state is dropped when the document's tap targets change, so a link can
  no longer stay painted hovered — with the paragraph stuck on a click cursor —
  after the text under the pointer has been replaced.
* A paragraph gaining its first link no longer rebuilds its whole subtree.
* A decoration-only span nested inside a link no longer swallows the link over
  its own text. Tap resolution takes the innermost target, and a nested span
  with no callback was still a target — so a link had a dead hole in the middle
  of it, with the cursor still showing a pointing hand.
* Hover is identified by a target's full range rather than its start offset, so
  two nested targets that begin at the same place no longer restyle each other.
* Hit-testing a link costs one engine call plus the targets that can actually
  contain the pointer, rather than measuring every target in the paragraph on
  every mouse move.
* `[](url)` no longer trips the debug assert that guards `inlineLinkBuilder`.
  An empty label has nothing to tap, which is correct rather than a mistake,
  and the package's own recommended `defaultSpan()` was tripping it.
* A rebuild landing mid-gesture can no longer redirect a tap to a different
  link. Tappable leaves get a fresh gesture recognizer per build rather than a
  recycled one, because a gesture in flight holds a reference to that object —
  recycling it meant a press that began on one link could open another link's
  url on release.
* The copy button on a fenced code block is no longer pointer-disabled during
  the check-mark window. `IgnorePointer` did not stop a second tap reaching an
  ancestor — an ancestor is already on the hit-test path — it only stopped the
  button claiming the gesture, so the tap fell through to whatever wrapped the
  code block. The duplicate-clipboard guard was always in `_copyCode`.
* Deprecated `linkBuilder`. Use `styleSheet`'s `LinkStyle` for appearance, or
  `inlineLinkBuilder` for full control. It still works and will be removed in
  2.0.0.
* Deprecated `sourceTagBuilder`, replaced by `inlineSourceTagBuilder`. The new
  builder is handed the *resolved* `TextStyle`; the old one keeps the empty
  `TextStyle` it has always been given, because existing builders were written
  against that.
* A recognizer on a span is now carried onto every piece the streaming reveal
  emits, so a tappable span stays tappable while it streams instead of only
  once the segment settles.
* Reveal timing for links changed as a consequence. The reveal counts a
  placeholder as one character, so a link used to arrive whole; its label is
  text now and reveals character by character like the prose around it.
* The default **citation chip** rendering is unchanged.
* **`incremental` now defaults to `true`**, so the single-pass parser is the
  default renderer. It lays out correctly where the regex pipeline does not —
  no spurious line after a fenced block — and is 20x to 69x faster. Pass
  `incremental: false` for the old pipeline. Custom
  `components`/`inlineComponents` still select it automatically.

* The reveal styles spans that are already built rather than re-slicing the
  source each frame, so a document is rendered once per text change and a frame
  restyles only the characters still arriving. Custom
  `components`/`inlineComponents` keep the older path.
* Content past the reveal head is no longer built, so nothing appears below the
  reading position before it is meant to be seen.
* `RevealEngine.tick` returns true until the last character has finished its
  entrance, not merely until the reveal has caught up.

### Fixed

* `***both***` renders as bold *and* italic, and `*italic **bold** italic*`
  keeps its bold. Emphasis is now decided by the length of the run of
  asterisks: reading `***` as `**` from the second asterisk left a stray `*`
  inside the bold, and closing a single `*` with the next asterisk found landed
  on the opening half of a nested `**`, dropping the bold and cutting the
  italic into three.
* `InlinePattern` beats the built-in reading of the same text on the
  incremental pipeline, as it always has on the regex one — a pattern for
  `**bold**` renders the pattern, not emphasis. Matches are lifted out before
  parsing and put back at render, because once there is a tree there is no
  text left for a pattern to claim. Scope filtering is preserved, and a pattern
  no longer reaches inside fenced code or block maths.

* Changing `animation:` no longer changes how the document is parsed. Every
  animating effect forces the incremental pipeline, so with the default
  `incremental: false` only `GptMarkdownAnimation.none` still went through the
  regex pipeline — which wraps text differently and leaves an extra line after
  a fenced block. Set `incremental: true` and every effect, `none` included,
  lays out identically; the example's streaming demo now pins it.

* An animated reveal no longer leaves the document split one span per
  character. `settledBelow` trailed the head by a fixed window forever, so even
  a finished reply kept its last 64 characters as individual spans. Flutter
  shapes each style run separately, so that changed how text kerned and wrapped
  against `GptMarkdownAnimation.none`, and broke a construct styling a
  continuous stretch — an inline code chip — into pieces. Characters needing no
  style of their own now coalesce, and a reveal that has caught up collapses
  back to exactly the spans it started from.

* Streamed text no longer restyles after the reader has seen it. A construct is
  literal text until its closing delimiter arrives, so `` `npm install` ``
  appeared as prose and turned into a monospace chip a moment later, reflowing
  the line around it — the same for `**bold**`, `*italic*`, `~~strike~~`,
  `<u>…</u>`, `\( … \)` and `[label](href)`. The reveal now waits behind an
  unterminated construct, so a character is in its final form when it appears.
  A delimiter that never closes — a lone backtick, a footnote asterisk — is
  taken for prose after a short run rather than stalling the reveal.

* `|` inside inline maths, a code span, or escaped as `\|` no longer ends a
  table cell — `| Modulus (\(|z|\)) |` was three columns.
* GFM task lists (`- [x] done`) render as checkboxes, as do `- ( ) choice`
  radios and ordered items. The marker used to survive as literal text, and the
  checkbox sat a blank line below its own bullet.
* Block maths in a list item renders as maths. `1. \[` with the body on the
  lines below left `\[` literal and leaked the body out of the list.
* `\[ ... \]` is recognised mid-sentence too, still rendering as a block. Text
  on either side is preserved.
* The reveal reaches inside headings, lists, task lists, checkboxes, radios and
  block quotes. Those render as widgets, and a widget was one opaque character
  to the reveal, so they arrived whole however `animation:` was set.
* `incremental` no longer forces content to the full width offered — a two-word
  answer claimed the whole column. Constructs that genuinely fill the width
  still do.
* Streaming no longer shifts settled content down by a block gap when the
  reveal advances past it, or again when the reply completes.
* `settledSplitOffset` no longer moves backward as text arrives.
* The inline-code chip paints while its paragraph is still animating. The chip
  is drawn for spans tagged `CodeTextSpan`, and the reveal rebuilt every span
  as a plain `TextSpan` — so the code text sat bare, in the right monospace,
  until the whole segment settled (1.8 s after the text on the demo reply),
  then the chrome popped in at once and popped back out on the next chunk.
  Settled spans now pass through the reveal as their original objects, and a
  partially revealed code span keeps its tag via `CodeTextSpan.revealing`.
* Fading text no longer jitters the words around it. Each mid-fade character
  was its own span, and Flutter shapes each span as its own run — kerning and
  ligatures broke at boundaries that moved every frame, so on a proportional
  font wrap points flickered near the head. The fading effects now style whole
  words (`wave` still travels letter by letter, its point), so a style
  boundary only ever falls on whitespace.
* The reveal never moves backwards. A construct opening late — `[the docs]`
  closing as prose and then `(` arriving — pulled the visible tail back behind
  the opener: text the reader had read vanished for the length of the hold,
  and on its return the engine re-stamped it and replayed its fade, blinking
  characters half a window behind the head. The hold now only advances, and
  the engine holds its head and marks everything beneath it settled when the
  target shrinks.
* Scrolling back to a streamed reply no longer replays it. Reveal progress and
  the blocks' one-shot entrances lived in element state, so a lazy list
  disposing an item and re-inflating it on scroll-back re-typed the whole
  message from nothing (with `isStreaming` still true) and re-ran every
  table's and fence's entrance from opacity zero. Content already present at
  mount now appears whole and plays no entrance; only text arriving after
  mount animates.
* A finished block entrance keeps its (paint-free) wrapper instead of swapping
  to the bare child, which changed the widget type and re-inflated the block's
  subtree once, mid-stream.
* Two identical blocks — two rules, two identical fences — no longer collide
  on one entrance key. The cached widget carried its position key inside the
  content-keyed cache, a duplicate-keys crash in debug builds.
* A fence glued to a paragraph with no blank line streams its body. The inline
  hold read the fence's own backticks as inline delimiters and withheld the
  entire code block until it closed.
* With `useDollarSignsForLatex`, an equation closing no longer blanks and
  re-types the message. The `$…$` → `\(…\)` rewrite edits the text
  retroactively, which failed the append-only check and reset the reveal; an
  edit confined to the tail now carries on from where it was. An unpaired `$`
  is also held rather than shown as prose it will not stay.
* A chunk ending in the first half of an opener — `\` before `\(`, `<` before
  `<u>` — is held until the next character decides it, instead of being shown
  and then vanishing.

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
