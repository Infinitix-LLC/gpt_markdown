# Streaming and incremental rendering

Rendering a reply while the model is still generating it.

## The shape

Streaming is **data, not a `Stream`**. Rebuild `GptMarkdown` with the complete
text received so far and tell it whether more content may arrive:

```dart
class ReplyView extends StatefulWidget {
  const ReplyView({super.key, required this.stream});
  final Stream<String> stream;

  @override
  State<ReplyView> createState() => _ReplyViewState();
}

class _ReplyViewState extends State<ReplyView> {
  final _buffer = StringBuffer();
  bool _generating = true;

  @override
  void initState() {
    super.initState();
    widget.stream.listen(
      (chunk) => setState(() => _buffer.write(chunk)),
      onDone: () => setState(() => _generating = false),
      onError: (_) => setState(() => _generating = false),
    );
  }

  @override
  Widget build(BuildContext context) => GptMarkdown(
    _buffer.toString(),
    incremental: true, // The default; written here to make the intent clear.
    animation: GptMarkdownAnimation.fade,
    blockAnimation: GptMarkdownBlockAnimation.fadeIn,
    isStreaming: _generating,
  );
}
```

Keep the same widget identity while the reply grows. Giving every chunk a new
key remounts the renderer and discards its reveal position and caches.

## `incremental`

`incremental` defaults to `true`. It selects the single-pass plusparse parser
and a segment-cached renderer:

```text
message
├── settled heading       → cached
├── settled paragraph     → cached
├── settled table         → cached
└── changing tail         → rebuilt
```

The source is split into top-level segments at safe blank lines. A blank line
inside fenced code or block maths is not a split point. When text is appended,
unchanged segments keep their parsed spans and settled widget instances; only
the tail is parsed, built and laid out again. The cost of an append therefore
stays roughly flat instead of rising with the length of the answer.

This optimization is useful even without animation:

```dart
GptMarkdown(
  streamedText,
  incremental: true,
  animation: GptMarkdownAnimation.none,
)
```

There is no need to fake a disabled animation with an extremely high
`charactersPerSecond` value.

### Legacy compatibility

Set `incremental: false` to select the older combined-regex renderer. This is
primarily an escape hatch for compatibility testing.

Supplying custom `components` or `inlineComponents` also selects the legacy
pipeline because consumer-defined regex components cannot be represented by
the built-in AST. `InlinePattern` and `InlineDirective` work on the incremental
pipeline and do not require that fallback.

An active character reveal uses the incremental renderer whenever custom
components do not prevent it, even if `incremental` is false. The reveal needs
the parsed span tree so it can animate existing text without reparsing Markdown
on every frame.

## Performance

There are two separate improvements.

### Parser speed

The package benchmark compares the legacy recursive combined-regex parser with
plusparse doing equivalent source-to-renderable-structure work:

| Scenario | Recorded speedup |
|---|---:|
| Dense inline syntax | about **20x** |
| Typical AI reply | about **32x** |
| Large 35 KB document | about **54x** |
| Re-parsing streamed prefixes | about **69x** |

Run it locally:

```bash
flutter test test/plusparse/plusparse_benchmark_test.dart
```

### Streaming rebuild work

The widget benchmark repeatedly appends 30 Markdown chunks. Segment caching
recorded about **4.6x less total rebuild and layout work** than the single-text
pipeline, while reusing every unchanged segment by identity:

```bash
flutter test test/plusparse/incremental_test.dart
```

These are debug-VM measurements, not device guarantees. Absolute times vary by
machine, Flutter version and document shape. The meaningful results are the
relative parser speed and the fact that incremental append cost does not grow
with the whole message.

## Character animations

`animation` controls how prose arrives. It defaults to `none`.

| Value | Behaviour |
|---|---|
| `GptMarkdownAnimation.none` | Shows content immediately; no reveal ticker |
| `.typewriter` | Reveals paced characters at their final appearance |
| `.fade` | Fades newly revealed text from transparent |
| `.blurIn` | Resolves new text out of a blur while fading in |
| `.wave` | Sends an accent-colour crest across new characters |

`typewriter` controls only visibility and pacing. `fade` and `blurIn` style
word-sized runs to preserve shaping, kerning and stable wrapping. `wave` is the
only effect that needs neighboring characters styled independently.

## Block animations

Tables, fenced code, block maths, rules and images are laid-out widgets. They
cannot reveal meaningful partial text, so `blockAnimation` controls their
one-shot entrance separately:

| Value | Behaviour | Changes layout height? |
|---|---|:---:|
| `GptMarkdownBlockAnimation.none` | Appears immediately | No |
| `.fadeIn` | Fades in at full size | No |
| `.growIn` | Expands vertically while fading | **Yes** |
| `.slideUp` | Rises slightly while fading | No |
| `.scaleIn` | Scales from slightly smaller while fading | No |

The two axes compose:

```dart
GptMarkdown(
  streamedText,
  incremental: true,
  animation: GptMarkdownAnimation.blurIn,
  blockAnimation: GptMarkdownBlockAnimation.slideUp,
  isStreaming: generating,
  charactersPerSecond: 300,
  revealFadeSeconds: 0.25,
  blockAnimationDuration: const Duration(milliseconds: 200),
  blockAnimationCurve: Curves.easeOut,
)
```

Block entrances are independent of the character effect and can be used with
`animation: none`. They play once when a new atomic block arrives; rebuilding
a settled message or scrolling it through a lazy-list cache boundary does not
replay them. They require the incremental renderer, so custom component lists
that select the legacy pipeline do not get these entrances.

## Tuning

`charactersPerSecond` defaults to 300. It is a baseline, not a hard limit. If
the backlog would take too long to clear, the reveal accelerates automatically
so it does not fall progressively behind a fast model.

`revealFadeSeconds` defaults to 0.25. It controls how long a newly revealed
character takes to settle after the reveal head passes. It does not change the
head's base speed and has no visual effect on `typewriter`.

`blockAnimationDuration` defaults to 200 milliseconds, and
`blockAnimationCurve` defaults to `Curves.easeOut`.

When `isStreaming` changes from true to false, any backlog fast-forwards rather
than continuing at the reading pace. Replacing the text instead of extending
it is treated as a regenerate or branch switch and starts a new reveal.

## Existing and incomplete content

Text already present when the renderer mounts is shown immediately. This keeps
history messages, restored conversations and live replies recreated by a lazy
list from replaying their animation. Only content appended after mount enters
through the reveal.

The reveal holds unfinished inline Markdown briefly so readers do not see text
change style after it has appeared. This applies to constructs such as bold,
inline code, links and inline maths. An open fenced-code block continues to
stream as code, while incomplete block maths waits for its closing delimiter.
The hold releases after a quiet period so a genuinely unmatched delimiter
cannot hide the end of a response forever.

## Why `isStreaming` matters

Set `isStreaming` to false for completed and historical messages:

```dart
GptMarkdown(
  message.text,
  animation: GptMarkdownAnimation.fade,
  isStreaming: message.isGenerating,
)
```

It tells the renderer when to fast-forward the remainder and stop its ticker.
Always clear it on normal completion and error paths. Leaving it true does not
disable segment caching, but it can leave reveal machinery waiting for content
that will never arrive.

## Accessibility and interaction

When `MediaQuery.disableAnimationsOf(context)` is true, content renders
immediately and no reveal ticker runs. No additional configuration is needed.

Selection is not a stable interaction while a reveal is actively rebuilding
its live spans. It is available normally once the reply settles. Links and
other interactions in settled content remain ordinary widgets.

Incremental rendering optimizes one `GptMarkdown` instance. It cannot prevent a
parent chat list from rebuilding every bubble on each token. Keep streaming
state local to the active message where possible.

For auto-scroll, pin to the bottom only while the reader is already there. A
forced jump on every chunk fights both reading and block entrances.

## Trying it

```bash
cd example && flutter run -d macos -t lib/streaming_demo.dart
```

The demo lets you vary model and reveal speed, stop generation to see
fast-forwarding, and compare animation modes.
