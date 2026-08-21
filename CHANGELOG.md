## Unreleased

* 📐 **Text scaling is now proportional for every component.** A paragraph lays inline children out in *scaled* space — it hands them `maxWidth / scale` and multiplies their reported size back — so a `WidgetSpan` child that also scales its own text was counted twice, and nesting compounded it. Measured at a 2x system font setting: a heading grew 17x, a list 10x, a checkbox 39x.
  Flutter's contract is that a `WidgetSpan` child does not scale itself; `MediaQuery.withNoTextScaling` exists for exactly this. Nested paragraphs built by `GptMarkdownConfig.getRich` now opt out, as do the list bullet and number, the checkbox and radio markers, and the code block. The root paragraph still scales normally, so text grows as the user asked.
  `GptMarkdownConfig.getRich` no longer forwards `textScaler` to nested paragraphs either: an explicit scaler on a `Text` beats the ambient `MediaQuery`, so passing it there defeated the opt-out and the `GptMarkdown.textScaler` parameter still double-counted — 978 points where the platform route gave 378. Both routes now agree exactly.
  Consumer widgets get the same treatment: a `WidgetSpan` returned from an `InlinePattern` builder, and anything passed to `baselineWidgetSpan`, are wrapped too — a chip was growing 3.8x at a 2x setting while the text beside it grew 2x.
  Measured after, at a width where nothing rewraps: paragraphs, inline code, headings, links, bullet and ordered lists, checkboxes, radio buttons, blockquotes, tables, code blocks and rules are all **exactly 2.0x at 2x and 3.0x at 3x**.

* 🔗 **Bare URLs, `www.` hosts and email addresses are now links.** `AutolinkMd` implements the GFM autolink extension — including the two rules everyone gets wrong: trailing punctuation is excluded (`see https://x.com.` leaves the period out), and a trailing `)` is part of the link only when the parentheses balance. `<https://x.com>`, `<mailto:a@b.com>` and `<a@b.com>` follow CommonMark §6.5. On by default; set `autolink: false` to render URLs as plain text.
  Doing this as a component rather than a pre-processor removes a whole class of bug: `**https://x.com**` used to become `[https://x.com](https://x.com**)` in downstream normalizers, because they cannot tell where the Markdown ends and the URL starts. `BoldMd` matches first, strips the `**`, and the autolink only ever sees a clean URL. Inline code, headings and table cells behave the same way.
* 🔐 **`autolinkSchemes`** opts extra schemes into *bare* linking — `http`, `https`, `mailto` and `xmpp` are linked without it, and a bare `myapp://thing` is not, since it is usually not meant as a link. `<...>` autolinks accept any scheme, as CommonMark specifies.
* 🐛 **Component dispatch mis-anchored alternations.** `generate` re-tested each component with `'^\$pattern\$'`, which binds `^` to the first alternative and `\$` to the last, so a component whose pattern contained a top-level `|` claimed matches it did not cover — and, being earlier in the list, stole them from the component that did. Now anchored as `'^(?:\$pattern)\$'`. `HrLine` and any consumer component with alternation were affected.
* 🐛 **Theme changes did not repaint.** Colours are resolved while the spans are built, not while they are painted — link colours from `GptMarkdownTheme`, inline code and headings from the ambient `ColorScheme`. `MdWidget` caches those spans and only regenerated them when the text or the config changed, so a light/dark switch, a new `GptMarkdownTheme`, or a text-direction change left the previous theme's colours on screen. It regenerates on `didChangeDependencies` now, and builds with its own element's context so the inherited dependency is registered where it can be notified.
* 🐛 **`GptMarkdownConfig.isSame` ignored several fields**, so `MdWidget` kept its cached spans and a runtime change to them rendered nothing new — silently, since the widget did rebuild. `inlineCodeStyle`, `autolink`, `autolinkSchemes`, `inlinePatterns`, `components` and `inlineComponents` are now compared. Swapping a component list at runtime previously had no effect at all. The remaining omissions are the builder closures, which any consumer writing them inline recreates on every build; comparing those would defeat the cache, so a change to one still needs a key or a remount — now stated in the code rather than left as a bare commented-out line.
* Link rendering moved into a shared `buildLinkSpan`, used by `ATagMd` and `AutolinkMd`, so both honour `linkBuilder`, `onLinkTap` and the theme's link colours identically.

* 💅 **Inline `code` is drawn as a rounded chip, and it wraps.** Flutter gives a span one decoration slot — `TextStyle.background`, a single `Paint` — which is a fill *or* a stroke, with no radius and no padding. The usual answer is a `WidgetSpan` holding a `Container`, which cannot wrap, breaks selection, sits off the baseline and does not paint on iOS inside a link label. Instead inline code stays a plain `TextSpan` and the chip is painted underneath the paragraph, once per line fragment — the same thing CSS calls `box-decoration-break: clone`. Long inline code now wraps and gets one chip per line. The default is monospace (the bundled JetBrains Mono, matching fenced blocks), a tinted fill, an outline and a 4px radius, with no horizontal padding so the surrounding words keep their normal spacing, all derived from the ambient `ColorScheme` and stepped up on dark schemes, where a light tint over a dark ground separates less than the reverse. **This changes how inline code looks in every app.**
* 🎛️ **`InlineCodeStyle`** configures it: `fontFamily`, `fontFamilyPackage`, `fontFamilyFallback`, `fontSizeFactor`, `fontWeight`, `color`, `backgroundColor`, `borderColor`, `borderWidth`, `borderRadius`, `padding`, `boxHeightStyle`. Every field is optional and falls back to a scheme-derived default, so one field is a complete override. Pass it per widget as `GptMarkdown.inlineCodeStyle`, or app-wide as `GptMarkdownThemeData.inlineCode`. An app that set only `GptMarkdownThemeData.highlightColor` keeps that colour as the chip fill.
* 💥 **`highlightBuilder` is gone, replaced by `inlineCodeBuilder`.** The old hook returned a `Widget`, which the package wrapped in a `WidgetSpan` at a hardcoded `PlaceholderAlignment.middle` — off the baseline, unable to wrap, skipped by selection, and blank on iOS inside a link label. `inlineCodeBuilder` returns an `InlineSpan` and receives the resolved `TextStyle` *and* `InlineCodeStyle`, so a builder can keep the painted chip (`CodeTextSpan`), drop it (`TextSpan`), or opt into a widget with `baselineWidgetSpan`, which aligns on the text baseline rather than the line box. Migration is mechanical: `(context, text, style) => MyChip(...)` becomes `(context, code, style, codeStyle) => baselineWidgetSpan(MyChip(...))`.
* Inline code no longer needs a builder to look right, so `` [`code`](url) `` renders correctly.
* ⚠️ A paragraph containing inline code (or one needing right-to-left placeholder reordering) now renders through `BidiRichText`, a `RichText` **subclass**. `find.byType(RichText)` matches exact runtime types and will miss those paragraphs; use `find.byWidgetPredicate((w) => w is RichText)`.
* `BidiRichText` gained `bidiEnabled`, so the reordering probe layout is skipped for paragraphs that cannot need it.

* 🎯 **Nesting scopes for components.** `MarkdownComponent` gained `scopes`, a set of `MarkdownScope` values (`content`, `linkLabel`, `tableCell`, `heading`) describing where a component may render. It defaults to every scope, so existing components are unaffected. `ATagMd`, `ImageMd` and `TableMd` now opt out of `linkLabel`: a link label is rendered inside the link's own `WidgetSpan`, and a second `WidgetSpan` nested in it does not paint on iOS — `[![alt](img)](url)` and `[#chip](url)` rendered as blank space. Custom components opt out with `Set<MarkdownScope> get scopes => MarkdownComponent.allScopesExceptLinkLabel;`.
* ✨ **`GptMarkdown.inlinePatterns`.** Register app-specific inline syntaxes — `@mention`, `#channel`, `:emoji:` — without subclassing `InlineMd` or reordering `inlineComponents`. Each `InlinePattern` pairs a `RegExp` with a builder returning an `InlineSpan`, is matched ahead of the built-in components, and by default does not apply inside link labels. `InlinePattern.prefixed` builds the common prefixed-token regex, with an optional generic fallback so an app can choose to claim only names it knows — `#2959` stays an issue number rather than becoming a channel.
* 🐛 **Text is no longer silently deleted.** `MarkdownComponent.generate` matched with a combined regex and then dispatched with a separate anchored re-test; when the two disagreed the match was dropped and the text vanished with no warning. It now falls back to plain text (and `debugPrint`s in debug builds). `ATagMd` did the same for malformed links such as `[[a](http://x)` and `[label](http://x` — those now render their source text too.
* 🐛 **Case-insensitive component patterns now match.** The combined regex was always built case-sensitively, so a component declaring `RegExp(..., caseSensitive: false)` never received its matches. The combined regex is now case-insensitive when any component asks for it, and the anchored dispatch re-test preserves each component's flag.
* ⚡ **Combined regexes are cached.** `generate` recompiled the joined alternation on every call, and it recurses once per nested span. Compiled regexes are now memoised by pattern string (bounded at 64 entries, since components may be built from runtime data).
* `GptMarkdownConfig` gained `scope` and `inlinePatterns`. `gpt_markdown.dart` now re-exports `custom_widgets/markdown_config.dart`, so `GptMarkdownConfig` and the builder typedefs are available from the main import.
* 🔡 Fixed inline widgets (LaTeX, images, links) rendering in reverse order when a paragraph mixes right-to-left text with two or more of them — e.g. `واحد $two^2$ ثلاثة أربعة five ستة سبعة $eight^8$` used to swap the two formulas. This works around [flutter/flutter#54400](https://github.com/flutter/flutter/issues/54400), where the engine fills a line's inline-placeholder slots left to right in logical order regardless of the line's direction. Affected paragraphs now render through `BidiText`, which computes the correct visual order per line with the Unicode bidi reordering rule (UAX #9, L2); everything else keeps using a plain `Text`.
* `GptMarkdownConfig.getRich` now returns `Widget` instead of `Text`.

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
