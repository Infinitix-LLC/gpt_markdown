# gpt_markdown — streaming AI chat harness

A second example app, separate from `example/`, built for one purpose: watch
`GptMarkdown` render **live model output** and measure what that costs.

The whole screen above the prompt box is a single `GptMarkdown` widget. Text
arrives from any OpenAI-protocol endpoint over SSE, the widget is rebuilt with
the full reply received so far, and a metrics bar reports how the UI thread
held up.

```
┌──────────────────────────────┐
│  GptMarkdown (full screen)   │  ← the widget under test
│                              │
├──────────────────────────────┤
│ ttft 412 ms · chars/s 180 …  │  ← live render metrics
├──────────────────────────────┤
│ [ Ask the model something… ]▲│  ← prompt box
└──────────────────────────────┘
```

## Run it

The app ships pointed at [`ai-testing`](../../ai-testing) — a small Node proxy
that sits next to `gpt_markdown/` and holds the provider key server-side, so
no key ever reaches this app:

```bash
# terminal 1 — the proxy holds the key
cd ../../ai-testing
OPENAI_API_KEY=sk-... npm start

# terminal 2 — the app needs nothing
cd ../gpt_markdown/example_ai_chat
flutter run -d macos
```

That is also the only setup that works on **web**: a browser will not let a
page call `api.openai.com` directly, and the proxy sends the CORS headers
that make it work.

### Talking to a provider directly

Skip the proxy by overriding the endpoint. The key then lives in the app, so
keep it to a throwaway one:

```bash
flutter run -d macos \
  --dart-define=OPENAI_BASE_URL=https://api.openai.com/v1 \
  --dart-define=OPENAI_API_KEY=sk-... \
  --dart-define=OPENAI_MODEL=gpt-4o-mini
```

Everything is also editable at runtime under the ⚙ settings button, with
presets for the proxy, OpenAI, Groq, OpenRouter, Ollama and LM Studio.
Whatever is entered is held in memory only — this app never writes it to disk.

Targets: macOS, iOS, Android, web. An Android emulator reaches the host
machine at `10.0.2.2`, which the default base URL already accounts for.

## When it cannot reach the proxy

Every platform blocks something by default, and the message is rarely
obvious. The error screen's **Copy error** button includes the endpoint and
platform, which is usually enough to tell these apart.

| Error | Cause | Fix |
|---|---|---|
| `SocketException: Connection failed (OS Error: Operation not permitted, errno = 1)` | macOS App Sandbox denies outgoing connections. Flutter's template grants `network.server` but not `network.client`. | Already fixed here — both `macos/Runner/*.entitlements` grant `com.apple.security.network.client`. Entitlements are applied at signing, so a **full restart** is needed; hot reload will not pick it up. |
| `Connection refused` | The proxy is not running. | `cd ../../ai-testing && OPENAI_API_KEY=sk-... npm start` |
| iOS: `App Transport Security ... cleartext` | ATS blocks plain http. | Already fixed — `NSAllowsLocalNetworking` in `ios/Runner/Info.plist` permits local hosts only. |
| Android: `Cleartext HTTP traffic not permitted` | Blocked since API 28. | Already fixed — `network_security_config.xml` permits `10.0.2.2`, `localhost` and `127.0.0.1` only. |
| Android: connection refused to `localhost` | On an emulator `localhost` is the emulator itself. | Use `http://10.0.2.2:8787/v1`, which is the default on Android. |
| Web: `XMLHttpRequest error` | CORS. | Use the proxy — it sends the headers. A browser cannot call a provider directly. |

## Measure it properly

**Run in profile mode.** A debug build spends most of every frame in
assertions and unoptimised code; frame times there say nothing about the
renderer. The metrics bar shows an ⓘ when the build is debug.

```bash
flutter run --profile -d macos --dart-define=OPENAI_API_KEY=sk-...
```

| Metric | Meaning |
|---|---|
| `ttft` | Time to first content delta — network and model, **not** rendering |
| `elapsed` | Send to end of stream |
| `chars` / `chars/s` | Markdown rendered, and the rate it arrived |
| `chunks` | Content deltas — one `GptMarkdown` rebuild each |
| `frames` | Frames produced during the stream |
| `avg` / `p95` frame | Build + raster per frame; p95 is where a stutter shows |
| `jank` | Frames over 16.7 ms, i.e. dropped at 60 Hz |

The number that matters is **p95 frame time as the reply grows**. A renderer
that re-parses the whole document per chunk degrades as the answer gets
longer; one that only rebuilds the tail stays flat.

## Issue tracker

Finding a rendering bug is easy; keeping track of one is not. The app has a
GitHub-shaped tracker built in, backed by the same SQLite file the proxy
records every request into.

**From a bad reply to a filed issue is one tap.** The 🐛 button in the app bar
opens the new-issue form with the exact Markdown that just rendered wrong
already attached, along with the id of the request that produced it. Nothing
has to be reproduced or pasted.

| Where | What |
|---|---|
| 🐛 **Report** | New issue, pre-filled with the reply on screen |
| ☑️ **Issues** | The list: Open/Closed counts, search, label and sort filters |
| 🕘 **History** | Every recorded request; open any one and file an issue from it |

An issue works the way you would expect one to:

- **Open, close and reopen**, with the green/purple state badge.
- **Comment**, in Markdown, with GitHub's Write / Preview tabs.
- **Label** it — ten are seeded (`bug`, `parser`, `latex`, `table`,
  `code-block`, `list`, `streaming`, `performance`, `enhancement`, `wontfix`).
- **A timeline** interleaving comments with closed / reopened / labeled events.

The part that makes it more than a notepad: the captured Markdown is
**re-rendered on the issue page every time you open it**. Change the parser,
reopen the issue, and the "Captured output" panel shows whether the same input
now looks right — with the source next to it to copy into a test.

The tracker lives on the proxy, so there is nothing extra to configure and
nothing extra to run: it is the same `npm start` and the same base URL. Issues
and history survive restarts, and are shared between every device pointed at
that proxy.

## What the toggles do

The ⚙ tune menu switches the renderer options live, mid-reply:

- **Incremental rendering** → `GptMarkdown(incremental: …)`. Splits the
  document into top-level segments, each cached by its source text, so
  appending text rebuilds only the tail segment. Turn it off on a long reply
  full of tables and LaTeX and watch p95 climb.
- **Fade reveal** → `animation: GptMarkdownAnimation.fade` with
  `isStreaming` and `charactersPerSecond: 300`.
- **Metrics bar** → hide the readout for a clean screenshot.

## Prompts that stress the parser

The default system prompt already asks for rich output. These push harder:

- "Explain backpropagation with the full derivation in display LaTeX."
- "Compare 6 sorting algorithms in one table, then give Dart code for each."
- "Write a deeply nested checklist for shipping a Flutter app, 4 levels deep."
- "Show me 10 code blocks in 10 different languages with commentary."

## Files

| File | Role |
|---|---|
| `lib/chat_page.dart` | The screen — full-screen `GptMarkdown` and the composer |
| `lib/openai_client.dart` | SSE streaming client for `/chat/completions` |
| `lib/chat_config.dart` | Endpoint settings and `--dart-define` defaults |
| `lib/error_report.dart` | The copyable failure view and the report it builds |
| `lib/tracker/tracker_api.dart` | Client for the proxy's issue and transcript API |
| `lib/tracker/issues_page.dart` | The issue list |
| `lib/tracker/issue_detail_page.dart` | One issue: body, captured output, timeline |
| `lib/tracker/new_issue_page.dart` | The new-issue form |
| `lib/tracker/requests_page.dart` | The request history and its detail view |
| `lib/tracker/markdown_editor.dart` | The Write / Preview Markdown field |
| `lib/render_metrics.dart` | `FrameTiming` collection and the derived stats |
| `lib/metrics_bar.dart` | The readout |
| `lib/settings_sheet.dart` | Runtime endpoint editor |

Only the current reply is rendered; the conversation is still kept so
follow-up turns have context. That keeps the surface under test what the
streaming path is designed around — one widget rendering one growing string.
