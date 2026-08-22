# Migration guide

## 1.1.x → 1.2.0

Nothing here stops code compiling — `1.2.0` is a drop-in upgrade. The changes
below alter what you see without a compiler warning, so read the list even
though your build is green.

---

## 1. `highlightBuilder` is deprecated

**Still works.** It is scheduled for removal in 2.0.0, and is now wrapped on
the text baseline rather than at the old hardcoded
`PlaceholderAlignment.middle`, so existing chips sit correctly against the
surrounding text.

It returned a `Widget`, which was wrapped in a `WidgetSpan` at a hardcoded
`PlaceholderAlignment.middle`. That sat off the baseline, could not wrap across
lines, was skipped by text selection, and did not paint on iOS when it ended up
inside a link label — `` [`code`](url) `` rendered as nothing.

Most callers used it only to restyle inline code, and no longer need a builder
at all:

```dart
GptMarkdown(
  text,
  inlineCodeStyle: const InlineCodeStyle(fontFamily: 'GeistMono'),
)
```

`InlineCodeStyle` covers `fontFamily`, `fontSizeFactor`, `fontWeight`, `color`,
`backgroundColor`, `borderColor`, `borderWidth`, `borderRadius`, `padding` and
`boxHeightStyle`. Every field is optional; unset fields follow your
`ColorScheme`.

If you genuinely need a widget:

```dart
// before
highlightBuilder: (context, text, style) => MyChip(text, style),

// after — returns an InlineSpan, so it stays on the baseline
inlineCodeBuilder: (context, code, style, codeStyle) =>
    baselineWidgetSpan(MyChip(code, style)),
```

`inlineCodeBuilder` receives the resolved `InlineCodeStyle` as well, so a
builder can reuse the chip colours instead of restating them. Returning a
`CodeTextSpan` keeps the painted chip; returning any other `TextSpan` drops it.

---

## 2. Inline code looks different

Was bold text on a faint `TextStyle.background` wash. It is now a monospace
chip — the bundled JetBrains Mono, matching fenced blocks — with a tinted fill,
a hairline outline and a 4px radius, painted once per line so long inline code
wraps instead of overflowing.

Nothing to change unless you want the old look. To tone it down:

```dart
GptMarkdown(
  text,
  inlineCodeStyle: const InlineCodeStyle(
    borderWidth: 0,
    backgroundColor: Colors.transparent,
    padding: EdgeInsets.zero,
  ),
)
```

Or app-wide via `GptMarkdownThemeData(inlineCode: ...)`.

---

## 3. Autolinking is on by default

Bare URLs, `www.` hosts, email addresses and `<...>` autolinks now become
links. Bare autolinks follow the GFM autolink extension; `<...>` autolinks
follow CommonMark §6.5.

```dart
GptMarkdown(text, autolink: false)              // keep URLs as plain text
GptMarkdown(text, autolinkSchemes: {'myapp'})   // also link myapp://…
```

**If your app rewrites bare URLs into `[url](url)` before rendering, remove
that step or set `autolink: false`.** Otherwise both run.

Removing the pre-processor is the better fix: a pre-processor works on raw
Markdown and has to guess where the syntax ends and the URL begins, which is
how `**https://example.com**` becomes a link whose href ends in `**`. The
renderer sees the URL after the emphasis has already been consumed, so that
class of bug cannot happen.

---

## 4. Text scaling is proportional

At raised system font settings, anything rendered through a `WidgetSpan` used
to reserve far more space than it needed — measured at a 2x setting: a heading
17x, a list 10x, a checkbox 39x. Each is now exact.

No API change. A layout tuned around the old inflation will look tighter, and
content that previously overflowed at large font sizes should now fit.

If you build your own inline widgets, wrap them so they do not scale twice:

```dart
WidgetSpan(child: MediaQuery.withNoTextScaling(child: MyChip()))
```

`baselineWidgetSpan` and `InlinePattern` do this for you.

---

## 5. Some components no longer render inside link labels

`ImageMd`, `TableMd` and `ATagMd` now declare
`MarkdownComponent.allScopesExceptLinkLabel`, so `[![alt](img)](url)` and
nested links render differently. They used to produce a placeholder nested
inside the link's own placeholder, which does not paint on iOS.

A **custom** component still renders inside link labels unless it says
otherwise:

```dart
class MyChipMd extends InlineMd {
  @override
  Set<MarkdownScope> get scopes => MarkdownComponent.allScopesExceptLinkLabel;

  // ...
}
```

If your component returns a `WidgetSpan`, you want this — it is the fix for a
chip going blank inside `[#channel](url)` on iOS.

Better still, app-specific inline syntax has a first-class API that excludes
link labels by default and needs no subclassing:

```dart
GptMarkdown(
  text,
  inlinePatterns: [
    InlinePattern.prefixed(
      prefix: '#',
      knownNames: channelNames,
      builder: (context, match, style) =>
          WidgetSpan(child: ChannelChip(match.group(0)!)),
    ),
  ],
)
```

Leaving `genericTokenPattern` null matches only the names you pass, so `#2959`
stays an issue number instead of being claimed as a channel.

---

## 6. Text that used to disappear now shows

Malformed links such as `[[a](http://x)` or `[label](http://x`, and matches no
component claims, render as plain text instead of being dropped silently. Debug
builds also print a warning.

If you were relying on malformed Markdown vanishing, it no longer does.

---

## 7. Components whose pattern contains a top-level `|`

Handler dispatch was anchored as `'^$pattern$'`, which binds `^` to the first
alternative and `$` to the last. A component whose pattern contained a
top-level `|` therefore claimed matches it did not actually cover — and, being
earlier in the list, could take them from the component that did.

It is now anchored as `'^(?:$pattern)$'`. If you have a component with
alternation, check it still matches what you expect.

---

## 8. Case-insensitive component patterns now match

The combined regex was always built case-sensitively, so a component declaring
`RegExp(..., caseSensitive: false)` never received those matches. It does now,
which may surface matches you did not previously see.

---

## 9. Tests: `find.byType(RichText)` misses package paragraphs

Paragraphs carrying inline code, or needing right-to-left placeholder
reordering, render through `BidiRichText` — a `RichText` **subclass** — and
`find.byType` matches exact runtime types.

```dart
// before
find.byType(RichText)

// after
find.byWidgetPredicate((widget) => widget is RichText)
```

---

## Not breaking

Everything in the customization work is additive:

* `GptMarkdownStyleSheet` and the twelve per-component style classes
* `blockQuoteBuilder`, `headingBuilder`, `checkboxBuilder`,
  `radioOptionBuilder`, `hrBuilder`
* `onCheckboxChanged`, `onCodeCopy`, `onImageTap`, `onSourceTagTap`
* `MarkdownScope`, `InlinePattern`, `autolink`, `autolinkSchemes`

The existing `h1`-`h6`, `linkColor`, `linkHoverColor` and `hrLine*` theme
fields keep working, and every previous builder keeps its signature. A
style-sheet value overrides them only where you set one.
