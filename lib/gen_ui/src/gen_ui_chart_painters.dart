import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'gen_ui_values.dart';

/// Dependency-free chart painters backing the gen-UI chart widgets.
///
/// These replace the chart package the host app used, so the markdown package
/// stays free of charting dependencies. They cover exactly what the gen-UI
/// payload schema needs: a line/area series, single-series bars, grouped
/// comparison bars, and a donut pie.

/// Colors and metrics pulled from the ambient theme, so painters do not need a
/// [BuildContext].
@immutable
class GenUiChartStyle {
  const GenUiChartStyle({
    required this.grid,
    required this.border,
    required this.label,
    required this.surface,
  });

  factory GenUiChartStyle.of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GenUiChartStyle(
      grid: scheme.outlineVariant,
      border: scheme.outlineVariant,
      label: scheme.onSurfaceVariant,
      surface: scheme.surface,
    );
  }

  final Color grid;
  final Color border;
  final Color label;
  final Color surface;

  @override
  bool operator ==(Object other) =>
      other is GenUiChartStyle &&
      other.grid == grid &&
      other.border == border &&
      other.label == label &&
      other.surface == surface;

  @override
  int get hashCode => Object.hash(grid, border, label, surface);
}

const double _leftAxisWidth = 40;
const double _bottomAxisHeight = 32;
const double _axisFontSize = 10;

/// Lays out the plot area and paints the grid plus axis labels.
class _AxisFrame {
  _AxisFrame({
    required this.size,
    required this.style,
    required this.minY,
    required this.maxY,
    required this.textScaler,
  }) : plot = Rect.fromLTRB(
         _leftAxisWidth,
         4,
         math.max(_leftAxisWidth + 1, size.width),
         math.max(5, size.height - _bottomAxisHeight),
       );

  final Size size;
  final GenUiChartStyle style;
  final double minY;
  final double maxY;
  final TextScaler textScaler;
  final Rect plot;

  double yToPixels(double value) {
    final span = maxY - minY;
    if (span.abs() < 1e-12) {
      return plot.bottom;
    }
    final t = (value - minY) / span;
    return plot.bottom - t * plot.height;
  }

  void paintHorizontalGrid(Canvas canvas, {bool withLabels = true}) {
    final paint = Paint()
      ..color = style.grid
      ..strokeWidth = 1;

    for (final tick in genUiNiceTicks(minY, maxY)) {
      final y = yToPixels(tick);
      if (y < plot.top - 0.5 || y > plot.bottom + 0.5) continue;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), paint);
      if (withLabels) {
        _paintText(
          canvas,
          genUiFormatAxis(tick),
          Offset(plot.left - 6, y),
          align: _TextAlign.right,
          color: style.label,
          textScaler: textScaler,
        );
      }
    }
  }

  void paintVerticalGridAt(Canvas canvas, Iterable<double> xs) {
    final paint = Paint()
      ..color = style.grid
      ..strokeWidth = 1;
    for (final x in xs) {
      if (x < plot.left - 0.5 || x > plot.right + 0.5) continue;
      canvas.drawLine(Offset(x, plot.top), Offset(x, plot.bottom), paint);
    }
  }

  void paintBorder(Canvas canvas) {
    canvas.drawRect(
      plot,
      Paint()
        ..color = style.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  /// Paints bottom labels, skipping any that would collide with the previous
  /// one.
  void paintBottomLabels(Canvas canvas, List<({double x, String label})> ticks) {
    var occupiedUntil = double.negativeInfinity;
    for (final tick in ticks) {
      if (tick.label.isEmpty) continue;
      final painter = _textPainter(tick.label, style.label, textScaler);
      final left = tick.x - painter.width / 2;
      if (left < occupiedUntil + 4) continue;
      occupiedUntil = left + painter.width;
      painter.paint(canvas, Offset(left, plot.bottom + 8));
    }
  }
}

enum _TextAlign { left, center, right }

TextPainter _textPainter(String text, Color color, TextScaler textScaler) {
  return TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(color: color, fontSize: _axisFontSize),
    ),
    textDirection: TextDirection.ltr,
    textScaler: textScaler,
  )..layout();
}

void _paintText(
  Canvas canvas,
  String text,
  Offset anchor, {
  required _TextAlign align,
  required Color color,
  required TextScaler textScaler,
  double fontSize = _axisFontSize,
  FontWeight? fontWeight,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
      ),
    ),
    textDirection: TextDirection.ltr,
    textScaler: textScaler,
  )..layout();

  final dx = switch (align) {
    _TextAlign.left => anchor.dx,
    _TextAlign.center => anchor.dx - painter.width / 2,
    _TextAlign.right => anchor.dx - painter.width,
  };
  painter.paint(canvas, Offset(dx, anchor.dy - painter.height / 2));
}

/// Line and area chart. Set [showArea] to fill below the curve.
class GenUiLineChartPainter extends CustomPainter {
  const GenUiLineChartPainter({
    required this.points,
    required this.color,
    required this.style,
    required this.curved,
    required this.showArea,
    required this.minY,
    required this.maxY,
    required this.textScaler,
    this.bottomLabels = const {},
  });

  final List<GenUiPoint> points;
  final Color color;
  final GenUiChartStyle style;
  final bool curved;
  final bool showArea;
  final double minY;
  final double maxY;
  final TextScaler textScaler;
  final Map<int, String> bottomLabels;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty || size.width <= 0 || size.height <= 0) return;

    final frame = _AxisFrame(
      size: size,
      style: style,
      minY: minY,
      maxY: maxY,
      textScaler: textScaler,
    );

    final minX = points.map((p) => p.x).reduce(math.min);
    final maxX = points.map((p) => p.x).reduce(math.max);
    double xToPixels(double x) {
      final span = maxX - minX;
      if (span.abs() < 1e-12) {
        return frame.plot.center.dx;
      }
      return frame.plot.left + (x - minX) / span * frame.plot.width;
    }

    final offsets = [
      for (final point in points)
        Offset(xToPixels(point.x), frame.yToPixels(point.y)),
    ];

    frame.paintHorizontalGrid(canvas);
    frame.paintVerticalGridAt(canvas, offsets.map((o) => o.dx));
    frame.paintBorder(canvas);

    final path = curved && offsets.length > 2
        ? _catmullRomPath(offsets)
        : (Path()..addPolygon(offsets, false));

    if (showArea) {
      final baseline = frame.yToPixels(minY.clamp(minY, maxY));
      final area = Path.from(path)
        ..lineTo(offsets.last.dx, baseline)
        ..lineTo(offsets.first.dx, baseline)
        ..close();
      canvas.drawPath(area, Paint()..color = color.withAlpha(50));
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    for (final offset in offsets) {
      canvas.drawCircle(offset, 4, Paint()..color = color);
      canvas.drawCircle(
        offset,
        4,
        Paint()
          ..color = style.surface
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    frame.paintBottomLabels(canvas, [
      for (var i = 0; i < points.length; i++)
        (
          x: offsets[i].dx,
          label: bottomLabels[points[i].x.round()] ??
              genUiFormatAxis(points[i].x),
        ),
    ]);
  }

  /// Catmull-Rom spline through every point, converted to cubic beziers.
  static Path _catmullRomPath(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = i == 0 ? points[i] : points[i - 1];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i + 2 < points.length ? points[i + 2] : p2;

      final c1 = Offset(
        p1.dx + (p2.dx - p0.dx) / 6,
        p1.dy + (p2.dy - p0.dy) / 6,
      );
      final c2 = Offset(
        p2.dx - (p3.dx - p1.dx) / 6,
        p2.dy - (p3.dy - p1.dy) / 6,
      );
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
    return path;
  }

  @override
  bool shouldRepaint(GenUiLineChartPainter old) =>
      old.points != points ||
      old.color != color ||
      old.style != style ||
      old.curved != curved ||
      old.showArea != showArea ||
      old.minY != minY ||
      old.maxY != maxY ||
      old.bottomLabels != bottomLabels;
}

/// Single-series bar chart with rounded rods.
class GenUiBarChartPainter extends CustomPainter {
  const GenUiBarChartPainter({
    required this.values,
    required this.colors,
    required this.labels,
    required this.style,
    required this.maxY,
    required this.textScaler,
  });

  final List<double> values;
  final List<Color> colors;
  final List<String> labels;
  final GenUiChartStyle style;
  final double maxY;
  final TextScaler textScaler;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || size.width <= 0 || size.height <= 0) return;

    final frame = _AxisFrame(
      size: size,
      style: style,
      minY: 0,
      maxY: maxY,
      textScaler: textScaler,
    );
    frame.paintHorizontalGrid(canvas);

    final slot = frame.plot.width / values.length;
    final barWidth = math.min(18.0, math.max(4.0, slot * 0.55));
    final bottom = frame.yToPixels(0);

    final ticks = <({double x, String label})>[];
    for (var i = 0; i < values.length; i++) {
      final centerX = frame.plot.left + slot * (i + 0.5);
      final top = frame.yToPixels(values[i]);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTRB(
          centerX - barWidth / 2,
          math.min(top, bottom),
          centerX + barWidth / 2,
          math.max(top, bottom),
        ),
        const Radius.circular(6),
      );
      canvas.drawRRect(rect, Paint()..color = colors[i % colors.length]);
      ticks.add((x: centerX, label: i < labels.length ? labels[i] : '$i'));
    }

    frame.paintBottomLabels(canvas, ticks);
  }

  @override
  bool shouldRepaint(GenUiBarChartPainter old) =>
      old.values != values ||
      old.colors != colors ||
      old.labels != labels ||
      old.style != style ||
      old.maxY != maxY;
}

/// Grouped bars: one `current` rod and one `target` rod per label.
class GenUiGroupedBarChartPainter extends CustomPainter {
  const GenUiGroupedBarChartPainter({
    required this.items,
    required this.currentColor,
    required this.targetColor,
    required this.style,
    required this.maxY,
    required this.textScaler,
  });

  final List<GenUiComparisonItem> items;
  final Color currentColor;
  final Color targetColor;
  final GenUiChartStyle style;
  final double maxY;
  final TextScaler textScaler;

  @override
  void paint(Canvas canvas, Size size) {
    if (items.isEmpty || size.width <= 0 || size.height <= 0) return;

    final frame = _AxisFrame(
      size: size,
      style: style,
      minY: 0,
      maxY: maxY,
      textScaler: textScaler,
    );
    frame.paintHorizontalGrid(canvas);

    const barsSpace = 4.0;
    final slot = frame.plot.width / items.length;
    final barWidth = math.min(10.0, math.max(3.0, (slot - barsSpace) * 0.34));
    final bottom = frame.yToPixels(0);

    void drawRod(double centerX, double value, Color color) {
      final top = frame.yToPixels(value);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(
            centerX - barWidth / 2,
            math.min(top, bottom),
            centerX + barWidth / 2,
            math.max(top, bottom),
          ),
          const Radius.circular(5),
        ),
        Paint()..color = color,
      );
    }

    final ticks = <({double x, String label})>[];
    for (var i = 0; i < items.length; i++) {
      final centerX = frame.plot.left + slot * (i + 0.5);
      final offset = (barWidth + barsSpace) / 2;
      drawRod(centerX - offset, items[i].current, currentColor);
      drawRod(centerX + offset, items[i].target, targetColor);
      ticks.add((x: centerX, label: items[i].label));
    }

    frame.paintBottomLabels(canvas, ticks);
  }

  @override
  bool shouldRepaint(GenUiGroupedBarChartPainter old) =>
      old.items != items ||
      old.currentColor != currentColor ||
      old.targetColor != targetColor ||
      old.style != style ||
      old.maxY != maxY;
}

/// Donut pie chart with in-slice labels.
class GenUiPieChartPainter extends CustomPainter {
  const GenUiPieChartPainter({
    required this.values,
    required this.colors,
    required this.labels,
    required this.style,
    required this.textScaler,
  });

  final List<double> values;
  final List<Color> colors;
  final List<String> labels;
  final GenUiChartStyle style;
  final TextScaler textScaler;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || size.width <= 0 || size.height <= 0) return;

    final total = values.fold<double>(0, (sum, value) => sum + value.abs());
    if (total <= 0) return;

    final center = size.center(Offset.zero);
    final outerRadius = math.min(size.width, size.height) / 2 - 2;
    if (outerRadius <= 0) return;
    final innerRadius = outerRadius * 0.34;
    // Angular equivalent of a ~2px gap between sections.
    final gap = values.length > 1 ? (2 / outerRadius) : 0.0;

    var startAngle = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = values[i].abs() / total * math.pi * 2;
      final drawSweep = math.max(0.0, sweep - gap);
      if (drawSweep > 0) {
        canvas.drawArc(
          Rect.fromCircle(
            center: center,
            radius: (outerRadius + innerRadius) / 2,
          ),
          startAngle + gap / 2,
          drawSweep,
          false,
          Paint()
            ..color = colors[i % colors.length]
            ..style = PaintingStyle.stroke
            ..strokeWidth = outerRadius - innerRadius,
        );
      }

      final label = i < labels.length ? labels[i] : '';
      // Only label slices wide enough to hold text.
      if (label.isNotEmpty && sweep > 0.28) {
        final midAngle = startAngle + sweep / 2;
        final labelRadius = (outerRadius + innerRadius) / 2;
        _paintText(
          canvas,
          label,
          center +
              Offset(
                math.cos(midAngle) * labelRadius,
                math.sin(midAngle) * labelRadius,
              ),
          align: _TextAlign.center,
          color: style.surface,
          textScaler: textScaler,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        );
      }

      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(GenUiPieChartPainter old) =>
      old.values != values ||
      old.colors != colors ||
      old.labels != labels ||
      old.style != style;
}
