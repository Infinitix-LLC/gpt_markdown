# gpt_markdown vs other Flutter Markdown renderers

Compared against:

| package | version | what it is |
|---|---|---|
| **gpt_markdown** | 1.3.0 | this package |
| **flutter_markdown_plus** | 1.0.12 | maintained fork of Google's discontinued `flutter_markdown` |
| **flow_ui** | 0.3.0 | a chat-UI kit; `FlowMarkdown` is its renderer |
| **markdown_widget** | 2.3.2+8 | a document/reader renderer with a table-of-contents |

`flutter_markdown` itself is discontinued and points at `flutter_markdown_plus`,
so it is not compared separately.

---

## 1. Speed

**How to read the ratios.** `2.0x faster` means the other package takes twice
as long as we do. `2.0x slower` means we take twice as long as it does.

**How it was measured.** Each package ran in its own process with an identical
harness: mount the document, settle, tear down, repeat. Minimum of three runs
of three rounds of twelve mounts, with an empty-harness pump subtracted. Each
single-construct row renders that construct **ten times** in one document, so a
per-construct cost is a tenth of what the harness reports — worth remembering
before reading any one row as the cost of one heading or one code block. Debug
VM on macOS, so treat the ratios as the result and ignore the absolute
microseconds. Each package rendered identical output — same paragraph count,
same character count — so nobody is winning by drawing less.

### 1a. Drawing a finished message (cold mount)

| what is being drawn | vs flutter_markdown_plus | vs flow_ui | vs markdown_widget |
|---|---|---|---|
| **Links** | **4.5x faster** | **2.7x faster** | **7.2x faster** |
| **Bullet list** | **3.1x faster** | **4.8x faster** | **4.7x faster** |
| **Plain prose** | **2.4x faster** | **3.8x faster** | **2.8x faster** |
| **Headings** | **1.5x faster** | **3.6x faster** | **7.1x faster** |
| **Mixed answer** | 1.1x slower | **2.4x faster** | **1.5x faster** |
| **Table** (small) | 1.7x slower | **1.1x faster** | **1.6x faster** |
| **Table** (40 rows) | **1.1x faster** | — | — |
| Code block | 2.9x slower | **7.2x faster** | 2.5x slower |

Every package was run three times in one sitting, and each ratio is computed
**within a round** — our number against theirs from the same round — then the
median of the three taken. That matters more than it sounds: an earlier draft
of this table divided fresh numbers of ours by numbers of theirs measured in a
different sitting, and the machine drifted about 20% in between, which moved
two rows by more than the effects being reported. Rows whose three rounds
disagreed most are headings (0.90-1.71x) and prose (1.99-3.98x); treat those as
"we are ahead", not as a precise figure.

**Read:** we win on the things a chat reply is mostly made of — prose, links,
headings, lists — against all three. The only cold-mount losses are code blocks
(to fmp and markdown_widget) and tables (to fmp). Both gaps are explained in
§1c.

### 1b. Text arriving live (streaming)

Cost of **one more chunk** as the reply grows. This is what a chat UI pays per
token.

| reply so far | `SliverGptMarkdown` | `GptMarkdown` | flow_ui | flutter_markdown_plus | markdown_widget | empty harness |
|---|---:|---:|---:|---:|---:|---:|
| 2 KB | 3.0 ms | 4.0 ms | 2.4 ms | 21.8 ms | 20.4 ms | 2.8 ms |
| 6 KB | 1.7 ms | 4.2 ms | 2.2 ms | 25.8 ms | 29.1 ms | 1.6 ms |
| 12 KB | **1.3 ms** | 3.4 ms | 1.7 ms | 49.3 ms | 57.0 ms | 1.2 ms |
| 18 KB | **1.0 ms** | 4.3 ms | 1.6 ms | 80.2 ms | 93.0 ms | 0.9 ms |

The last column is the same harness rendering nothing at all. Subtract it to
compare renderers: at 18 KB the sliver is doing its work in **essentially the
harness floor**, flow_ui in 0.7 ms above it, the plain widget in 3.4 ms above
it, and the other two in 79 ms and 92 ms above it.

Using `SliverGptMarkdown`, at 18 KB:

| | ratio |
|---|---|
| vs flow_ui | **1.6x faster** |
| vs flutter_markdown_plus | **80x faster** |
| vs markdown_widget | **93x faster** |

Using the plain `GptMarkdown`, at 18 KB:

| | ratio |
|---|---|
| vs flutter_markdown_plus | **19x faster** |
| vs markdown_widget | **22x faster** |
| vs flow_ui | 2.7x slower |

**Read:** two different stories.

- **Against `flutter_markdown_plus` and `markdown_widget` this is not a ratio,
  it is a different shape.** Both re-render the whole reply on every chunk, so
  their cost climbs without limit — 17 ms → 70 ms and 17 ms → 88 ms, still
  rising. Ours stays flat. The longer the answer, the bigger the gap. At 18 KB
  they are dropping 4–5 frames per token; we fit inside one.
- **Which of our two widgets you use decides this.** `GptMarkdown` hands every
  block to one `Column`, so the whole document is in the tree at once.
  `SliverGptMarkdown` builds only what is on screen, so its cost *falls* as the
  reply grows past a screenful — past 12 KB it is indistinguishable from an
  empty harness. **Use the sliver for long streaming replies.**
- `flow_ui` still beats the plain `GptMarkdown`, by 2.7x, and is beaten by the
  sliver. It renders the full document either way, so its number is honest
  work, not deferral — it reuses unchanged block objects so Flutter skips their
  subtrees, and it collapses the document's semantics while streaming.

### 1c. Why we lose where we lose

| | reason | can it be fixed? |
|---|---|---|
| **Code block** vs fmp | We run syntax highlighting and draw a language label and a working copy button. fmp draws one plain `RichText`, has **no built-in highlighting at all**, and no copy button. | No — it is the feature. About half the gap is the copy button (10.8 ms against 7.1 ms for ten blocks); the rest is highlighting, which fmp simply does not do. See below. |
| **Code block** vs markdown_widget | Both highlight. Theirs uses `flutter_highlight`'s prebuilt themes and draws no language label or copy button. | Yes, by giving up the button: `CodeBlockStyle(showCopyButton: false)` halves what a code block costs. |
| **Table** vs fmp | We size columns to their content, so every cell is laid out twice: once to measure, once for real. fmp splits the width equally and measures nothing. The cost is per cell, so it shows up worst on a *small* table, where it sits on top of fixed per-table overhead. | Reduced, not removed — see below. `TableStyle.columnWidth` is meant to be the opt-out, but see the correction under it: the numbers this table once carried for that route were measuring a collapsed table. |
| **Streaming** vs flow_ui, plain `GptMarkdown` | The whole document sits in one `Column`. Measured per chunk: 2 segments rebuild, 2 re-lay-out — the cache is doing its job — but every block is still walked and painted. | Partly. Collapsing the semantics of a reply while it is still arriving cut this roughly in half (see below). For the rest, use `SliverGptMarkdown`. |

**What the copy button costs, and why it is not one widget.** Measured through
the package's own opt-out — the same document with `showCopyButton` true and
false, counterbalanced, with a duplicate variant agreeing within 5%:

| per code block | widgets | render objects |
|---|---:|---:|
| without the copy button | 48.3 | 28.1 |
| with it | 99.3 | 55.1 |

**The button doubles the code block's widget tree.** Fifty-one widgets for one
32-pixel circle, because a pressable, focusable, announceable control is a
`Tooltip` (overlay portal, timers, its own recogniser, semantics) over a
`Material` over an `InkWell` (gesture detector, listener, mouse region, focus
node, actions, ink controller, semantics) over an `AnimatedSwitcher`. Ten code
blocks cost 13.4 ms with it and 7.1 ms without; per block the delta measures
340-640 us depending on harness.

It was briefly drawn as a plain icon until a pointer arrived, which saved that
and broke three things — a keyboard user could never reach it, the first stylus
contact was swallowed, and press-and-hold meant the opposite thing before and
after. So it stays a real button, and `showCopyButton: false` is the way out for
anyone who would rather have the microseconds. Remember these are debug-VM
numbers, per *cold mount*: a settled block is not rebuilt, and a chat message
carries one or two code blocks, not ten.

**What table rendering cost.** Every cell sat in an alignment box. For a
centred or right-aligned column that box does the work; for a left-aligned one
— the default, and most columns — it does nothing a tight-width cell would not
already do, and content-sized columns lay every cell out *twice*, so the
redundant box cost two layout passes per cell plus a render object for paint to
walk. Dropping it for left-aligned columns took the table from 397 render
objects to **274** for 123 cells (flow_ui 393, fmp 503 — we are now the leanest
of the three) and cut the per-cell measurement from ~36 us to ~20 us. A 40-row
table went from 1.2x slower than fmp to **1.1x faster**.

The catch, and why it needed a regression test: a cell that is not in an
alignment box fills its column, so its own `textAlign` is what places the
glyphs. A caller who had set `textAlign` globally would have had it silently
override what the table's own `|:--|` syntax asked for. The column's alignment
is now pinned — and only when the caller set one, so an ordinary table
allocates nothing for it.

**What list rendering cost.** A bullet item was a `Row` holding a padded
marker box and a `Flexible` child — seven render objects per item to draw one
dot, plus two more from the flex wrapper every block carried. Paint walks all
of them on every frame, even where a viewport clips them, so a streaming reply
paid for them on every chunk. Drawing the marker directly in one hanging-indent
render object took a list item from **9.8 render objects to 2.6**, the same
order as a plain paragraph. Every block's measured width and height is
unchanged to the pixel. Lists now cost what prose costs: 2.79 ms against
2.86 ms per chunk at 12 KB, where before the fixes below they were 13.67 ms
against 4.82 ms.

**What the streaming cost actually was.** Per chunk, at 12 KB, the segment
cache returned 277 of 279 blocks unchanged, only 2 blocks re-laid-out, and the
number of widgets rebuilt was the same as flow_ui's (149 vs 153). Almost none
of the cost was our own code. It was **semantics**: every block already on
screen re-published its accessibility node on every frame. Collapsing the reply
into a single semantics node while text is still arriving — which is also
better for anyone actually listening, who was getting an announcement storm —
took the per-chunk cost from 2.30 ms to 1.10 ms on a prose document, measured
counterbalanced in one process against an identical control variant that agreed
within 4%.

Two further things were tried and **made it worse or nothing**, recorded to
save the next person the trip:

- a `RepaintBoundary` per block — it does remove the repaints (183 per chunk
  down to 2), and it is *slower*: painting an off-screen paragraph that is
  already shaped is nearly free, and a few hundred composited layers are not;
- replacing the gap widgets with `Flex.spacing` — halves the child count, and
  changes the measured time by less than the noise. Kept anyway, because less
  work for the same result is still less work.

**Correction: the flex-column measurements in an earlier draft were wrong.**
This document previously reported that setting `TableStyle.columnWidth` to
`FlexColumnWidth()` "measures nothing and lands level with fmp or ahead of it",
with numbers to match. Those numbers were real but they were measuring nothing
useful: a table sits inside a horizontal scroll view, so it is laid out against
an unbounded width, and a flex column has no finite width to take a share of.
The table collapses. Measured on a two-row table at 600 logical pixels:

| `columnWidth` | table size |
|---|---|
| unset (content-sized) | 174.5 x 84.0 |
| `FlexColumnWidth()` | **0.0 x 304.0** |
| `IntrinsicColumnWidth()` | 174.5 x 84.0 |
| `FixedColumnWidth(120)` | 240.0 x 84.0 |

So a "faster" flex table was a table drawn zero pixels wide with every cell
wrapped to one character per line. The lesson is the one this document keeps
relearning: a performance number means nothing until you have checked that both
sides rendered the same thing.

And on the table, two things that were tried and did not help:

- asking for intrinsic sizes instead of laying cells out — slower, because the
  paragraph lays the text out either way and the table still lays the cell out
  afterwards;
- caching the column-width object — no effect, because the segment cache
  already skips unchanged tables.

---

## 2. Features

`YES` = supported. `PART` = partly, see the note. `NO` = not supported.

### 2a. Where we are ahead

| feature | us | fmp | flow_ui | markdown_widget |
|---|---|---|---|---|
| **LaTeX / maths** | YES, inline and block | NO | NO | NO |
| **Built-in syntax highlighting** | YES, ~190 languages | PART — you write it | YES, 9 languages | YES, via `flutter_highlight` |
| **Streaming flag** | YES | NO | YES | NO |
| **Incremental re-render** | YES | NO | YES | NO |
| **Character reveal animation** | YES | NO | YES | NO |
| **Block entrance animation** | PART — widget blocks only | NO | PART — same | NO |
| **Sliver / lazy rendering** | PART — real sliver, lazy per block | PART — `ListView`, parses all first | NO | PART — `ListView`, parses all first |
| **Task list checkboxes** | YES, optionally tappable | PART — renders, not tappable | NO — literal `[ ]` | PART — renders, not tappable |
| **Images, size from alt text** | YES | PART — no alt sizing | NO — renders as text | PART — no alt sizing |
| **Custom inline syntax** | YES — patterns + directives | YES — full parser access | NO | YES — node generators |
| **Bidi placeholder fix** | YES | NO | NO | NO |
| **Autolinks** | YES — GFM + angle + custom schemes | YES | PART — no email | YES |
| **Code copy button** | YES | NO | YES | NO |

### 2b. Where they are ahead

| feature | us | fmp | flow_ui | markdown_widget |
|---|---|---|---|---|
| **Per-chunk streaming cost** | **falls to ~1.0 ms** with the sliver; flat ~3-4 ms without | grows, no limit | flat ~1.6 ms | grows, no limit |
| **Default text direction** | LTR until you pass it | — | **follows `Directionality`** | — |
| **Footnotes** | NO | **YES** | NO | NO |
| **Any-HTML-tag builders** | NO — fixed hooks | **YES — any tag** | NO | **YES — any node** |
| **Built-in `selectable:` flag** | NO — wrap in `SelectionArea` | **YES** | always on | **YES** |
| **Table of contents** | NO | NO | NO | **YES — with scroll sync** |
| **Style sheet size** | many style objects | **57 fields, per tag** | 16 fields | per-node configs |
| **Package size** | 15,800 lines | **2,800 lines** | 18,000 (whole chat kit) | **2,450 lines** |
| **Dependencies** | 2 | **3, all tiny** | 3, incl. `google_fonts` | 3 |

### 2c. Roughly equal

| feature | note |
|---|---|
| Tables + column alignment | all four |
| Lists, nesting, `start` number | all four |
| Blockquotes, nested | all four |
| Strikethrough | all four |
| Horizontal rules | all four |
| Link tap callback | all four; none launch URLs for you |
| Text selection | all four, by different routes |
| System text scaling | us, fmp, flow_ui |

---

## 3. Which to pick

**gpt_markdown** — an LLM chat app. You get maths, real syntax highlighting,
streaming that stays flat as the reply grows, and the widest extension surface.
Best on prose, links, headings and lists, which is most of a reply. **For a long
streaming reply use `SliverGptMarkdown`** — it is the fastest of the four per
chunk. The plain widget is now within 2.7x of flow_ui rather than 5.1x, which
is comfortably inside a frame for a normal-length message.

Where you pay for it is code blocks and small tables.
`CodeBlockStyle(showCopyButton: false)` halves a code block. For tables the
opt-out is `TableStyle.columnWidth`, but pick the policy carefully — see the
correction in §1c. Leave
them on unless a profile says otherwise — a chat reply carries one or two code
blocks, not the ten these benchmarks stack up.

**flutter_markdown_plus** — a document viewer, not a chat. Smallest and
simplest by far (2,800 lines), the most granular style sheet, footnotes, and
builders for any HTML tag. Avoid it for streaming: cost grows with the length of
the text and does not level off.

**flow_ui** — you want a whole chat UI, not a renderer, and you do not need
maths or images. Its per-chunk streaming cost beats our plain widget, though not
our sliver. Its cold mount is the slowest, badly so for code blocks.

**markdown_widget** — a long document someone reads and scrolls: it is the only
one with a table of contents wired to the scroll position, and it is the
smallest of the four. Not for chat — no streaming flag, no incremental render,
and per-chunk cost grows faster than any other package here.

---

## 4. Honest caveats

- Debug VM, macOS, one machine. Ratios travel; microseconds do not.
- **`flutter test` always runs the accessibility pipeline**, whether or not the
  flag says otherwise — a real app runs it only when a screen reader is
  attached. So every number here is the screen-reader-on case, and a typical
  user pays less than the table says. This matters because it was hiding a real
  cost of ours: see §1c.
- Cold-mount and streaming numbers come from **different harnesses** and are not
  comparable to each other, only within their own table.
- Feature rows were read from each package's source, not its README, and then
  re-checked by a second pass. That pass corrected four claims in the first
  draft, including one where we had ourselves the right way round on RTL and
  were in fact behind.
- `flow_ui` is a chat kit. Comparing only its renderer is fair for this document
  and unfair to the package.

---

## 5. Against our own 1.2.1

The tables above compare this package with other packages. This one compares it
with itself: tag `v1.2.1`, the last release, against the working tree — and the
two widgets the working tree offers, `GptMarkdown` and `SliverGptMarkdown`.

**Mostly end-to-end renders.** Every figure in §5a and §5b is a real frame —
parse, build, layout and paint — with each iteration mounting the widget,
settling it, tearing the tree down and mounting it again cold. §5c splits that
apart, reporting the parse stage on its own beside the whole frame, because
"how much faster is the parser" and "how much faster is a render" have very
different answers.

**How it was measured.** All three renderers in **one process**. v1.2.1 was
extracted from the tag into a second package under a different name so a single
test can mount both versions at once — cross-process comparison drifts about
20% on this machine, which is larger than several of the effects reported here,
and an earlier draft of §1 got two rows wrong exactly that way. Order is
counterbalanced, each figure is the minimum of several rounds, and an empty
harness is subtracted. Every run also mounts `GptMarkdown` a second time as a
**duplicate control**: two byte-identical variants that disagree by more than a
few percent mean the run is noise, and rows where that happened are marked †.

**The viewport is 800x600, and it matters.** All three sit in an identically
sized viewport — the two box renderers in a `SingleChildScrollView`, the sliver
in a `CustomScrollView`. The sliver's entire claim is that it builds only what
is on screen, so its numbers are a function of that size. A taller viewport
moves them.

### 5a. Cold mount, by document length

Time above the harness floor. One unit is a heading, a wrapping
paragraph with bold, inline code and a link, and a two-item list — about a
third of a screen.

| document | 1.2.1 | `GptMarkdown` | vs 1.2.1 | `SliverGptMarkdown` | vs 1.2.1 | sliver vs `GptMarkdown` |
|---|---:|---:|---|---:|---|---|
| 1 unit † | 2.14 ms | 1.39 ms | **1.5x faster** | 1.38 ms | **1.6x faster** | level (1.0x) |
| 4 units | 4.13 ms | **1.88 ms** | **2.2x faster** | 3.07 ms | 1.3x faster | **1.6x slower** |
| 20 units | 16.82 ms | 4.97 ms | **3.4x faster** | **2.33 ms** | **7.2x faster** | **2.1x faster** |
| 60 units | 54.90 ms | 13.45 ms | **4.1x faster** | **2.09 ms** | **26x faster** | **6.4x faster** |

**Read:** `GptMarkdown` is faster than 1.2.1 at every length, and the gap widens
with the document because 1.2.1 grows faster than linearly. The sliver is the
more interesting column: at **4 units it is 1.6x *slower* than the plain
widget**, because a `CustomScrollView` and a lazy sliver cost more to set up
than a four-screen document costs to draw. It overtakes at around 20 units and
then flattens — 60 units costs it barely more than 20, because everything past
the first screen is never built.

### 5b. Streaming, by reply length

Cost of one more chunk as the reply grows. Same viewport.

Run twice, because the headline numbers here are large enough to deserve it.
Both runs are shown as a range, and each ratio is the **more conservative of
the two**.

| reply so far | 1.2.1 | `GptMarkdown` | vs 1.2.1 | `SliverGptMarkdown` | vs 1.2.1 | sliver vs `GptMarkdown` |
|---|---:|---:|---|---:|---|---|
| 2 KB † | 5.3-7.5 ms | 0.7-2.0 ms | 3.8x faster | 0.69-0.95 ms | **7.6x faster** | **2.1x faster** |
| 6 KB | 14.1-17.1 ms | 0.80-1.09 ms | **16x faster** | **0.49-0.75 ms** | **23x faster** | **1.5x faster** |
| 12 KB | 32.0-38.4 ms | 1.01-1.24 ms | **31x faster** | **0.42-0.52 ms** | **74x faster** | **2.4x faster** |

**Read:** against 1.2.1 this is not a ratio, it is a different shape. 1.2.1
re-parses and re-renders the whole reply on every chunk, so its cost climbs
without limit — 5 ms to 38 ms and still rising. Both current widgets stay flat,
and the sliver's cost *falls* as the reply grows past a screenful, because the
share of it that is on screen keeps shrinking.

The 31x at 12 KB reproduced closely across both runs (31.0x and 31.6x). The
2 KB row did not — 7.4x and 3.8x, with a duplicate control 62% apart in the
second run — so it is marked and reported at its worst. At 2 KB the per-chunk
cost is near the harness floor, which is where this method stops resolving.

**Both sides were checked for rendering the same document**, because a
"faster" variant that quietly draws less is the failure mode this document has
already hit once. At 12 KB the two trees differ in shape — 547 `RichText`s
against 364, and 1181 more characters on the 1.2.1 side — but that difference is
entirely `U+FFFC` placeholders: 1.2.1 wraps blocks and links in widget spans, so
its text lives in nested paragraphs and reads back out of order. Rendered height
agrees within 2.5%, the visible words are identical, and neither renderer defers
work past the frame the clock stops in.

### 5c. Parse stage and whole frame, separately

Two different questions, so two measurements. **Parse** is source to
`List<InlineSpan>` — both versions expose one call taking a `BuildContext`, a
string and a config and returning spans, so this is like for like: parsing plus
inline span construction, no layout, no paint. **Whole frame** is a real cold
mount: parse, build, layout and paint, torn down and remounted each iteration.

Documents are shaped like things people send. A document of N copies of one
construct measures block count, which is the dominant term for the new
pipeline, so repetition would answer the wrong question.

| document | parse 1.2.1 | parse now | | whole frame 1.2.1 | whole frame now | |
|---|---:|---:|---|---:|---:|---|
| short reply | 0.49 ms | 0.23 ms | **2.1x faster** | 7.57 ms | 5.45 ms | **1.4x faster** |
| long reply (5x) | 1.75 ms | 0.64 ms | **2.7x faster** | 25.80 ms | 13.22 ms | **2.0x faster** |
| document (20x) | 6.63 ms | 2.21 ms | **3.0x faster** | 94.34 ms | 54.73 ms | **1.7x faster** |
| prose reply † | 1.38 ms | 0.47 ms | **2.9x faster** | 1.54 ms | 0.89 ms | **1.7x faster** |
| prose, long form | 6.20 ms | 2.27 ms | **2.7x faster** | 9.47 ms | 5.23 ms | **1.8x faster** |

**Read:** faster in both stages on every document — parsing 2.1x to 3.0x,
whole frames 1.4x to 2.0x. The duplicate control sat at 0-5% on every row but
one (the prose reply's frame, 18%, where the document is small enough that the
numbers approach the harness floor).

The frame ratio is lower than the parse ratio because parsing is not where the
time goes. On a reply with structure in it — headings, lists, a table, a fence —
the parse is about **4%** of the frame; the other 96% is building widgets,
laying them out and painting them. Making the parser three times faster moves
a twenty-fifth of the work, which is why the frame numbers are 1.4x-2.0x and not
3x.

On plain prose the split is different: parse is 43-53% of the frame, because
there is almost nothing to lay out. That is the one shape where parser work
dominates, and it is also the shape with the least total work to do.

### 5d. Which widget, given the above

- **A chat message, a card, anything up to a few screens** — `GptMarkdown`. The
  sliver costs more than it saves below about 20 units, and it has to live in a
  `CustomScrollView`.
- **A long reply, a document, anything well past a screenful** — 
  `SliverGptMarkdown`. It is 6x the plain widget at 60 units and its streaming
  cost falls rather than rises.
- **Upgrading from 1.2.1 and changing nothing** — everything gets faster, in
  both stages, on every document shape measured here.

### 5e. Caveats particular to this comparison

- v1.2.1 is measured under a renamed package. Its Dart source is byte-identical
  to the tag; only the package name and its own internal imports were rewritten
  so both versions could be loaded at once.
- Both versions resolve the same bundled monospace font, so the code rows are
  not measuring a font substitution.
- † marks a row whose duplicate control disagreed by more than about 15%: the
  1-unit row in §5a (34%) and the prose reply's frame in §5c (18%). Both are
  small documents, where the measurement approaches the harness floor. Read them
  as directional. Every other row sat at 0-13%.
- Debug VM, macOS, one machine, and `flutter test` always runs the accessibility
  pipeline — see §4. Ratios travel; microseconds do not.
