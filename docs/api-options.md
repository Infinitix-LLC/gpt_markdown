# `GptMarkdown` options

A reference for the public constructor. Follow the linked guides for behavior
that needs more than a one-line description.

## Content and layout

| Option | Default | Purpose |
|---|---|---|
| `data` | required | Markdown source passed as the first positional argument |
| `style` | inherited | Base `TextStyle`; headings, markers and inline code derive from it |
| `textDirection` | `TextDirection.ltr` | Direction used by paragraphs and mixed inline widgets |
| `textAlign` | inherited | Paragraph alignment |
| `textScaler` | `MediaQuery` | Explicit scaler propagated to text and inline widgets |
| `maxLines` | unlimited | Maximum paragraph lines |
| `overflow` | inherited | Overflow behavior when `maxLines` is reached |

The widget sizes itself to its content and does not provide vertical scrolling.
See [getting started](getting-started.md).

## Parsing and syntax

| Option | Default | Purpose |
|---|---|---|
| `incremental` | `true` | Uses plusparse and caches unchanged top-level segments |
| `useDollarSignsForLatex` | `false` | Enables `$…$` and `$$…$$` maths parsing |
| `latexWorkaround` | none | Transforms TeX immediately before rendering |
| `autolink` | `true` | Enables bare URL, host and email autolinking |
| `autolinkSchemes` | empty set | Additional schemes accepted as bare links |
| `inlineDirectives` | none | Protects delimited host data from Markdown parsing |
| `inlinePatterns` | none | Adds consumer-defined inline tokens to both parser paths |
| `components` | built-ins | Replaces the legacy block-component list |
| `inlineComponents` | built-ins | Replaces the legacy inline-component list |

Custom `components` or `inlineComponents` select the legacy parser even when
`incremental` is true. Passing a short list replaces the defaults rather than
extending them. Build block lists on top of
`MarkdownComponent.globalComponents` and inline lists on top of
`MarkdownComponent.inlineComponents`. See
[custom components](custom-components.md).

## Streaming and animation

| Option | Default | Purpose |
|---|---|---|
| `animation` | `GptMarkdownAnimation.none` | Character reveal effect |
| `blockAnimation` | `GptMarkdownBlockAnimation.none` | Entrance for atomic block widgets |
| `isStreaming` | `true` | Says whether more source may arrive |
| `charactersPerSecond` | `300` | Adaptive reveal baseline |
| `revealFadeSeconds` | `0.25` | Time for an arriving character to settle |
| `blockAnimationDuration` | `200 ms` | Duration of a block entrance |
| `blockAnimationCurve` | `Curves.easeOut` | Easing used by block entrances |

`isStreaming`, `charactersPerSecond` and `revealFadeSeconds` matter only when a
character reveal is active. Block animation is an independent axis.
`incremental` remains useful with `animation: none`. See
[streaming and incremental rendering](streaming.md).

## Appearance

| Option | Default | Purpose |
|---|---|---|
| `styleSheet` | themed defaults | Per-component visual overrides |
| `inlineCodeStyle` | themed defaults | Convenience override for inline code only |
| `followLinkColor` | `false` | Lets nested link-label content inherit the link color |

Use `GptMarkdownThemeData` for app-wide defaults and `styleSheet` for one
widget. Widget fields win over theme fields one property at a time. See
[customization](customization.md).

## Builders

Builders replace structure. All are optional:

| Option | Replaces |
|---|---|
| `headingBuilder` | A heading and its optional divider |
| `blockQuoteBuilder` | A block quote |
| `checkboxBuilder` | A task-list row |
| `radioOptionBuilder` | A radio-option row |
| `hrBuilder` | A horizontal rule |
| `codeBuilder` | A fenced code block |
| `tableBuilder` | A table |
| `imageBuilder` | An image |
| `latexBuilder` | Inline or block TeX |
| `linkBuilder` | A Markdown or automatic link |
| `inlineCodeBuilder` | The span for inline code |
| `sourceTagBuilder` | A citation/source tag |
| `orderedListBuilder` | An ordered-list item |
| `unOrderedListBuilder` | An unordered-list item |

`highlightBuilder` is deprecated; use `inlineCodeBuilder`. Builder signatures
and resolved styles are listed in [customization](customization.md#builders).

## Callbacks

| Option | Called when |
|---|---|
| `onLinkTap` | A link is activated; receives URL and label |
| `onImageTap` | An image is activated |
| `onCodeCopy` | The built-in code copy action succeeds |
| `onSourceTagTap` | A citation/source tag is activated |
| `onCheckboxChanged` | An interactive task checkbox changes |

Checkboxes are read-only unless `CheckboxStyle.interactive` is true. A custom
`codeBuilder` owns its own copy behavior and does not invoke `onCodeCopy`
automatically.

## Choosing the right extension point

1. Use `style` for surrounding typography.
2. Use a style object for component appearance.
3. Use `InlinePattern` for app-specific inline tokens.
4. Use a builder when the component's structure must change.
5. Use `MarkdownComponent` only for genuinely new grammar.
