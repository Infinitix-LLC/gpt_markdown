# Inline syntax

Autolinks, and app-specific tokens like `@mention`, `#channel` and `:emoji:`.

---

## Autolinks

Bare URLs, `www.` hosts, email addresses and `<…>` autolinks become links with
no pre-processing:

```dart
GptMarkdown(
  'Ship it: https://pub.dev or mail ada@example.com',
  onLinkTap: (url, title) => launchUrlString(url),
)
```

Bare autolinks follow the
[GFM autolink extension](https://github.github.com/gfm/#autolinks-extension-),
so the awkward cases come out right:

| Input | Links to |
|---|---|
| `see https://x.com.` | `https://x.com` — the period stays outside |
| `(https://x.com)` | `https://x.com` — unbalanced `)` stays outside |
| `https://en.wikipedia.org/wiki/Foo_(bar)` | the whole URL — parens balance |
| `www.example.com` | `http://www.example.com` |
| `ada@example.com` | `mailto:ada@example.com` |
| `**https://x.com**` | bold link, `**` never reaches the href |
| `` `https://x.com` `` | nothing — it stays code |

`<https://x.com>`, `<mailto:a@b.com>` and `<a@b.com>` follow CommonMark §6.5.

### Schemes

`http`, `https`, `mailto` and `xmpp` are linked bare. Anything else is opt-in:

```dart
GptMarkdown(text, autolinkSchemes: const {'myapp', 'slack'})
```

> [!NOTE]
> A bare `myapp://thing` in prose usually is not meant as a link, which is why
> it needs the allowlist. Angle autolinks accept **any** scheme without it —
> `<myapp://thing>` works — because the author wrote the brackets deliberately.

Turn it all off:

```dart
GptMarkdown(text, autolink: false)
```

Explicit `[label](url)` links keep working.

### Why this beats a pre-processor

> [!IMPORTANT]
> If your app rewrites bare URLs into `[url](url)` before rendering, **delete
> that step** or set `autolink: false`. Otherwise both run.

Removing it is the better fix. A pre-processor works on raw Markdown and has to
guess where the syntax ends and the URL begins — which is how
`**https://x.com**` becomes a link whose href ends in `**`.

A component runs *after* the surrounding syntax is consumed: `BoldMd` matches
first, strips the `**`, and the autolinker only ever sees a clean URL. That
class of bug cannot happen. The same holds for backticked URLs, headings and
table cells.

---

## App-specific tokens

Chat apps layer their own inline syntax on top of Markdown. `#2959` is a
channel in one product, a topic in another, an issue in a third — so the
package supplies the mechanism and you supply the meaning.

### A simple pattern

```dart
GptMarkdown(
  text,
  inlinePatterns: [
    InlinePattern(
      pattern: RegExp(r'(?<![\w-])GH-(\d+)\b'),
      builder: (context, match, style) => TextSpan(
        text: match.group(0),
        style: style.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () => openIssue(match.group(1)!),
      ),
    ),
  ],
)
```

Patterns are matched **ahead of** the built-in components, so a pattern always
wins over the default reading of the same text.

### Prefixed tokens

`@name` and `#channel` have a helper, because the boundary rules are fiddly —
an `@` inside an email and a `#` in a URL fragment must not match.

```dart
InlinePattern.prefixed(
  prefix: '#',
  knownNames: myChannelNames,          // ['general', 'design-review', …]
  builder: (context, match, style) => WidgetSpan(
    alignment: PlaceholderAlignment.baseline,
    baseline: TextBaseline.alphabetic,
    child: ChannelChip(name: match.group(0)!.substring(1)),
  ),
)
```

Longer names win over shorter ones, so `#design-review` is not shadowed by a
`#design` entry. Matching is case-insensitive.

> [!WARNING]
> `genericTokenPattern` is optional, and leaving it **null** is usually right —
> then only the names you pass match.
>
> Supply one and every `#token` becomes a chip, including `#2959` when the
> author meant issue 2959. That is a real bug that shipped in a real app.

```dart
// Only known channels — recommended
InlinePattern.prefixed(prefix: '#', knownNames: channels, builder: …)

// Any token at all — chips for things that are not channels
InlinePattern.prefixed(
  prefix: '#',
  knownNames: channels,
  genericTokenPattern: r'[A-Za-z0-9_][A-Za-z0-9_-]*',
  builder: …,
)
```

### Emoji shortcodes

```dart
InlinePattern(
  pattern: RegExp(':(tada|rocket|fire):'),
  builder: (context, match, style) => WidgetSpan(
    alignment: PlaceholderAlignment.middle,
    child: Text(
      const {'tada': '🎉', 'rocket': '🚀', 'fire': '🔥'}[match.group(1)] ?? '',
      style: TextStyle(fontSize: (style.fontSize ?? 14) * 1.15),
    ),
  ),
)
```

Build the alternation from your palette, longest first, so a longer shortcode
is not shadowed by a shorter prefix.

### Prefer a TextSpan

> [!TIP]
> A `TextSpan` stays selectable, wraps across lines and sits on the baseline. A
> `WidgetSpan` does none of those. Use a widget only when the design genuinely
> needs one — a rounded chip with an icon, say.

Widgets returned from a pattern builder are handled correctly at raised text
scales: the package wraps them so they do not scale twice.

---

## Scopes

Markdown nests: a link label can contain bold text, a table cell can contain a
link. A component declares where it applies.

| Scope | Where |
|---|---|
| `content` | ordinary document and inline text |
| `linkLabel` | inside the `label` of `[label](url)` |
| `tableCell` | inside a table cell |
| `heading` | inside a `#` heading |

`InlinePattern` defaults to `MarkdownComponent.allScopesExceptLinkLabel`.

> [!WARNING]
> That default matters. A link label is already rendered inside the link's own
> `WidgetSpan`; a pattern returning a second one there produces a **nested
> placeholder, which does not paint on iOS** — the text is simply invisible,
> with no error.
>
> `[#design](https://example.com)` was blank on iOS for exactly this reason.

Opt back in when your builder returns a `TextSpan`, which is safe to nest:

```dart
InlinePattern(
  pattern: RegExp(r'GH-\d+'),
  builder: (context, match, style) => TextSpan(text: match.group(0)),
  scopes: MarkdownComponent.allScopes,
)
```

Restrict further when a token only makes sense in prose:

```dart
scopes: const {MarkdownScope.content},
```

---

## Common mistakes

> [!WARNING]
> **A generic `#` fallback.** It turns issue numbers, hex colours and headings
> written mid-sentence into chips. Match known names only unless you have a
> reason not to.

> [!WARNING]
> **Rebuilding the pattern list every frame.** The list is compared by element
> identity, so a fresh list regenerates every span on every build. Cache it in
> a field or make it `const`.

> [!TIP]
> **Anchor with lookarounds, not `^`/`$`.** Patterns are matched against the
> document, not a line, so `^` will not do what you expect. Use
> `(?<![\w-])` and `\b` to define boundaries.
