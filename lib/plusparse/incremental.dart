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

  /// Fully settled segments, built once and handed back by identity.
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
  /// Set for a reply that was already complete when it mounted — history, a
  /// re-opened conversation — which must appear whole rather than typing
  /// itself out to a reader who has seen it before.
  late bool _snapPending = !widget.isStreaming;

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
      // A regenerate or a branch switch replaces the text rather than
      // extending it; continuing from the old offset would be meaningless.
      _engine.reset();
      _startTicking();
      return;
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

  /// Wraps [child] in its one-shot entrance, when the segment has one.
  ///
  /// Keyed by position, not by text: the tail's source changes with every
  /// chunk, and a text key would remount the entrance and replay it on every
  /// keystroke. Position is append-only while a reply grows, so the key holds
  /// exactly as long as the block does.
  Widget _entrance(int index, List<InlineSpan> spans, Widget child) {
    if (widget.blockAnimation == GptMarkdownBlockAnimation.none ||
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
    final segments = splitStreamSegments(widget.text);
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
    // itself out again.
    if (_snapPending) {
      _snapPending = false;
      _engine.snapToEnd(_total);
    }

    // Reduced motion is a preference about movement, not about content: the
    // document still renders, it just renders whole.
    final revealing =
        widget.revealing && !MediaQuery.disableAnimationsOf(context);
    final fading = revealing && widget.effect.animatesCharacters;
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
        // Settled: hand back the same widget instance, entrance wrapper and
        // all, so Flutter skips the rebuild and the relayout entirely. The
        // wrapper lives inside the cache rather than over it — a fresh
        // wrapper each build is a different widget, which is the reuse this
        // exists to protect.
        child =
            liveSettled[segment] =
                _settled[segment] ??
                _entrance(i, spans[i], _paragraph(spans[i]));
      } else {
        // The colour is resolved here and not before the loop on purpose:
        // reading Theme and DefaultTextStyle registers an inherited
        // dependency, and a dependency that fires drops the segment caches. A
        // document that is not revealing must not pay that — it would rebuild
        // every segment whenever an ancestor rebuilt.
        child = _entrance(
          i,
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}
