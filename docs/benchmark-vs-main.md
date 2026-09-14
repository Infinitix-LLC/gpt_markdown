# Committed branch versus upstream main

Compared `feature/parser` commit **32998d0** with freshly fetched `origin/main`
commit **034e9c0**. The stale local `main` at `f302e68` was not used. Both renderer
sources were taken from committed Git archives, independent of the working tree.
This is a different baseline from the earlier comparisons against `5f92914`.

| Scenario | Main (ms) | Committed branch (ms) | Main / branch |
| --- | ---: | ---: | ---: |
| Short mixed answer, cold mount | 1.897 | 1.468 | **1.29x** |
| Long mixed answer, cold mount | 10.727 | 7.696 | **1.39x** |
| Math answer, cold mount | 1.922 | 1.427 | **1.35x** |
| Streaming without animation | 3.466 | 0.589 | **5.89x** |
| Streaming with animation enabled | 0.554 | 0.520 | **1.07x** |
| Long answer, sliver first viewport | 10.727 | 2.016 | **5.32x** |

Values are medians of four rounds' median UI-plus-raster work per frame. A larger
ratio means less rendering work on the committed branch. UI and raster threads
can overlap: these are **not FPS ratios or end-to-end response latency**.

For animated streaming, median-of-rounds **p95 UI duration** fell from
**2.367 ms to 0.565 ms (4.19x)**. This captures the reduction in expensive
frames better than its typical-frame ratio. It is a separate metric from the
table's combined median work. One main animated frame exceeded a 16.667ms UI or
raster budget; none of the branch or sliver frames did. Both generally met the
60 Hz budget on this Mac, so the ratios do not imply an equivalent visible FPS gain.

## Scope and limitations

- This measures the full branch-to-main change, including earlier work on this
  branch, not only the latest performance refactor.
- Both packages receive the same source, text style, input chunks, and animation
  flag. Their output and internals are not identical: main renders code as plain
  text, while the branch highlights supported languages and has a different code
  header. Main animates source substrings; the branch reveals rendered spans.
  Animated ratios therefore compare package behavior, not identical per-frame
  visible characters or effects.
- The sliver ratio measures first-viewport work plus its default cache extent;
  offscreen blocks are deferred until scrolling. It does not describe the cost of
  rendering or scrolling through the entire answer. Sliver streaming was excluded
  because it does not implement the same character-reveal behavior.
- Runs used a native macOS profile build, Flutter 3.44.2 / Dart 3.12.2, at 560
  logical pixels wide in the unmodified example window. The scroll position stayed
  at the top. SelectionArea was mounted, but pointer/focus input was blocked.
  There were no network images or model calls, and no framework errors occurred.
- Mobile, web, scroll-through, and interactive selection need separate measurements.

## Reproduction and evidence

The fixture and timing loop are in
[profile_rendering.dart](../tool/benchmarks/profile_rendering.dart) at commit
`32998d0`. Short, long, and math inputs contain 1,485, 8,920, and 845 characters.
Each cold workload warms up with eight mounts, then measures forty fresh mounts
per round. Streaming appends 48 characters each frame without animation, or each
three frames with animation, then ends streaming and allows the animation to
settle. FrameTiming batches are drained for 350ms around measurements.

An isolated example app imported both package snapshots. Main's package name
and self-import URIs were renamed to `gpt_markdown_main`; renderer logic was
unchanged. Font package references stayed unchanged, and Git confirms the font
assets are identical between commits. The same SDK and resolved dependencies
were used in one process. Workloads run adjacent for each variant, reversing the
variant order every other round. No other tests or builds ran during measurement.

The adapter supplied a third SliverGptMarkdown builder and CustomScrollView
viewport, and skipped that variant for streaming scenarios. It ran with:

```sh
flutter run -d macos --profile --no-pub --dart-define=BENCH_ROUNDS=4 \
  -t lib/profile_main.dart
```

[Raw results and adapter source](../tool/benchmarks/profile_vs_main_results.json)
contain all 52 per-round records, separate UI/raster medians and p95 timings,
frame counts, exact commit IDs, and the temporary harness adjustment. The
comparison app was temporary; no runtime package code or dependencies were changed.
