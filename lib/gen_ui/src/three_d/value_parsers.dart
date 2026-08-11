part of 'gen_ui_3d_graphs.dart';

String? _equationFromValue(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is String) {
    final equation = value.trim();
    return equation.isEmpty ? null : equation;
  }
  if (value is List) {
    for (final item in value) {
      final equation = _equationFromValue(item);
      if (equation != null) {
        return equation;
      }
    }
    return null;
  }
  if (value is Map) {
    for (final key in const [
      'equation',
      'formula',
      'function',
      'expression',
      'z',
      'r',
      'radius',
    ]) {
      final equation = _equationFromValue(value[key]);
      if (equation != null) {
        return equation;
      }
    }
  }
  return null;
}

String _rightHandExpression(String value) {
  final equalsIndex = value.indexOf('=');
  if (equalsIndex == -1) {
    return value;
  }
  return value.substring(equalsIndex + 1);
}

double? _doubleFromValue(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value);
  }
  return null;
}

double? _angleFromValue(dynamic value) {
  if (value == 'pi') {
    return math.pi;
  }
  if (value is String && value.endsWith('pi')) {
    final multiplier = double.tryParse(value.substring(0, value.length - 2));
    if (multiplier != null) {
      return multiplier * math.pi;
    }
  }
  return _doubleFromValue(value);
}

int? _stepsFromValue(dynamic value) {
  final steps = _doubleFromValue(value)?.round();
  if (steps == null) {
    return null;
  }
  return steps.clamp(8, 96);
}

vm.Vector3? _vectorFromValue(dynamic value) {
  if (value is! List || value.length < 3) {
    return null;
  }

  final x = _doubleFromValue(value[0]);
  final y = _doubleFromValue(value[1]);
  final z = _doubleFromValue(value[2]);
  if (x == null || y == null || z == null) {
    return null;
  }
  return vm.Vector3(x, y, z);
}

WireframeMode _wireframeFromValue(dynamic value) {
  return switch (value?.toString()) {
    'only' => WireframeMode.only,
    'overlay' => WireframeMode.overlay,
    _ => WireframeMode.none,
  };
}

GradientAxis _gradientAxisFromValue(dynamic value) {
  return switch (value?.toString()) {
    'x' => GradientAxis.x,
    'y' => GradientAxis.y,
    'u' => GradientAxis.u,
    'v' => GradientAxis.v,
    _ => GradientAxis.z,
  };
}

List<Color> _colorsFromValue(dynamic value, {required List<Color> fallback}) {
  if (value is! List) {
    return fallback;
  }

  final colors = [
    for (final item in value)
      _colorFromValue(item, fallback: Colors.transparent),
  ].where((color) => color != Colors.transparent).toList();

  return colors.isEmpty ? fallback : colors.take(4).toList();
}

Color _colorFromValue(dynamic value, {required Color fallback}) {
  if (value is Color) {
    return value;
  }
  if (value is int) {
    return Color(value);
  }
  if (value is String) {
    final hex = value.replaceAll('#', '').replaceAll('0x', '');
    if (hex.length == 6) {
      final color = int.tryParse('FF$hex', radix: 16);
      if (color != null) {
        return Color(color);
      }
    }
    if (hex.length == 8) {
      final color = int.tryParse(hex, radix: 16);
      if (color != null) {
        return Color(color);
      }
    }
  }
  return fallback;
}
