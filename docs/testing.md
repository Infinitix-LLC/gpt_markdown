# Testing

Things that bite when writing widget tests against rendered Markdown.

---

## `find.text` rarely works

Markdown renders as spans inside one paragraph, not as separate `Text` widgets.
`find.text('hello')` only matches a `Text` whose entire `data` is `hello`.

```dart
// Fails, even though "hello" is on screen
expect(find.text('hello'), findsOneWidget);
```

Read the text out of the spans instead:

```dart
String plainText(WidgetTester tester) {
  final buffer = StringBuffer();
  for (final rt in tester.widgetList<RichText>(
    find.byWidgetPredicate((w) => w is RichText),
  )) {
    buffer.write(rt.text.toPlainText(includePlaceholders: false));
  }
  return buffer.toString();
}

expect(plainText(tester), contains('hello'));
```

> [!TIP]
> `find.text` **does** work for content inside a `WidgetSpan` — a chip from a
> custom component, a code block, a table cell — because those are real `Text`
> widgets.

---

## `find.byType(RichText)` misses paragraphs

Paragraphs carrying inline code, or needing right-to-left placeholder
reordering, render through `BidiRichText` — a `RichText` **subclass**.
`find.byType` matches exact runtime types.

```dart
// Misses them
find.byType(RichText)

// Finds them
find.byWidgetPredicate((widget) => widget is RichText)
```

> [!WARNING]
> This one is nasty because it fails *selectively*. A test passes on plain
> prose and fails the moment someone adds `` `code` `` to the fixture.

---

## Changing a builder at runtime does nothing

`GptMarkdownConfig.isSame` decides whether spans are regenerated, and it cannot
compare closures — any consumer writing them inline creates a new one every
build, so comparing them would defeat the cache entirely.

```dart
// This will not take effect
await tester.pumpWidget(app(codeBuilder: builderA));
await tester.pumpWidget(app(codeBuilder: builderB));   // still builderA
```

Give the widget a key that changes with it:

```dart
GptMarkdown(text, key: ValueKey(builderId), codeBuilder: builder)
```

Styles, patterns and component lists **are** compared and do update live.

---

## Overflow warnings are expected at raised text scales

Code blocks and long headings cannot wrap. At 2× or 3× on a phone-width surface
they overflow horizontally, failing any assertion that
`tester.takeException()` is null.

Drain it deliberately rather than widening the surface until it hides:

```dart
await tester.pumpAndSettle();
while (tester.takeException() != null) {}
```

> [!TIP]
> Do not silence it globally. Drain it in the tests where the overflow is
> expected, so a *new* overflow somewhere else still fails.

---

## Height ratios are not scale ratios

At a raised text scale a paragraph gets **more lines**, so its height can grow
5× while every line is exactly 2× taller.

```dart
// Wrong conclusion: "text scaling is broken, it grew 5x"
final ratio = heightAt2x / heightAt1x;
expect(ratio, closeTo(2.0, 0.1));   // fails for reasons that are not a bug
```

Measure at a width where nothing rewraps:

```dart
SizedBox(width: 4000, child: GptMarkdown(sample))
```

Or compare line height rather than total height, via
`RenderParagraph.getBoxesForSelection`.

---

## Streaming needs pumping, not settling

`pumpAndSettle` waits for animations to finish. A reveal does finish — but only
after the whole reply is revealed, which may be seconds of simulated time.

```dart
// One frame of the reveal
await tester.pump(const Duration(milliseconds: 16));

// Let it run to completion
await tester.pumpAndSettle(const Duration(seconds: 5));
```

For tests that are not about streaming, skip the animation entirely:

```dart
GptMarkdown(text, animation: GptMarkdownAnimation.none)
// or
GptMarkdown(text, animation: GptMarkdownAnimation.fade, isStreaming: false)
```

---

## Testing a style

Assert on the widget the style feeds, not on pixels:

```dart
testWidgets('the bar follows the theme', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        extensions: [
          GptMarkdownThemeData(
            brightness: Brightness.light,
            styleSheet: const GptMarkdownStyleSheet(
              blockQuote: BlockQuoteStyle(barWidth: 7),
            ),
          ),
        ],
      ),
      home: const Scaffold(body: GptMarkdown('> quoted')),
    ),
  );
  await tester.pumpAndSettle();

  final quote = tester.widget<BlockQuoteWidget>(
    find.byType(BlockQuoteWidget),
  );
  expect(quote.width, 7);
});
```

Also assert the **merge**, because per-object override is the easy mistake:
set one field on the widget and a different one on the theme, then check both
survived.

---

## Golden tests

The package's defaults are locked by goldens in
`test/golden/default_look_test.dart` — eight constructs in light and dark.

> [!IMPORTANT]
> **They run on Linux only**, and are skipped everywhere else.
>
> Text rasterisation is not identical across platforms, so a golden captured on
> macOS fails on CI for reasons that are not a change. Pinning to one platform
> is the only way the comparison means anything.

A tolerance was tried and rejected. Any threshold loose enough to absorb
cross-platform antialiasing also hides real changes — widening the blockquote
bar from 3 to 9 points passed at a 0.5% tolerance, which defeats the point.

To regenerate after an intended change, dispatch the workflow against your
branch. It regenerates on Linux and commits the images back, so a maintainer
on macOS or Windows never has to produce them by hand:

```bash
gh workflow run goldens.yml --ref my-branch
gh run watch
git pull
```

Pass `-f commit=false` to get the images as an artifact and commit them
yourself. On Linux, `./scripts/goldens.sh` does the whole thing locally.

> [!WARNING]
> Regenerating is not a fix for a failing golden — it is how you record a
> change you meant to make. `--update-goldens` overwrites the reference with
> whatever the code now draws, so running it on a red build makes the
> regression the new baseline. Look at the diff images first.
>
> This is why the workflow is manual. If it ran on every push the goldens would
> always match and the test could never fail.

If a golden fails on CI, download the `golden-failures` artifact from the run —
it contains the expected, actual and diff images, which is the only readable
way to see what moved.

## README screenshots

`./scripts/screenshots.sh` regenerates the showcase images in `screenshots/`
from `tool/screenshots/`. They render through the test harness because that is
the supported way to rasterise a widget to a file without opening a window.

Unlike goldens, nothing compares them — they are documentation, so any machine
can regenerate them. `flutter test` only looks in `test/`, so they never run on
CI and never gate a build.

> [!NOTE]
> Two things in the images are harness artefacts, not defects in what a reader
> would see. Text that resolves to a null font family — the code block's copy
> button, for one — draws in the test font, whose glyphs are filled boxes, so
> that button is switched off for the screenshots. Fonts are otherwise loaded
> from paths resolved out of the SDK and `.dart_tool/package_config.json`, never
> hardcoded.

## Documentation snippets are compiled

Every snippet in `docs/` lives in `test/docs/snippets_test.dart` and is
compiled by the test suite. If you rename a parameter, that file stops
compiling — so the guides cannot quietly go stale.

Add to it when you document something new.
