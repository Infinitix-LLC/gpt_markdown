part of 'gen_ui_3d_graphs.dart';

String _formulaValue(Map<String, dynamic> attributes) {
  for (final key in const [
    'equation',
    'equations',
    'formula',
    'function',
    'expression',
    'z',
    'r',
    'radius',
  ]) {
    if (key == 'formula' && attributes[key] is! String) {
      continue;
    }

    final equation = _equationFromValue(attributes[key]);
    if (equation != null) {
      return equation;
    }
  }

  return '';
}

SurfaceFn _surfaceFnFromValue(
  String value,
  List<_GraphConstant> constants,
  Map<String, double> constantValues,
) {
  const surfaceVariables = ['x', 'y'];
  final constantNames = _constantVariableNames(constants, surfaceVariables);
  final compiled = _compileFormula(
    value,
    variableNames: [...surfaceVariables, ...constantNames],
  );
  if (compiled == null) {
    return (x, y) => 0;
  }

  return (x, y) => compiled.evaluate([
        x,
        y,
        ..._constantEvaluationValues(constants, constantValues, constantNames),
      ]).toDouble();
}

PolarSurfaceFn _polarSurfaceFnFromValue(
  String value,
  List<_GraphConstant> constants,
  Map<String, double> constantValues,
) {
  const polarVariables = ['radius', 'r', 'theta'];
  final constantNames = _constantVariableNames(constants, polarVariables);
  final compiled = _compileFormula(
    value,
    variableNames: [...polarVariables, ...constantNames],
  );
  if (compiled == null) {
    return (radius, theta) => 0;
  }

  return (radius, theta) => compiled.evaluate([
        radius,
        radius,
        theta,
        ..._constantEvaluationValues(constants, constantValues, constantNames),
      ]).toDouble();
}

SphericalSurfaceFn _sphericalSurfaceFnFromValue(
  String value,
  List<_GraphConstant> constants,
  Map<String, double> constantValues,
) {
  const sphericalVariables = ['theta', 'phi'];
  final constantNames = _constantVariableNames(constants, sphericalVariables);
  final compiled = _compileFormula(
    value,
    variableNames: [...sphericalVariables, ...constantNames],
  );
  if (compiled == null) {
    return (theta, phi) => 1;
  }

  return (theta, phi) => compiled.evaluate([
        theta,
        phi,
        ..._constantEvaluationValues(constants, constantValues, constantNames),
      ]).toDouble();
}

CylindricalSurfaceFn _cylindricalSurfaceFnFromValue(
  String value,
  List<_GraphConstant> constants,
  Map<String, double> constantValues,
) {
  const cylindricalVariables = ['theta', 'z'];
  final constantNames = _constantVariableNames(constants, cylindricalVariables);
  final compiled = _compileFormula(
    value,
    variableNames: [...cylindricalVariables, ...constantNames],
  );
  if (compiled == null) {
    return (theta, z) => 1;
  }

  return (theta, z) => compiled.evaluate([
        theta,
        z,
        ..._constantEvaluationValues(constants, constantValues, constantNames),
      ]).toDouble();
}

List<_GraphConstant> _constantsFromValue(dynamic value) {
  if (value is! List) {
    return const [];
  }

  final constants = <_GraphConstant>[];
  final usedNames = <String>{};

  for (final item in value) {
    final constant = _constantFromValue(item);
    if (constant == null || usedNames.contains(constant.name)) {
      continue;
    }

    usedNames.add(constant.name);
    constants.add(constant);
  }

  return constants;
}

List<_GraphFormula> _formulasFromValue(dynamic value) {
  if (value == null || value is String) {
    return const [];
  }

  if (value is List) {
    return [
      for (final item in value)
        if (_formulaFromValue(item) case final formula?) formula,
    ];
  }

  final formula = _formulaFromValue(value);
  return formula == null ? const [] : [formula];
}

_GraphFormula? _formulaFromValue(dynamic value) {
  if (value is! Map) {
    return null;
  }

  final latex = _equationFromValue(
    value['latex'] ?? value['tex'] ?? value['equation'],
  );
  final expression = _equationFromValue(
    value['expression'] ?? value['valueExpression'] ?? value['value'],
  );
  if (latex == null || expression == null) {
    return null;
  }

  return _GraphFormula(latex: latex, expression: expression);
}

_GraphConstant? _constantFromValue(dynamic value) {
  if (value is! Map) {
    return null;
  }

  final name = value['name']?.toString().trim();
  if (name == null || !_isValidVariableName(name)) {
    return null;
  }

  final defaultValue = _doubleFromValue(value['value'] ?? value['default']);
  final min = _doubleFromValue(value['min']);
  final max = _doubleFromValue(value['max']);
  if (defaultValue == null || min == null || max == null || min >= max) {
    return null;
  }

  return _GraphConstant(
    name: name,
    label: value['label']?.toString().trim().isNotEmpty == true
        ? value['label'].toString().trim()
        : name,
    value: defaultValue.clamp(min, max).toDouble(),
    min: min,
    max: max,
    step: _doubleFromValue(value['step']),
  );
}

Map<String, double> _initialConstantValues(List<_GraphConstant> constants) {
  return {
    for (final constant in constants) constant.name: constant.value,
  };
}

List<String> _constantVariableNames(
  List<_GraphConstant> constants,
  List<String> graphVariables,
) {
  final blockedNames = graphVariables.toSet();
  return [
    for (final constant in constants)
      if (!blockedNames.contains(constant.name)) constant.name,
  ];
}

List<double> _constantEvaluationValues(
  List<_GraphConstant> constants,
  Map<String, double> constantValues,
  List<String> constantNames,
) {
  return [
    for (final name in constantNames)
      constantValues[name] ??
          constants.firstWhere((constant) => constant.name == name).value,
  ];
}

double? _constantExpressionValue(
  dynamic value,
  List<_GraphConstant> constants,
  Map<String, double> constantValues,
) {
  if (value is! String) {
    return null;
  }

  final constantNames = _constantVariableNames(constants, const []);
  final compiled = _compileFormula(value, variableNames: constantNames);
  if (compiled == null) {
    return null;
  }

  try {
    final result = compiled
        .evaluate(
          _constantEvaluationValues(constants, constantValues, constantNames),
        )
        .toDouble();
    return result.isFinite ? result : null;
  } on PlusfinityCalculatorException {
    return null;
  }
}

bool _isValidVariableName(String value) {
  return RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(value);
}

String _formatSliderValue(double value) {
  final text = value.abs() >= 100 || value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(3);

  return text.replaceFirst(RegExp(r'\.?0+$'), '');
}

PlusfinityCompiledEvaluator? _compileFormula(
  String value, {
  required List<String> variableNames,
}) {
  final formula = _withExplicitVariableMultiplication(
    _rightHandExpression(value).trim(),
    variableNames,
  );
  if (formula.isEmpty) {
    return null;
  }

  try {
    return PlusfinityCalculator()
        .parse(formula, variableNames: variableNames)
        .compile(variableNames: variableNames);
  } on PlusfinityCalculatorException {
    return null;
  }
}

String _withExplicitVariableMultiplication(
  String formula,
  List<String> variableNames,
) {
  var normalized = formula;
  final names = [...variableNames]
    ..sort((a, b) => b.length.compareTo(a.length));

  for (final name in names) {
    final escapedName = RegExp.escape(name);
    normalized = normalized.replaceAllMapped(
      RegExp('(^|[^A-Za-z0-9_])($escapedName)\\s*(?=\\()'),
      (match) => '${match[1]}${match[2]} * ',
    );
  }

  return normalized;
}
