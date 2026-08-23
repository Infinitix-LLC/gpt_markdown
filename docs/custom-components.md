# Custom components

For syntax the package does not know about.

> [!TIP]
> Reach for this **last**. For `@mention`-style tokens use
> [`InlinePattern`](inline-syntax.md) — no subclassing, and it gets the nesting
> rules right for free. For appearance use a
> [style object](customization.md). A custom component is for genuinely new
> syntax.

---

## The two lists

```dart
GptMarkdown(
  text,
  components: [...],        // block pass: headings, lists, tables, fences
  inlineComponents: [...],  // inline pass: bold, links, code, images
)
```

> [!WARNING]
> Passing a list **replaces** the defaults. Build on top of them or you lose
> every built-in construct:

```dart
// Wrong — bold, links and code stop working
inlineComponents: [MyComponent()],

// Right
inlineComponents: [MyComponent(), ...MarkdownComponent.inlineComponents],
```

---

## An inline component

Say you want `!!shout!!` to render in caps:

```dart
class ShoutMd extends InlineMd {
  @override
  RegExp get exp => RegExp(r'!![A-Za-z]+!!');

  @override
  Set<MarkdownScope> get scopes => MarkdownComponent.allScopesExceptLinkLabel;

  @override
  InlineSpan span(
    BuildContext context,
    String text,
    GptMarkdownConfig config,
  ) {
    return TextSpan(
      text: text.replaceAll('!!', '').toUpperCase(),
      style: config.style?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}
```

```dart
GptMarkdown(
  'This is !!important!! text.',
  inlineComponents: [ShoutMd(), ...MarkdownComponent.inlineComponents],
)
```

`text` is the whole matched string, so re-run your regex if you need groups:

```dart
final match = exp.firstMatch(text);
final inner = match?.group(1) ?? text;
```

---

## A block component

Extend `BlockMd`, override `expString` and return a widget:

```dart
class CalloutMd extends BlockMd {
  @override
  String get expString => r':::(\w+)\n([\s\S]*?)\n:::';

  @override
  Widget build(
    BuildContext context,
    String text,
    GptMarkdownConfig config,
  ) {
    final match = exp.firstMatch(text);
    final kind = match?.group(1) ?? 'note';
    final body = match?.group(2) ?? '';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(kind == 'warning' ? Icons.warning : Icons.info),
          const SizedBox(width: 8),
          // Render the body as Markdown too.
          Flexible(child: GptMarkdown(body, style: config.style)),
        ],
      ),
    );
  }
}
```

---

## Rules that are easy to miss

### Declare your scopes

```dart
@override
Set<MarkdownScope> get scopes => MarkdownComponent.allScopesExceptLinkLabel;
```

> [!WARNING]
> Without this a component fires **everywhere**, including inside link labels.
> If it returns a `WidgetSpan`, that nests a placeholder inside the link's own
> placeholder — which **does not paint on iOS**. The text is invisible, with no
> error and nothing in the logs.

### Order matters twice

List order decides two different things: which alternative the combined regex
matches at a given position, and which handler claims the match. Earlier wins
both times, so **prepend** to override:

```dart
inlineComponents: [MyLinkMd(), ...MarkdownComponent.inlineComponents],
```

### Return the source on failure

```dart
// Wrong — the user's text disappears with no warning
if (match == null) return const TextSpan();

// Right
if (match == null) return TextSpan(text: text, style: config.style);
```

The package does the same for malformed links.

### Inline widgets need scale compensation

> [!WARNING]
> A paragraph lays inline children out in scaled space — it hands them
> `maxWidth / scale` and multiplies the reported size back. A child that also
> scales its own text is counted twice, and at a 2× system font setting can
> reserve **many times** the space it needs.

```dart
// Wrong at raised text scales
return WidgetSpan(child: MyChip());

// Right
return WidgetSpan(child: MediaQuery.withNoTextScaling(child: MyChip()));

// Also right, and baseline-aligned
return baselineWidgetSpan(MyChip());
```

`InlinePattern` does this for you.

### Case sensitivity is contagious

The combined regex carries one set of flags. One component declaring
`caseSensitive: false` makes the whole alternation case-insensitive — required
for it to match at all, but be aware it affects the others.

### Cache the list

> [!WARNING]
> Component lists are compared by element identity. Building the list inline in
> `build` creates new instances every frame, regenerating every span.

```dart
// Wrong
GptMarkdown(text, inlineComponents: [ShoutMd(), ...])

// Right
late final _components = [ShoutMd(), ...MarkdownComponent.inlineComponents];
GptMarkdown(text, inlineComponents: _components)
```

---

## Testing a component

```dart
testWidgets('renders in caps', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: GptMarkdown(
          'a !!loud!! word',
          inlineComponents: [ShoutMd(), ...MarkdownComponent.inlineComponents],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  // Markdown renders as spans, not Text widgets — read the span tree.
  final buffer = StringBuffer();
  for (final rt in tester.widgetList<RichText>(
    find.byWidgetPredicate((w) => w is RichText),
  )) {
    buffer.write(rt.text.toPlainText(includePlaceholders: false));
  }
  expect(buffer.toString(), contains('LOUD'));
});
```

Add a case for your component **inside a link label**, since that is the one
that fails silently:

```dart
await tester.pumpWidget(/* … '[!!loud!!](https://x.com)' … */);
// With allScopesExceptLinkLabel it should stay literal, not become a chip.
```

More in [testing](testing.md).
