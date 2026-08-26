/// Workaround for https://github.com/flutter/flutter/issues/54400.
///
/// Flutter's paragraph engine fills the inline-placeholder slots of a line in
/// *logical* order from left to right, even when the line reads right to left.
/// The surrounding text runs are reordered correctly, so a paragraph such as
///
/// ```text
/// واحد \(two^2\) ثلاثة أربعة five ستة سبعة \(eight^8\)
/// ```
///
/// renders every word in the right place but swaps the two formulas: the first
/// one is pushed to the far left, where the last one belongs.
///
/// [BidiText] and [BidiRichText] undo that. Before the real layout they run a
/// probe layout, work out the correct visual order of the placeholders on every
/// line with the Unicode bidi reordering rule (UAX #9, rule L2), and then feed
/// the placeholder sizes to the engine in the order the engine will consume
/// them. The children are matched back up with the boxes afterwards.
///
/// When the computed order turns out to be the identity — no RTL involved, a
/// single placeholder per line, an all-LTR line — nothing is changed and the
/// behaviour is identical to a plain [RichText].
library;

import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'inline_code.dart';

/// Strong right-to-left scripts: Hebrew, Arabic, Syriac, Thaana, NKo, Samaritan
/// and the Arabic presentation forms.
final RegExp _rtlPattern = RegExp(r'[֐-׿؀-޿ࡠ-ࣿיִ-﷿ﹰ-﻿]');

/// Whether [span] can be hit by the placeholder-ordering bug.
///
/// Two or more inline widgets are needed for an ordering to exist at all, and
/// some right-to-left text is needed for the visual order to differ from the
/// logical one. Anything else keeps using a stock [Text].
bool needsBidiPlaceholderFix(InlineSpan span) {
  var placeholders = 0;
  var hasRtl = false;

  void visit(InlineSpan current) {
    if (current is PlaceholderSpan) {
      placeholders++;
    }
    if (current is TextSpan) {
      final text = current.text;
      if (!hasRtl && text != null && _rtlPattern.hasMatch(text)) {
        hasRtl = true;
      }
      final children = current.children;
      if (children != null) {
        for (final child in children) {
          visit(child);
        }
      }
    }
  }

  visit(span);
  return placeholders >= 2 && hasRtl;
}

/// The text offset of every [PlaceholderSpan] in [root], in logical order.
///
/// Each placeholder takes up exactly one code unit (U+FFFC) in the plain text
/// the engine lays out.
List<int> _placeholderOffsets(InlineSpan root) {
  final offsets = <int>[];
  var offset = 0;

  void visit(InlineSpan span) {
    if (span is TextSpan) {
      offset += span.text?.length ?? 0;
      final children = span.children;
      if (children != null) {
        for (final child in children) {
          visit(child);
        }
      }
    } else if (span is PlaceholderSpan) {
      offsets.add(offset);
      offset += 1;
    } else {
      offset += span.toPlainText(includePlaceholders: true).length;
    }
  }

  visit(root);
  return offsets;
}

void _reverseRange(List<int> list, int start, int end) {
  var i = start;
  var j = end - 1;
  while (i < j) {
    final tmp = list[i];
    list[i] = list[j];
    list[j] = tmp;
    i++;
    j--;
  }
}

/// A [RichText] that lays inline widgets out in the correct visual order in
/// bidirectional paragraphs.
class BidiRichText extends RichText {
  BidiRichText({
    super.key,
    required super.text,
    this.bidiEnabled = true,
    this.inlineCodeRuns = const <InlineCodeRun>[],
    super.textAlign,
    super.textDirection,
    super.softWrap,
    super.overflow,
    super.textScaler,
    super.maxLines,
    super.locale,
    super.strutStyle,
    super.textWidthBasis,
    super.textHeightBehavior,
    super.selectionRegistrar,
    super.selectionColor,
  });

  /// Whether to reorder inline placeholders for bidirectional text.
  ///
  /// The reordering costs a probe layout, so callers that already know the
  /// paragraph cannot be affected — see [needsBidiPlaceholderFix] — pass false
  /// and this behaves exactly like a [RichText].
  final bool bidiEnabled;

  /// Inline-code runs to paint chips behind. See [InlineCodeDecoration].
  final List<InlineCodeRun> inlineCodeRuns;

  @override
  RenderParagraph createRenderObject(BuildContext context) {
    return RenderBidiParagraph(
      text,
      bidiEnabled: bidiEnabled,
      inlineCodeRuns: inlineCodeRuns,
      textAlign: textAlign,
      textDirection: textDirection ?? Directionality.of(context),
      softWrap: softWrap,
      overflow: overflow,
      textScaler: textScaler,
      maxLines: maxLines,
      strutStyle: strutStyle,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      locale: locale ?? Localizations.maybeLocaleOf(context),
      registrar: selectionRegistrar,
      selectionColor: selectionColor,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderParagraph renderObject,
  ) {
    super.updateRenderObject(context, renderObject);
    (renderObject as RenderBidiParagraph)
      ..bidiEnabled = bidiEnabled
      ..inlineCodeRuns = inlineCodeRuns;
  }
}

/// The render object behind [BidiRichText].
class RenderBidiParagraph extends RenderParagraph with InlineCodeDecoration {
  RenderBidiParagraph(
    super.text, {
    bool bidiEnabled = true,
    List<InlineCodeRun> inlineCodeRuns = const <InlineCodeRun>[],
    super.textAlign,
    required super.textDirection,
    super.softWrap,
    super.overflow,
    super.textScaler,
    super.maxLines,
    super.locale,
    super.strutStyle,
    super.textWidthBasis,
    super.textHeightBehavior,
    super.children,
    super.registrar,
    super.selectionColor,
  }) : _bidiEnabled = bidiEnabled {
    this.inlineCodeRuns = inlineCodeRuns;
  }

  bool _bidiEnabled;

  /// Whether placeholder reordering runs at all.
  bool get bidiEnabled => _bidiEnabled;

  set bidiEnabled(bool value) {
    if (_bidiEnabled == value) {
      return;
    }
    _bidiEnabled = value;
    _inverse = null;
    markNeedsLayout();
  }

  /// `_inverse[childIndex]` is the index of the engine box that child belongs
  /// in. `null` means "no reordering needed", in which case this render object
  /// behaves exactly like [RenderParagraph].
  List<int>? _inverse;

  TextPainter? _probe;

  @override
  void dispose() {
    _probe?.dispose();
    _probe = null;
    super.dispose();
  }

  @override
  List<PlaceholderDimensions> layoutInlineChildren(
    double maxWidth,
    ChildLayouter layoutChild,
    ChildBaselineGetter getChildBaseline,
  ) {
    final dimensions = super.layoutInlineChildren(
      maxWidth,
      layoutChild,
      getChildBaseline,
    );
    // Dry passes only measure. Permuting placeholders within a line never
    // changes the line's total width, so the dry size is the same either way,
    // and the cached order must not be clobbered before `performLayout` reads
    // it back in `positionInlineChildren`.
    if (!identical(layoutChild, ChildLayoutHelper.layoutChild)) {
      return dimensions;
    }
    _inverse = null;
    if (!_bidiEnabled) {
      return dimensions;
    }
    if (dimensions.length < 2) {
      return dimensions;
    }
    final order = _computeVisualOrder(dimensions, maxWidth);
    if (order == null) {
      return dimensions;
    }
    final inverse = List<int>.filled(order.length, 0);
    for (var boxIndex = 0; boxIndex < order.length; boxIndex++) {
      inverse[order[boxIndex]] = boxIndex;
    }
    _inverse = inverse;
    return <PlaceholderDimensions>[for (final i in order) dimensions[i]];
  }

  @override
  void positionInlineChildren(List<ui.TextBox> boxes) {
    final inverse = _inverse;
    if (inverse == null || boxes.length != inverse.length) {
      // Not reordering, or the engine dropped placeholders (ellipsis). Either
      // way, hand the boxes over untouched.
      super.positionInlineChildren(boxes);
      return;
    }
    // `super` walks the children in order and gives child `i` the box at index
    // `i`, so hand it a list already arranged that way.
    super.positionInlineChildren(<ui.TextBox>[
      for (var child = 0; child < boxes.length; child++) boxes[inverse[child]],
    ]);
  }

  /// Returns `order`, where `order[k]` is the logical index of the placeholder
  /// that belongs in the engine's k-th placeholder slot, or `null` when the
  /// order is already correct.
  List<int>? _computeVisualOrder(
    List<PlaceholderDimensions> dimensions,
    double maxWidth,
  ) {
    final offsets = _placeholderOffsets(text);
    if (offsets.length != dimensions.length) {
      return null;
    }

    final probe =
        _probe ??= TextPainter(textDirection: textDirection)
          ..textWidthBasis = textWidthBasis;
    probe
      ..text = text
      ..textAlign = textAlign
      ..textDirection = textDirection
      ..textScaler = textScaler
      ..maxLines = maxLines
      ..ellipsis = overflow == TextOverflow.ellipsis ? '…' : null
      ..locale = locale
      ..strutStyle = strutStyle
      ..textWidthBasis = textWidthBasis
      ..textHeightBehavior = textHeightBehavior
      ..setPlaceholderDimensions(dimensions);
    probe.layout(
      maxWidth:
          softWrap || overflow == TextOverflow.ellipsis
              ? maxWidth
              : double.infinity,
    );

    final boxes = probe.inlinePlaceholderBoxes;
    if (boxes == null || boxes.length != offsets.length) {
      return null;
    }

    final order = <int>[];
    var changed = false;
    var start = 0;
    while (start < boxes.length) {
      final line = probe.getLineBoundary(TextPosition(offset: offsets[start]));
      var end = start + 1;
      while (end < boxes.length &&
          probe.getLineBoundary(TextPosition(offset: offsets[end])) == line) {
        end++;
      }
      final lineOrder = _visualOrderForLine(probe, boxes, offsets, start, end);
      for (var i = 0; i < lineOrder.length; i++) {
        if (lineOrder[i] != start + i) {
          changed = true;
        }
      }
      order.addAll(lineOrder);
      start = end;
    }
    return changed ? order : null;
  }

  /// Visual (left to right) order of the placeholders `[start, end)` of one
  /// line, via the Unicode bidi reordering rule L2.
  List<int> _visualOrderForLine(
    TextPainter probe,
    List<ui.TextBox> boxes,
    List<int> offsets,
    int start,
    int end,
  ) {
    if (end - start < 2) {
      return <int>[for (var i = start; i < end; i++) i];
    }

    final baseLevel = textDirection == TextDirection.rtl ? 1 : 0;
    int levelOf(TextDirection direction) {
      if (baseLevel == 1) {
        return direction == TextDirection.ltr ? 2 : 1;
      }
      return direction == TextDirection.ltr ? 0 : 1;
    }

    // The sequence the reordering runs on: every placeholder, plus one item per
    // stretch of text between two of them (needed because two LTR placeholders
    // only share an embedding run when the text between them is LTR too).
    final items = <int>[]; // placeholder index, or -1 for a text separator
    final levels = <int>[];
    for (var i = start; i < end; i++) {
      if (i > start) {
        final separator = _separatorDirection(
          probe,
          offsets[i - 1] + 1,
          offsets[i],
        );
        if (separator != null) {
          items.add(-1);
          levels.add(levelOf(separator));
        }
      }
      items.add(i);
      levels.add(levelOf(boxes[i].direction));
    }

    var maxLevel = baseLevel;
    var minOddLevel = baseLevel.isOdd ? baseLevel : 1 << 30;
    for (final level in levels) {
      if (level > maxLevel) {
        maxLevel = level;
      }
      if (level.isOdd && level < minOddLevel) {
        minOddLevel = level;
      }
    }

    // L2: from the highest level down to the lowest odd level, reverse every
    // contiguous run at that level or above. Ranges come from the fixed logical
    // level array; the reversals compose on the result.
    for (var level = maxLevel; level >= minOddLevel; level--) {
      var i = 0;
      while (i < levels.length) {
        if (levels[i] < level) {
          i++;
          continue;
        }
        var j = i;
        while (j < levels.length && levels[j] >= level) {
          j++;
        }
        _reverseRange(items, i, j);
        i = j;
      }
    }

    return <int>[
      for (final item in items)
        if (item >= 0) item,
    ];
  }

  /// The resolved direction of the text in `[start, end)`, or `null` when that
  /// range is empty. A range holding any RTL run counts as RTL, since a single
  /// RTL run is enough to break an LTR embedding in two.
  TextDirection? _separatorDirection(TextPainter probe, int start, int end) {
    if (end <= start) {
      return null;
    }
    final boxes = probe.getBoxesForSelection(
      TextSelection(baseOffset: start, extentOffset: end),
    );
    if (boxes.isEmpty) {
      return null;
    }
    for (final box in boxes) {
      if (box.direction == TextDirection.rtl) {
        return TextDirection.rtl;
      }
    }
    return TextDirection.ltr;
  }
}

/// A drop-in stand-in for `Text.rich` that renders inline widgets in the right
/// visual order in bidirectional paragraphs.
///
/// It resolves the ambient [DefaultTextStyle], bold-text and text-scale
/// accessibility settings, and selection registrar the same way [Text] does.
class BidiText extends StatelessWidget {
  const BidiText(
    this.textSpan, {
    super.key,
    this.bidiEnabled = true,
    this.inlineCodeRuns = const <InlineCodeRun>[],
    this.style,
    this.textAlign,
    this.textDirection,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.locale,
    this.strutStyle,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  });

  final InlineSpan textSpan;

  /// Whether to reorder inline placeholders for bidirectional text.
  final bool bidiEnabled;

  /// Inline-code runs to paint chips behind, in [textSpan]'s own offsets.
  final List<InlineCodeRun> inlineCodeRuns;

  final TextStyle? style;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final bool? softWrap;
  final TextOverflow? overflow;
  final TextScaler? textScaler;
  final int? maxLines;
  final Locale? locale;
  final StrutStyle? strutStyle;
  final TextWidthBasis? textWidthBasis;
  final ui.TextHeightBehavior? textHeightBehavior;
  final Color? selectionColor;

  @override
  Widget build(BuildContext context) {
    final defaultTextStyle = DefaultTextStyle.of(context);
    var effectiveTextStyle = style;
    if (style == null || style!.inherit) {
      effectiveTextStyle = defaultTextStyle.style.merge(style);
    }
    if (MediaQuery.boldTextOf(context)) {
      effectiveTextStyle = effectiveTextStyle!.merge(
        const TextStyle(fontWeight: FontWeight.bold),
      );
    }
    final registrar = SelectionContainer.maybeOf(context);
    return BidiRichText(
      bidiEnabled: bidiEnabled,
      inlineCodeRuns: inlineCodeRuns,
      text: TextSpan(
        style: effectiveTextStyle,
        locale: locale,
        children: <InlineSpan>[textSpan],
      ),
      textAlign: textAlign ?? defaultTextStyle.textAlign ?? TextAlign.start,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap ?? defaultTextStyle.softWrap,
      overflow:
          overflow ?? effectiveTextStyle?.overflow ?? defaultTextStyle.overflow,
      textScaler: textScaler ?? MediaQuery.textScalerOf(context),
      maxLines: maxLines ?? defaultTextStyle.maxLines,
      strutStyle: strutStyle,
      textWidthBasis: textWidthBasis ?? defaultTextStyle.textWidthBasis,
      textHeightBehavior:
          textHeightBehavior ??
          defaultTextStyle.textHeightBehavior ??
          DefaultTextHeightBehavior.maybeOf(context),
      selectionRegistrar: registrar,
      selectionColor:
          selectionColor ??
          DefaultSelectionStyle.of(context).selectionColor ??
          DefaultSelectionStyle.defaultColor,
    );
  }
}
