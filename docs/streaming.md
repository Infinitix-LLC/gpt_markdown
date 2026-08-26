# Streaming

Rendering a reply while the model is still generating it.

## The shape

Streaming is **data, not a `Stream`**. Rebuild the widget with a longer string
as tokens arrive, and say whether more is coming:

```dart
class ReplyView extends StatefulWidget {
  const ReplyView({super.key, required this.stream});
  final Stream<String> stream;   // your transport, whatever it is

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
    );
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: GptMarkdown(
      _buffer.toString(),
      animation: GptMarkdownAnimation.fade,
      isStreaming: _generating,
    ),
  );
}
```

`GptMarkdownAnimation.none` is the default. It takes an early return: no
ticker, no wrapper widget, no split — the tree is exactly what it would be
without the feature.

---

## Why `isStreaming` is required

> [!IMPORTANT]
> Without it the widget cannot tell two very different events apart:
>
> * the text got **longer** — a new token, so continue revealing
> * the text got **different** — a regenerate or branch switch, so restart
>
> And it cannot know the reply finished, which is when the remainder should
> fast-forward in rather than trickle.

Set it false for history messages and the widget renders statically, with no
animation cost at all:

```dart
GptMarkdown(
  message.text,
  animation: GptMarkdownAnimation.fade,
  isStreaming: message.isGenerating,   // false for everything already sent
)
```

---

## How it stays fast

The source is split at the last safe blank line:

```
settled prefix  →  built once, cached, behind a RepaintBoundary
live tail       →  rebuilt as the reveal advances
```

Appending to the end of a document cannot change what came before, so the
prefix is reused. Only the tail — at most one construct — is rebuilt.

Measured on a 7.7 kB reply, 120 appends:

| | per token |
|---|---|
| `animation: none` | 14.6 ms |
| `animation: fade` | **11.0 ms** |

Faster **with** the animation, because the plain path rebuilds the whole
document on every token while the split path does not. The plain path also gets
worse as the reply grows; the split path stays flat.

> [!NOTE]
> The split never cuts inside a fenced code block or block maths. A prefix
> holding an unterminated ``` would render as literal text until the closing
> fence arrived — a visible flicker mid-stream.

---

## Pacing

`charactersPerSecond` (default 300) is a **baseline, not a limit**.

```dart
GptMarkdown(
  reply,
  animation: GptMarkdownAnimation.fade,
  isStreaming: generating,
  charactersPerSecond: 220,   // calmer
)
```

Three behaviours sit on top of it:

**Lag adaptation.** A model can emit faster than the reveal draws. Whenever the
backlog would take more than 0.4 s to clear, the reveal speeds up to clear it
in that window — so it never falls further behind for the rest of a long reply.

**Fast-forward.** When `isStreaming` turns false there is nothing left to wait
for, so the remainder lands within 0.15 s. A finished reply never trickles.

**Restart.** Text that replaces rather than extends restarts the reveal — a
regenerate or a branch switch.

> [!TIP]
> Do not try to match `charactersPerSecond` to your model's speed. The
> adaptation handles that. Pick the speed that reads well when the model is
> *slower* than the reveal — that is the case you control.

---

## Accessibility

Reduced motion is honoured. When `MediaQuery.disableAnimationsOf` is true the
reveal is skipped and the finished document renders immediately. No ticker
runs.

Nothing to configure — but do test it, because it is the path a real user with
motion sensitivity gets:

```dart
MediaQuery(
  data: const MediaQueryData(disableAnimations: true),
  child: GptMarkdown(reply, animation: GptMarkdownAnimation.fade),
)
```

---

## Limitations

> [!WARNING]
> **Selection is unavailable while revealing.** The tail is rebuilt every
> frame, so it is not a stable selection target. It returns the moment the
> reply settles.

> [!NOTE]
> The fade is at the **reveal edge**, not per character. Per-glyph alpha needs
> span-level access inside the renderer.

---

## Trying it

```bash
cd example && flutter run -d macos -t lib/streaming_demo.dart
```

A simulated reply with independent sliders for **model speed** (characters
emitted per second) and **reveal speed** (characters drawn per second).

* Set the model **faster** than the reveal to watch the lag adaptation catch up
* Press **Stop** mid-reply to see the fast-forward
* Switch to `none` to compare against no animation

---

## If you are not animating

The split is part of the animation path, so `animation: none` still rebuilds
the whole document per token — 14 ms and climbing on a long reply.

To get the caching without a visible reveal, set a very high speed:

```dart
GptMarkdown(
  reply,
  animation: GptMarkdownAnimation.fade,
  isStreaming: generating,
  charactersPerSecond: 100000,   // completes within a frame
)
```

The reveal finishes instantly while the prefix stays cached.

---

## Common mistakes

> [!WARNING]
> **Leaving `isStreaming: true` after the reply finishes.** The ticker keeps
> running and the tail keeps rebuilding for nothing. Always flip it on `onDone`
> — including on error paths.

> [!WARNING]
> **Rebuilding the whole chat list per token.** The split keeps *this widget*
> cheap; it cannot help if the `ListView` above rebuilds every bubble. Make the
> message itself listenable so only the streaming bubble rebuilds.

> [!TIP]
> **Auto-scrolling?** The reply grows continuously, so a scroll controller
> jumping to the bottom on every token fights the reveal. Animate to the extent
> instead, or pin only while the user is already at the bottom.
