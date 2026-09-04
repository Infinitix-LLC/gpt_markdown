part of '../gpt_markdown.dart';

/// The vertical space between two top-level blocks.
///
/// Approximates the "\n\n" paragraph break of the single-text pipeline: one
/// empty line of the default 1.15 line height. Scaled like the text it
/// separates, so the gap does not shrink relative to the type when a reader
/// raises their font size.
///
/// Shared, not duplicated: [_IncrementalMdView] puts it between its own
/// segments, and [GptMarkdown] hands the same value to [StreamingMarkdown] for
/// the seam between the settled prefix and the live tail. Those two have to
/// agree, or content moves when the seam does.
double blockGap(BuildContext context, GptMarkdownConfig config) {
  final scaler = config.textScaler ?? MediaQuery.textScalerOf(context);
  return scaler.scale((config.style?.fontSize ?? 14) * 1.15);
}

/// Incremental (segment-cached) Markdown view, and the streaming reveal.
///
/// The document is split into top-level segments ([splitStreamSegments]) and
/// each renders as its own `Text.rich` in a column, cached by its source text.
/// Appending to the reply only rebuilds the tail segment — earlier segments
/// keep their exact widget instances, so Flutter skips rebuilding and
/// re-laying-out everything above (LaTeX, tables, lists…) and per-chunk cost
/// stays constant instead of growing with answer length.
///
/// ## The reveal
///
/// When [effect] is animating, this widget also owns the reveal: a ticker, a
/// [RevealEngine], and the per-frame restyling of the characters still
/// arriving.
///
/// It reveals over *spans*, not over the source. Slicing the Markdown source
/// and re-rendering the prefix every frame reparses the tail on every tick and
/// can only ever produce a hard cut — once there are spans the character
/// boundaries are gone. Here the segment's spans are rendered once per text
/// change and cached; a frame's whole job is restyling at most
/// [RevealEngine.fadeWindow] characters in the one segment the reveal head is
/// inside. Every segment behind it is already settled and returns its cached
/// widget untouched.
///
/// Segments beyond the head are not built at all, so the document ends where
/// the animation is and nothing appears below the reading position before it
/// is meant to be seen.
class _IncrementalMdView extends StatefulWidget {
  const _IncrementalMdView({
    required this.text,
    required this.config,
    this.effect = GptMarkdownAnimation.none,
    this.blockAnimation = GptMarkdownBlockAnimation.none,
    this.isStreaming = false,
    this.revealing = false,
    this.charactersPerSecond = 300,
    this.revealFadeSeconds = 0.25,
    this.blockAnimationDuration = const Duration(milliseconds: 200),
    this.blockAnimationCurve = Curves.easeOut,
    this.holdMathDollars = false,
  });

  final String text;
  final GptMarkdownConfig config;

  /// How each character arrives.
  final GptMarkdownAnimation effect;

  /// How a block containing a laid-out widget enters.
  final GptMarkdownBlockAnimation blockAnimation;

  /// Whether more text may still arrive.
  final bool isStreaming;

  /// Whether to reveal progressively at all. False renders the whole document
  /// at once, with no ticker and no per-character work.
  final bool revealing;

  final double charactersPerSecond;
  final double revealFadeSeconds;
  final Duration blockAnimationDuration;
  final Curve blockAnimationCurve;

  /// Whether `$…$` in the source is maths, so the reveal holds an unpaired
  /// `$` instead of showing it as prose it will not stay.
  final bool holdMathDollars;

  @override
  State<_IncrementalMdView> createState() => _IncrementalMdViewState();
}

class _IncrementalMdViewState extends State<_IncrementalMdView>
    with SingleTickerProviderStateMixin {
  /// Rendered spans per segment source. Spans, not widgets: the reveal
  /// restyles them every frame, and re-rendering to get them back would put
  /// the parser in the frame loop, which is the cost this whole design exists
  /// to avoid.
  final Map<String, List<InlineSpan>> _spans = {};

  /// Fully settled segment paragraphs, built once and handed back by
  /// identity. The entrance wrapper is applied outside the cache: it is keyed
  /// by position, and two identical segments — two rules, say — share one
  /// cached paragraph but must not share one keyed wrapper.
  final Map<String, Widget> _settled = {};

  late RevealEngine _engine = RevealEngine(
    fadeSeconds: widget.revealFadeSeconds,
  );
  Ticker? _ticker;
  Duration _lastElapsed = Duration.zero;

  /// Rendered characters in the whole visible document, from the last build.
  /// The ticker aims at this; a build refreshes it before the next tick.
  int _total = 0;

  /// Whether the reveal should jump straight to the end on the next build.
  ///
  /// Deferred to a build because the target is a property of the *rendered*
  /// document, and nothing has been rendered yet when the state is created.
  /// Always set at mount: whatever the document already holds when this state
  /// is created — history, a re-opened conversation, a message a lazy list
  /// disposed and re-inflated mid-scroll — has been seen, and must appear
  /// whole rather than type itself out again. Only text that arrives *after*
  /// mount animates. (Streaming flags are no help here: `isStreaming` is
  /// commonly still true for a message scrolled back to during a live reply,
  /// and replaying its whole reveal from nothing blanked it for half a
  /// second.)
  bool _snapPending = true;

  /// Rendered characters already present when this state mounted.
  ///
  /// Segments that lie entirely below this were on screen before this element
  /// existed, so they skip their block entrance. Without it, every trip
  /// through a lazy list's cache boundary replayed every table and fence from
  /// opacity zero.
  int _mountOffset = 0;

  /// Releases the inline hold when the stream goes quiet without closing.
  ///
  /// A host that forgets to flip `isStreaming` off after the last chunk would
  /// otherwise leave the final characters behind an unclosed delimiter hidden
  /// forever — the hold only releases when more text arrives, and no more
  /// text is coming. Any new text disarms and re-arms it.
  Timer? _holdRelease;
  bool _holdExpired = false;

  /// High-water mark of the inline hold, as an offset into the whole source.
  ///
  /// The hold can ask to move backwards: `[the docs]` closes and reveals as
  /// prose, then `(` arrives and the whole construct is pending again.
  /// Un-showing text a reader has already read is worse than restyling it
  /// when the construct finally closes, so the hold only ever advances.
  int _holdHighWater = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Theme or other inherited data changed: cached spans and widgets baked in
    // the old values, so drop them.
    _dropCaches();
  }

  @override
  void didUpdateWidget(covariant _IncrementalMdView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text) {
      _holdRelease?.cancel();
      _holdRelease = null;
      _holdExpired = false;
    }
    if (!oldWidget.config.isSame(widget.config)) {
      _dropCaches();
    }
    if (widget.revealFadeSeconds != oldWidget.revealFadeSeconds) {
      _engine = RevealEngine(fadeSeconds: widget.revealFadeSeconds);
    }

    if (!widget.revealing) {
      _stopTicking();
      _engine.snapToEnd(_total);
      return;
    }

    final extended =
        widget.text.length >= oldWidget.text.length &&
        widget.text.startsWith(oldWidget.text);
    if (!extended) {
      final limit = min(widget.text.length, oldWidget.text.length);
      var shared = 0;
      while (shared < limit &&
          widget.text.codeUnitAt(shared) == oldWidget.text.codeUnitAt(shared)) {
        shared += 1;
      }
      // An edit confined to the tail is a rewrite, not a new reply — the
      // `$…$` → `\(…\)` conversion completing, most likely. The reveal
      // carries on from where it is; resetting here blanked the whole message
      // for a frame and re-typed it on every equation that closed. The
      // tolerance matches the longest run the inline hold can be keeping
      // hidden ([markupDelimiterHold]), because that hold is exactly what
      // confines the rewrite to unseen text.
      final tailEdit =
          shared > 0 &&
          oldWidget.text.length - shared <= markupDelimiterHold + 8;
      if (!tailEdit) {
        // A regenerate or a branch switch replaces the text rather than
        // extending it; continuing from the old offset would be meaningless,
        // and the new reply is genuinely unseen, so entrances play again.
        _engine.reset();
        _mountOffset = 0;
        _holdHighWater = 0;
        _startTicking();
        return;
      }
    }

    if (widget.isStreaming) {
      _engine.clearFastForward();
      _startTicking();
    } else if (oldWidget.isStreaming) {
      // The reply finished. Nothing more is coming, so land the remainder
      // quickly instead of making the reader wait at the baseline rate.
      _engine.beginFastForward();
      _startTicking();
    }
  }

  @override
  void dispose() {
    _holdRelease?.cancel();
    _ticker?.dispose();
    super.dispose();
  }

  void _dropCaches() {
    _spans.clear();
    _settled.clear();
  }

  void _startTicking() {
    if (_ticker?.isActive ?? false) {
      return;
    }
    _ticker ??= createTicker(_onTick);
    _lastElapsed = Duration.zero;
    _ticker!.start();
  }

  void _stopTicking() {
    if (_ticker?.isActive ?? false) {
      _ticker!.stop();
    }
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _lastElapsed).inMicroseconds / 1e6;
    _lastElapsed = elapsed;
    if (dt <= 0) {
      return;
    }
    setState(() {
      final keepGoing = _engine.tick(dt, _total, widget.charactersPerSecond);
      if (!keepGoing) {
        _stopTicking();
      }
    });
  }

  List<InlineSpan> _spansFor(BuildContext context, String segment) {
    return _spans[segment] ??= PlusparseRenderer.render(
      context,
      segment,
      widget.config,
    );
  }

  /// Wraps [spans] as a root paragraph.
  ///
  /// `isRoot` matters: without it the text renders at `TextScaler.noScaling`
  /// and a raised system font size has no effect at all.
  Widget _paragraph(List<InlineSpan> spans) => widget.config.getRich(
    TextSpan(children: spans, style: widget.config.style?.copyWith()),
    isRoot: true,
  );

  /// Whether the character reveal cannot animate this segment's content, so a
  /// block entrance has to stand in for it.
  ///
  /// The renderer wraps block-level constructs — headings, lists, quotes,
  /// tables, fences, block maths, rules, images — in widget spans, and a
  /// widget span is one opaque character to the reveal. Those arrive whole
  /// however the reveal is configured, which is a step change in layout unless
  /// something eases them in.
  ///
  /// The test is whether any *text* survives to be revealed, not whether a
  /// widget is present anywhere. A paragraph holding a link or inline maths
  /// contains a widget span too, but its prose still reveals character by
  /// character — giving it an entrance as well would play two animations over
  /// the same content. Measured across every construct the renderer emits,
  /// content the reveal can reach carries an order of magnitude more text than
  /// placeholders, and content it cannot carries essentially none.
  static bool _isAtomic(List<InlineSpan> spans) {
    var text = 0;
    var placeholders = 0;
    void walk(InlineSpan span) {
      // A revealable block publishes the text inside its widget; that text is
      // what the reveal will animate, so it is what decides this. Walking its
      // rendered children instead would find only the opaque widget and
      // conclude — wrongly — that a heading or a list item cannot be revealed.
      if (span is RevealableSpan) {
        span.content.forEach(walk);
        return;
      }
      if (span is! TextSpan) {
        placeholders += 1;
        return;
      }
      text += span.text?.length ?? 0;
      span.children?.forEach(walk);
    }

    spans.forEach(walk);
    return placeholders > 0 && text <= placeholders;
  }

  /// The segments to show, with the tail trimmed back to markup that has
  /// finished arriving.
  ///
  /// A construct is literal text until its closing delimiter lands, so
  /// revealing characters the moment they arrive means showing them in the
  /// wrong form and restyling them a moment later — `` `npm install` `` turns
  /// monospace after the reader has already read it, and the line reflows
  /// around the chip. Holding the head behind the unterminated construct costs
  /// a little latency and means every character is final when it appears.
  ///
  /// Only the last segment can be incomplete, and only while more is coming.
  /// A fence or block maths is left alone: those are opaque to begin with, and
  /// [splitStreamSegments] already keeps them whole.
  List<String> _visibleSegments(String source, List<String> segments) {
    if (!widget.isStreaming ||
        !widget.revealing ||
        _holdExpired ||
        segments.isEmpty) {
      return segments;
    }
    final last = segments.last;
    final opener = last.trimLeft();
    // Block maths is opaque: whole or nothing. An unterminated `\[` hands
    // partial tex to the renderer, which paints the raw source on any cut
    // landing mid-command — the equation flickered rendered <-> raw several
    // times while it streamed. So a closed block shows and an open one waits.
    if (opener.startsWith(r'\[')) {
      if (last.contains(r'\]')) {
        return segments;
      }
      _armHoldRelease();
      return segments.sublist(0, segments.length - 1);
    }
    // An open fence streams as itself — its backticks are not inline
    // delimiters, and its body must not be withheld.
    if (_hasOpenFence(last)) {
      return segments;
    }
    // Fences that have already closed are opaque to the inline scanner too:
    // only the prose after the last one is scanned, or a closed fence's
    // backticks would be read as inline code and the prose after it would
    // stream unheld.
    final scanFrom = _afterLastFence(last);
    var safe =
        scanFrom +
        inlineSafeLength(
          last.substring(scanFrom),
          holdMathDollars: widget.holdMathDollars,
        );
    // The hold never moves backwards. Offsets are kept against the whole
    // source so the mark survives the tail segment closing and a new one
    // opening.
    final tailStart = source.lastIndexOf(last);
    if (tailStart >= 0) {
      final floor = _holdHighWater - tailStart;
      if (floor > safe) {
        safe = min(floor, last.length);
      }
      _holdHighWater = tailStart + safe;
    }
    if (safe >= last.length) {
      return segments;
    }
    _armHoldRelease();
    final trimmed = last.substring(0, safe);
    final out = segments.sublist(0, segments.length - 1);
    if (trimmed.trim().isNotEmpty) {
      out.add(trimmed);
    }
    return out;
  }

  /// Arms the quiet-stream release, once per stretch of unchanged text.
  void _armHoldRelease() {
    _holdRelease ??= Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _holdExpired = true);
      }
    });
  }

  /// Whether [segment] contains a fence that has not closed yet.
  ///
  /// The same naive toggle [splitStreamSegments] uses, so the two always
  /// agree about what is inside a fence.
  static bool _hasOpenFence(String segment) {
    var open = false;
    for (final line in segment.split('\n')) {
      if (line.trimLeft().startsWith('```')) {
        open = !open;
      }
    }
    return open;
  }

  /// Offset just past the last line that closes a fence in [segment], or 0.
  static int _afterLastFence(String segment) {
    var open = false;
    var after = 0;
    var offset = 0;
    for (final line in segment.split('\n')) {
      final lineEnd = offset + line.length;
      if (line.trimLeft().startsWith('```')) {
        open = !open;
        if (!open) {
          after = lineEnd < segment.length ? lineEnd + 1 : segment.length;
        }
      }
      offset = lineEnd + 1;
    }
    return after;
  }

  /// Wraps [child] in its one-shot entrance, when the segment has one.
  ///
  /// Keyed by position, not by text: the tail's source changes with every
  /// chunk, and a text key would remount the entrance and replay it on every
  /// keystroke. Position is append-only while a reply grows, so the key holds
  /// exactly as long as the block does.
  ///
  /// A segment already on screen when this state mounted plays nothing: its
  /// reader has seen it, and a lazy list re-creating this state on scroll
  /// must not replay what did not move.
  Widget _entrance(int index, int start, List<InlineSpan> spans, Widget child) {
    if (widget.blockAnimation == GptMarkdownBlockAnimation.none ||
        start < _mountOffset ||
        !_isAtomic(spans)) {
      return child;
    }
    return GptMarkdownBlockEntrance(
      key: ValueKey<int>(index),
      animation: widget.blockAnimation,
      duration: widget.blockAnimationDuration,
      curve: widget.blockAnimationCurve,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Already masked by `GptMarkdown`, so a directive is inert text here and
    // cannot be split across segments.
    // Masked before segmentation so a match can never be split across
    // segments, and before parsing so it beats the built-in reading of the
    // same text. Directives are already masked by `GptMarkdown`.
    final patterns = widget.config.inlinePatterns;
    final source =
        patterns == null || patterns.isEmpty
            ? widget.text
            : maskInlinePatterns(widget.text, patterns);
    final segments = _visibleSegments(source, splitStreamSegments(source));
    final gap = blockGap(context, widget.config);

    // Rendered-character extents, and the running total the ticker aims at.
    // Every segment is measured even when it will not be shown: the target has
    // to be the whole visible document, or the reveal stops at whatever
    // happens to be on screen. Measuring is a parse, which is cached — it is
    // not a layout.
    final spans = <List<InlineSpan>>[];
    final starts = <int>[];
    var offset = 0;
    for (final segment in segments) {
      final rendered = _spansFor(context, segment);
      spans.add(rendered);
      starts.add(offset);
      offset += countRevealCharacters(rendered);
    }
    _total = offset;

    // A reader who has already seen this reply should not watch it type
    // itself out again — and the blocks it contains have no entrance left to
    // make.
    if (_snapPending) {
      _snapPending = false;
      _mountOffset = _total;
      _engine.snapToEnd(_total);
    }

    // Reduced motion is a preference about movement, not about content: the
    // document still renders, it just renders whole.
    final revealing =
        widget.revealing && !MediaQuery.disableAnimationsOf(context);
    // Once the last character has finished arriving there is nothing to style,
    // and the document should be exactly what it would have been without an
    // animation — one span per run, not one per character. Anything else keeps
    // a finished reply shaping as hundreds of separate runs, which moves its
    // wrapping and breaks a construct that styles a continuous stretch.
    final settled = _engine.revealedFloor >= _total && !_engine.tailStillFading;
    final fading = revealing && widget.effect.animatesCharacters && !settled;
    final revealed = revealing ? _engine.revealedFloor : _total;
    final settledBelow = fading ? revealed - RevealEngine.fadeWindow : revealed;
    final children = <Widget>[];
    final liveSpans = <String, List<InlineSpan>>{};
    final liveSettled = <String, Widget>{};

    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final start = starts[i];
      final end = start + countRevealCharacters(spans[i]);

      // The document ends where the reveal is.
      if (start >= revealed) {
        break;
      }
      liveSpans[segment] = spans[i];

      final Widget child;
      if (end <= settledBelow) {
        // Settled: the paragraph is cached and handed back by identity, so
        // Flutter skips its rebuild and relayout. The keyed entrance wrapper
        // is applied per position, outside the cache: its child is identical
        // build to build, so the subtree under it is still skipped, and two
        // identical segments no longer share one key.
        final paragraph =
            liveSettled[segment] = _settled[segment] ?? _paragraph(spans[i]);
        child = _entrance(i, start, spans[i], paragraph);
      } else {
        // The colour is resolved here and not before the loop on purpose:
        // reading Theme and DefaultTextStyle registers an inherited
        // dependency, and a dependency that fires drops the segment caches. A
        // document that is not revealing must not pay that — it would rebuild
        // every segment whenever an ancestor rebuilt.
        child = _entrance(
          i,
          start,
          spans[i],
          _paragraph(
            applyReveal(
              spans: spans[i],
              revealed: revealed - start,
              effect: widget.effect,
              progressFor: (index) => _engine.progressFor(start + index),
              defaultColor:
                  widget.config.style?.color ??
                  DefaultTextStyle.of(context).style.color ??
                  Theme.of(context).colorScheme.onSurface,
              window: RevealEngine.fadeWindow,
            ),
          ),
        );
      }

      if (i > 0) {
        children.add(SizedBox(height: gap));
      }
      children.add(child);
    }

    _spans
      ..clear()
      ..addAll(liveSpans);
    _settled
      ..clear()
      ..addAll(liveSettled);

    // The ticker is armed here rather than in `initState` because the target
    // is a property of the *rendered* document: how many characters a source
    // produces is only known once it has been rendered, and on the first build
    // that has just happened for the first time. Arming it earlier would aim
    // the reveal at zero and stop it before it began.
    //
    // Starting a ticker during build is safe: it schedules a callback, it does
    // not call back synchronously.
    if (widget.revealing &&
        (_engine.revealedFloor < _total || _engine.tailStillFading)) {
      _startTicking();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      // start, not stretch: stretch forces every segment to the maximum width
      // the parent offers, so a two-word answer laid claim to the whole
      // column. The single-text pipeline sizes to its content, and so should
      // this — a paragraph that needs the width still takes it, because its
      // own text wraps into it.
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}
