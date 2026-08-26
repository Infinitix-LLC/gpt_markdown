/// Shared value coercion helpers for gen-UI attribute maps.
///
/// Payloads come straight from a model, so every field is treated as
/// best-effort: wrong types degrade to `null` instead of throwing.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Reads a double from a `num` or a numeric `String`.
double? genUiDouble(dynamic value) {
  if (value is num) {
    final result = value.toDouble();
    return result.isFinite ? result : null;
  }
  if (value is String) {
    final parsed = double.tryParse(value.trim());
    return (parsed != null && parsed.isFinite) ? parsed : null;
  }
  return null;
}

/// Reads an int from an `int`, a rounded `num`, or a numeric `String`.
int? genUiInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.isFinite ? value.round() : null;
  }
  if (value is String) {
    final parsed = int.tryParse(value.trim());
    if (parsed != null) {
      return parsed;
    }
    final asDouble = double.tryParse(value.trim());
    return (asDouble != null && asDouble.isFinite) ? asDouble.round() : null;
  }
  return null;
}

/// Reads a bool from a `bool` or the strings `true` / `false`.
bool? genUiBool(dynamic value) {
  if (value is bool) {
    return value;
  }
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true') return true;
    if (normalized == 'false') return false;
  }
  return null;
}

/// Reads a non-empty trimmed string, or `null`.
String? genUiString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

/// Reads a [Color] from a [Color], an ARGB `int`, or a `#RRGGBB` /
/// `#AARRGGBB` / `0xAARRGGBB` string. Falls back to [fallback].
Color genUiColor(dynamic value, {required Color fallback}) {
  if (value is Color) {
    return value;
  }
  if (value is int) {
    return Color(value);
  }
  if (value is String) {
    final hex = value.replaceAll('#', '').replaceAll('0x', '').trim();
    if (hex.length == 6) {
      final parsed = int.tryParse('FF$hex', radix: 16);
      if (parsed != null) {
        return Color(parsed);
      }
    }
    if (hex.length == 8) {
      final parsed = int.tryParse(hex, radix: 16);
      if (parsed != null) {
        return Color(parsed);
      }
    }
  }
  return fallback;
}

/// Compact number formatting: drops a trailing `.0`, otherwise one decimal.
String genUiFormatNumber(double value) {
  if (!value.isFinite) {
    return 'N/A';
  }
  if (value % 1 == 0) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(1);
}

/// Formats [value] with up to [precision] decimals, trimming trailing zeros.
String genUiFormatPrecise(double value, int precision) {
  if (!value.isFinite) {
    return 'N/A';
  }

  final threshold = math.pow(10, -precision).toDouble();
  if ((value - value.roundToDouble()).abs() < threshold) {
    return value.toStringAsFixed(0);
  }

  return value
      .toStringAsFixed(precision)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

/// Axis label formatting: integers stay integers, everything else gets one
/// decimal.
String genUiFormatAxis(double value) {
  if (!value.isFinite) return '';
  final absolute = value.abs();
  if (absolute >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (absolute >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}k';
  }
  if (value % 1 == 0) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(1);
}

/// Default series palette, matching the host app's gen-UI colors.
const List<Color> genUiPalette = [
  Color(0xFFC848AB),
  Color(0xFF766CE3),
  Color(0xFF4090DD),
  Color(0xFFE9967A),
  Color(0xFF00CED1),
];

/// Palette entry for series index [index], wrapping around.
Color genUiPaletteColor(int index) => genUiPalette[index % genUiPalette.length];

/// Builds `{index: label}` from a JSON list of labels.
Map<int, String> genUiLabelsByIndex(dynamic value) {
  if (value is! List) {
    return const {};
  }
  return {for (var i = 0; i < value.length; i++) i: value[i].toString()};
}

/// A single `(x, y)` sample.
///
/// Accepts bare numbers (index becomes `x`) or objects with `y` / `value` and
/// an optional `x`.
@immutable
class GenUiPoint {
  const GenUiPoint({required this.x, required this.y});

  final double x;
  final double y;

  static List<GenUiPoint> fromList(dynamic value) {
    if (value is! List) {
      return const [];
    }

    final points = <GenUiPoint>[];
    for (var i = 0; i < value.length; i++) {
      final entry = value[i];
      if (entry is Map) {
        final y = genUiDouble(entry['y'] ?? entry['value']);
        if (y == null) {
          continue;
        }
        points.add(
          GenUiPoint(x: genUiDouble(entry['x']) ?? i.toDouble(), y: y),
        );
      } else {
        final y = genUiDouble(entry);
        if (y != null) {
          points.add(GenUiPoint(x: i.toDouble(), y: y));
        }
      }
    }
    return points;
  }
}

/// A labeled value, used by bar / pie / progress / metric widgets.
@immutable
class GenUiItem {
  const GenUiItem({required this.label, required this.value, this.color});

  final String label;
  final double value;
  final dynamic color;

  static List<GenUiItem> fromList(dynamic value) {
    if (value is! List) {
      return const [];
    }

    final items = <GenUiItem>[];
    for (var i = 0; i < value.length; i++) {
      final entry = value[i];
      if (entry is Map) {
        final itemValue = genUiDouble(entry['value'] ?? entry['y']);
        if (itemValue == null) {
          continue;
        }
        items.add(
          GenUiItem(
            label: entry['label']?.toString() ?? entry['x']?.toString() ?? '$i',
            value: itemValue,
            color: entry['color'],
          ),
        );
      } else {
        final itemValue = genUiDouble(entry);
        if (itemValue != null) {
          items.add(GenUiItem(label: '$i', value: itemValue));
        }
      }
    }
    return items;
  }
}

/// A `current` vs `target` pair for the comparison chart.
@immutable
class GenUiComparisonItem {
  const GenUiComparisonItem({
    required this.label,
    required this.current,
    required this.target,
  });

  final String label;
  final double current;
  final double target;

  static List<GenUiComparisonItem> fromList(dynamic value) {
    if (value is! List) {
      return const [];
    }

    final items = <GenUiComparisonItem>[];
    for (var i = 0; i < value.length; i++) {
      final entry = value[i];
      if (entry is! Map) {
        continue;
      }

      final current = genUiDouble(entry['current']);
      final target = genUiDouble(entry['target']);
      if (current == null || target == null) {
        continue;
      }

      items.add(
        GenUiComparisonItem(
          label: entry['label']?.toString() ?? '$i',
          current: current,
          target: target,
        ),
      );
    }
    return items;
  }
}

/// A metric tile: a big display value plus an optional delta.
@immutable
class GenUiMetricItem {
  const GenUiMetricItem({
    required this.label,
    required this.value,
    this.delta,
    this.color,
  });

  final String label;
  final String value;
  final String? delta;
  final dynamic color;

  static List<GenUiMetricItem> fromList(dynamic value) {
    if (value is! List) {
      return const [];
    }

    final items = <GenUiMetricItem>[];
    for (var i = 0; i < value.length; i++) {
      final entry = value[i];
      if (entry is! Map) {
        continue;
      }

      items.add(
        GenUiMetricItem(
          label: entry['label']?.toString() ?? '$i',
          value: entry['value']?.toString() ?? '',
          delta: genUiString(entry['delta']),
          color: entry['color'],
        ),
      );
    }
    return items;
  }
}

/// Chooses "nice" evenly spaced axis ticks covering `[min, max]`.
List<double> genUiNiceTicks(double min, double max, {int desired = 5}) {
  if (!min.isFinite || !max.isFinite || desired < 2) {
    return [min, max];
  }
  if ((max - min).abs() < 1e-12) {
    return [min, min + 1];
  }

  final rawStep = (max - min) / (desired - 1);
  final magnitude =
      math.pow(10, (math.log(rawStep) / math.ln10).floor()).toDouble();
  final normalized = rawStep / magnitude;
  final double niceNormalized;
  if (normalized <= 1) {
    niceNormalized = 1;
  } else if (normalized <= 2) {
    niceNormalized = 2;
  } else if (normalized <= 5) {
    niceNormalized = 5;
  } else {
    niceNormalized = 10;
  }
  final step = niceNormalized * magnitude;

  final start = (min / step).floor() * step;
  final ticks = <double>[];
  for (var tick = start; tick <= max + step * 0.5; tick += step) {
    if (tick >= min - step * 0.5) {
      ticks.add(tick);
    }
    if (ticks.length > 24) break;
  }
  return ticks.isEmpty ? [min, max] : ticks;
}
