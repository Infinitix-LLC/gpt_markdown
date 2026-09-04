## Unreleased

### Added

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

### `gpt_chat` — Responses API (breaking)

The gateway retired `/chat/completions`; it now answers 404 with *"This API
serves POST /v1/responses"*. The client speaks the Responses API instead.

* `PlusfinityConfig.responsesUri` replaces `completionsUri`, which is
  deprecated and now points at the same endpoint.
* Request fields follow Responses: `input` rather than `messages`,
  `max_output_tokens` rather than `max_tokens`, and `reasoning: {effort}`
  rather than a flat `reasoning_effort`. `x_plusfinity` is unchanged.
* `CompletionChunk` reads typed stream events — `response.output_text.delta`
  for text, `response.completed` / `.failed` / `.incomplete` for the end — and
  an `output` array of `output_text` parts when not streaming. There are no
  `choices`.

### `gpt_chat` — adapter + slot rework (breaking)

The chat layer is now a UI shell any app can drive, with the Plusfinity Gateway
as one plug-in rather than the foundation. See `doc/chat_adapter_plan.md`.

* **New entry points.** `package:gpt_markdown/gpt_chat.dart` is the UI and adapter
  layer and pulls in no HTTP dependency; the gateway client moved to
  `package:gpt_markdown/gpt_chat_gateway.dart`. The old
  `package:gpt_markdown/gpt_chat/gpt_chat.dart` still works and re-exports both.
* **`ChatAdapter`** is the seam between the UI and whatever produces the
  conversation. Apps that already own their chat state implement it directly and
  keep that state; apps with no state layer extend `StreamingChatAdapter`, which
  handles sessions, titling, cancellation, retry and persistence on top of one
  `streamReply` method. `ChatViewModel`, `ChatRepository`, `SessionRepository`
  and `ModelRepository` are gone.
* **`ChatMessage` is now an interface**, so a host can satisfy it on its own
  message type — mutable, a `ChangeNotifier`, backed by a DTO — without
  converting. `SimpleChatMessage` is the package's own implementation. When a
  message is also a `Listenable`, the transcript rebuilds that one bubble as it
  streams instead of the whole list.
* **Slot-based builders.** Every builder now takes a single `ChatSlot` carrying
  the controller, the resolved theme, the default widget, *and* the parts that
  composed it. Replace the transcript and you still get the bubbles
  (`slot.item(i)`); replace an answer and you still get its text, sections and
  actions. Names are flat and prefixed (`answerText`, `composerSend`).
* **`ChatTheme`** covers colours, radii, spacing, widths and typography, so a
  rebrand needs no builders.
* **`ChatCapabilities`** replaces the `showSessions` / `showModelSelector` flags:
  the chrome follows the adapter.
* **Defaults redrawn** to the familiar assistant-app shape — centred reading
  column, user bubble right / assistant full width, model picker in the app bar,
  floating rounded composer, date-grouped conversation drawer.
* `GptChat(config:)` is now `GatewayChat(config:)`; `GptChat` takes an adapter.
* Composer drafts carry attachments and a host-defined tool via `ChatDraft`.
* Send and stop are separate widgets (`ChatSendButton`, `ChatStopButton`) behind
  `composerSend` / `composerStop`; stop takes send's place while a reply streams.
* The drawer groups by recency, searches past eight conversations, and offers
  rename when the adapter allows it. The conversation list, suggestion chips,
  the attachment strip and the load-more footer are each gated on the matching
  `ChatCapabilities` flag.
* Answer actions are copy + regenerate, pinned on touch and hover-revealed on
  pointer platforms per `ChatTheme.answerActionsAlwaysVisible`.
* **A host's own message type now flows through `StreamingChatAdapter`.**
  `newMessage` returns `ChatMessage` rather than the package's own type, and one
  new hook — `updateMessage` — is all a custom model needs. Forgetting it fails
  loudly at send time (debug assert) instead of asynchronously inside the stream.
* **`ChatDelta` carries a `payload`**, plus a `ChatDelta.data` constructor, so a
  chunk's non-prose parts (sources, tool status, media, reasoning) can be routed
  into fields the package knows nothing about via the `applyDelta` hook.
* `ChatTheme.scrollPhysics` and `ChatTheme.transcriptPadding` — the last two
  reasons a host had to override `messageList` just to change a metric.
* `listHeader` / `listFooter` are constrained to the reading column, like every
  exchange, so they no longer have to re-wrap themselves.
* `ChatController(followLatest: false)` hands scrolling entirely to the host, for
  apps whose own view model already drives the transcript. Without it two things
  share one `ScrollController`.
* The transcript's anchor height is now measured *after* `transcriptPadding`, so
  the last exchange is not taller than the space it actually gets.
* The awaiting-first-token state no longer short-circuits the `answer` builder: a
  host's header, status line and progress now render from the moment a question
  is sent, not from the first token.

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
