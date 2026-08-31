/// Applying a character reveal to spans that are already built.
///
/// The alternative — re-slicing the Markdown source every frame and rendering
/// the prefix — reparses the tail on every tick, and can only ever produce a
/// hard cut: by the time there are spans the character boundaries are gone, so
/// the only softening left is a gradient over whatever pixels happen to be at
/// the bottom of the box.
///
/// Working on the span tree instead means the document is rendered once per
/// *text* change rather than once per *frame*, and a frame's whole job is
/// restyling the handful of characters still arriving. It also has nothing to
/// say about which parser produced the spans, so one implementation serves
/// both pipelines.
library;

import 'package:flutter/material.dart';

import 'reveal_effect.dart';

/// Total characters in [spans], counting a placeholder as one.
///
/// This is the unit the reveal counts in, so it has to agree exactly with what
/// [applyReveal] walks — hence one function, used by both.
int countRevealCharacters(List<InlineSpan> spans) {
  var total = 0;
  for (final span in spans) {
    total += _count(span);
  }
  return total;
}

int _count(InlineSpan span) {
  if (span is! TextSpan) {
    // A placeholder occupies one character in Flutter's own accounting
    // (`￼`); matching that keeps offsets aligned with the paragraph.
    return 1;
  }
  var total = span.text?.length ?? 0;
  final children = span.children;
  if (children != null) {
    for (final child in children) {
      total += _count(child);
    }
  }
  return total;
}

/// Rebuilds [spans] showing only the first [revealed] characters, with the
/// ones still arriving styled by [effect].
///
/// [progressFor] reports how far through its entrance the character at a given
/// index is — `RevealEngine.progressFor` in practice, but any function will do.
///
/// Three regions come out of this, and only the middle one costs anything per
/// frame:
///
/// * **Settled** — characters whose entrance is over, emitted as whole spans
///   and never split, so a long reply stays a handful of spans.
/// * **Arriving** — at most [window] characters, each its own span carrying
///   the effect's style delta.
/// * **Unrevealed** — dropped. The document ends where the reveal is, so
///   nothing below the reading position is laid out before it is meant to be
///   seen, and nothing pops in there later.
List<InlineSpan> applyReveal({
  required List<InlineSpan> spans,
  required int revealed,
  required GptMarkdownAnimation effect,
  required double Function(int index) progressFor,
  required Color defaultColor,
  int window = 64,
}) {
  final from = effect.animatesCharacters ? revealed - window : revealed;
  final out = <InlineSpan>[];
  _walk(
    spans: spans,
    out: out,
    cursor: _Cursor(),
    revealed: revealed,
    settledBelow: from < 0 ? 0 : from,
    effect: effect,
    progressFor: progressFor,
    inheritedColor: defaultColor,
  );
  return out;
}

/// The running character offset, shared down the recursion.
class _Cursor {
  int value = 0;
}

void _walk({
  required List<InlineSpan> spans,
  required List<InlineSpan> out,
  required _Cursor cursor,
  required int revealed,
  required int settledBelow,
  required GptMarkdownAnimation effect,
  required double Function(int index) progressFor,
  required Color inheritedColor,
}) {
  for (final span in spans) {
    if (cursor.value >= revealed) {
      return;
    }
    if (span is! TextSpan) {
      // Placeholders are atomic: shown whole or not at all, and never
      // restyled — there is no text inside them to fade.
      out.add(span);
      cursor.value += 1;
      continue;
    }

    // Only the colour is resolved down the tree. Everything else is left to
    // Flutter's own span inheritance, so the rebuilt tree keeps whatever the
    // renderer put on these spans without this file having to know about it.
    final color = span.style?.color ?? inheritedColor;

    final pieces = <InlineSpan>[];
    final text = span.text;
    if (text != null && text.isNotEmpty) {
      _emitText(
        text: text,
        out: pieces,
        cursor: cursor,
        revealed: revealed,
        settledBelow: settledBelow,
        effect: effect,
        progressFor: progressFor,
        color: color,
      );
    }
    final children = span.children;
    if (children != null && cursor.value < revealed) {
      _walk(
        spans: children,
        out: pieces,
        cursor: cursor,
        revealed: revealed,
        settledBelow: settledBelow,
        effect: effect,
        progressFor: progressFor,
        inheritedColor: color,
      );
    }
    if (pieces.isEmpty) {
      continue;
    }
    // The original span's own style and recognizer are kept on the container
    // and the pieces carry only the effect's delta, so a link in the tail is
    // still a link and Flutter resolves `foreground` against `color` the way
    // it always does.
    out.add(
      TextSpan(
        children: pieces,
        style: span.style,
        recognizer: span.recognizer,
        mouseCursor: span.mouseCursor,
        onEnter: span.onEnter,
        onExit: span.onExit,
        semanticsLabel: span.semanticsLabel,
        locale: span.locale,
        spellOut: span.spellOut,
      ),
    );
  }
}

void _emitText({
  required String text,
  required List<InlineSpan> out,
  required _Cursor cursor,
  required int revealed,
  required int settledBelow,
  required GptMarkdownAnimation effect,
  required double Function(int index) progressFor,
  required Color color,
}) {
  final start = cursor.value;
  final end = start + text.length;
  cursor.value = end;

  // Entirely settled: one span, whatever its length. This is the branch that
  // keeps a long reply cheap.
  if (end <= settledBelow) {
    out.add(TextSpan(text: text));
    return;
  }
  // Entirely past the reveal head.
  if (start >= revealed) {
    return;
  }

  final settledEnd = settledBelow < start ? start : settledBelow;
  if (settledEnd > start) {
    out.add(TextSpan(text: text.substring(0, settledEnd - start)));
  }

  final limit = end < revealed ? end : revealed;
  var i = settledEnd;
  while (i < limit) {
    // Never split a surrogate pair: half of one is not a character, and
    // Flutter cannot lay it out as anything sensible.
    final width =
        _isHighSurrogate(text.codeUnitAt(i - start)) && i + 1 < limit ? 2 : 1;
    final piece = text.substring(i - start, i - start + width);
    final delta = revealStyleFor(effect, progressFor(i), color);
    out.add(TextSpan(text: piece, style: delta));
    i += width;
  }
}

bool _isHighSurrogate(int codeUnit) => (codeUnit & 0xFC00) == 0xD800;
