import 'package:flutter/material.dart';

import 'gen_ui_shells.dart';
import 'gen_ui_values.dart';

/// Student-learning gen-UI widgets: an interactive unit converter and a
/// vertical timeline / process flow.

/// `unit_converter`: shows a source value, the converted value, an optional
/// slider, the dimensional-analysis steps, and a learning note.
class GenUnitConverter extends StatefulWidget {
  const GenUnitConverter({super.key, required this.attributes});

  final Map<String, dynamic> attributes;

  @override
  State<GenUnitConverter> createState() => _GenUnitConverterState();
}

class _GenUnitConverterState extends State<GenUnitConverter> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = _initialValue(widget.attributes);
  }

  @override
  void didUpdateWidget(covariant GenUnitConverter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.attributes != widget.attributes) {
      _value = _initialValue(widget.attributes);
    }
  }

  static double _initialValue(Map<String, dynamic> attributes) {
    return genUiDouble(attributes['value'] ?? attributes['amount']) ?? 1;
  }

  @override
  Widget build(BuildContext context) {
    final conversion = _UnitConversion.fromAttributes(
      widget.attributes,
      _value,
    );
    if (conversion == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final min = genUiDouble(widget.attributes['min']);
    final max = genUiDouble(widget.attributes['max']);
    final showSlider = min != null && max != null && max > min;

    return GenUiLearningCard(
      title: genUiString(widget.attributes['title']) ?? 'Unit Conversion',
      subtitle: genUiString(widget.attributes['subtitle']),
      icon: Icons.straighten_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _ValuePanel(
                  label: conversion.fromLabel,
                  value: genUiFormatPrecise(_value, conversion.precision),
                  unit: conversion.fromSymbol,
                  color: theme.colorScheme.primary,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 22,
                ),
              ),
              Expanded(
                child: _ValuePanel(
                  label: conversion.toLabel,
                  value: genUiFormatPrecise(
                    conversion.result,
                    conversion.precision,
                  ),
                  unit: conversion.toSymbol,
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
          if (showSlider) ...[
            const SizedBox(height: 18),
            GenUiSlider(
              min: min,
              max: max,
              value: _value.clamp(min, max),
              divisions: genUiInt(widget.attributes['divisions']),
              label: genUiFormatPrecise(_value, conversion.precision),
              onChanged: (value) => setState(() => _value = value),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  genUiFormatPrecise(min, conversion.precision),
                  style: genUiMutedStyle(theme, fontSize: 11),
                ),
                const Spacer(),
                Text(
                  genUiFormatPrecise(max, conversion.precision),
                  style: genUiMutedStyle(theme, fontSize: 11),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          GenUiFormulaBox(
            title: 'Dimensional analysis',
            lines: conversion.steps,
          ),
          if (conversion.note != null && conversion.note!.isNotEmpty) ...[
            const SizedBox(height: 12),
            GenUiLearningNote(text: conversion.note!),
          ],
        ],
      ),
    );
  }
}

/// `timeline_flow`: a numbered vertical timeline of steps or events.
class GenTimelineFlow extends StatelessWidget {
  const GenTimelineFlow({super.key, required this.attributes});

  final Map<String, dynamic> attributes;

  @override
  Widget build(BuildContext context) {
    final items = _TimelineItem.fromList(
      attributes['items'] ?? attributes['events'] ?? attributes['steps'],
    );
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final height = genUiDouble(attributes['height']);
    final content = Column(
      children: [
        for (var i = 0; i < items.length; i++)
          _TimelineRow(
            item: items[i],
            index: i,
            isFirst: i == 0,
            isLast: i == items.length - 1,
          ),
      ],
    );

    return GenUiLearningCard(
      title: genUiString(attributes['title']) ?? 'Timeline',
      subtitle: genUiString(attributes['subtitle']),
      icon: Icons.timeline_rounded,
      child: height == null
          ? content
          : SizedBox(
              height: height,
              child: SingleChildScrollView(child: content),
            ),
    );
  }
}

class _ValuePanel extends StatelessWidget {
  const _ValuePanel({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  final String label;
  final String value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest.withValues(
          alpha: 0.62,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.48),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: genUiMutedStyle(theme, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: RichText(
                text: TextSpan(
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                  children: [
                    TextSpan(text: value),
                    TextSpan(
                      text: ' $unit',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.item,
    required this.index,
    required this.isFirst,
    required this.isLast,
  });

  final _TimelineItem item;
  final int index;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = genUiColor(item.color, fallback: genUiPaletteColor(index));

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 34,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: 2,
                    color: isFirst
                        ? Colors.transparent
                        : theme.colorScheme.outlineVariant,
                  ),
                ),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: 0.55)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast
                        ? Colors.transparent
                        : theme.colorScheme.outlineVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLowest.withValues(
                    alpha: 0.58,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.48,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (item.time != null && item.time!.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: color.withValues(alpha: 0.28),
                                ),
                              ),
                              child: Text(
                                item.time!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(
                              item.title,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (item.description != null &&
                          item.description!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          item.description!,
                          style: genUiMutedStyle(theme, fontSize: 12),
                        ),
                      ],
                      if (item.takeaway != null &&
                          item.takeaway!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainer
                                .withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            item.takeaway!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem {
  const _TimelineItem({
    required this.title,
    this.time,
    this.description,
    this.takeaway,
    this.color,
  });

  final String title;
  final String? time;
  final String? description;
  final String? takeaway;
  final dynamic color;

  static List<_TimelineItem> fromList(dynamic value) {
    if (value is! List) {
      return const [];
    }

    final items = <_TimelineItem>[];
    for (final entry in value) {
      if (entry is Map) {
        final title = entry['title'] ?? entry['label'] ?? entry['name'];
        if (title == null || title.toString().trim().isEmpty) {
          continue;
        }
        items.add(
          _TimelineItem(
            title: title.toString(),
            time: genUiString(
              entry['time'] ?? entry['date'] ?? entry['period'],
            ),
            description: genUiString(
              entry['description'] ?? entry['text'] ?? entry['body'],
            ),
            takeaway: genUiString(
              entry['takeaway'] ?? entry['summary'] ?? entry['keyPoint'],
            ),
            color: entry['color'],
          ),
        );
      } else if (entry != null && entry.toString().trim().isNotEmpty) {
        items.add(_TimelineItem(title: entry.toString()));
      }
    }
    return items;
  }
}

class _UnitConversion {
  const _UnitConversion({
    required this.fromLabel,
    required this.toLabel,
    required this.fromSymbol,
    required this.toSymbol,
    required this.result,
    required this.precision,
    required this.steps,
    this.note,
  });

  final String fromLabel;
  final String toLabel;
  final String fromSymbol;
  final String toSymbol;
  final double result;
  final int precision;
  final List<String> steps;
  final String? note;

  static _UnitConversion? fromAttributes(
    Map<String, dynamic> attributes,
    double value,
  ) {
    final precision = (genUiInt(attributes['precision']) ?? 3).clamp(0, 8);

    final from = _UnitDefinition.lookup(
      attributes['fromUnit'] ?? attributes['from'],
    );
    final to = _UnitDefinition.lookup(attributes['toUnit'] ?? attributes['to']);
    if (from == null || to == null || from.category != to.category) {
      return null;
    }

    final result = _convert(value, from, to);

    return _UnitConversion(
      fromLabel: genUiString(attributes['fromLabel']) ?? from.name,
      toLabel: genUiString(attributes['toLabel']) ?? to.name,
      fromSymbol: genUiString(attributes['fromSymbol']) ?? from.symbol,
      toSymbol: genUiString(attributes['toSymbol']) ?? to.symbol,
      result: result,
      precision: precision,
      steps: _buildSteps(value, result, from, to, precision),
      note: genUiString(attributes['note']) ?? _defaultNote(from.category),
    );
  }

  static double _convert(
    double value,
    _UnitDefinition from,
    _UnitDefinition to,
  ) {
    if (from.category == _UnitCategory.temperature) {
      return to.fromBase(from.toBase(value));
    }
    return value * from.toBaseFactor / to.toBaseFactor;
  }

  static List<String> _buildSteps(
    double value,
    double result,
    _UnitDefinition from,
    _UnitDefinition to,
    int precision,
  ) {
    final formattedValue = genUiFormatPrecise(value, precision);
    final formattedResult = genUiFormatPrecise(result, precision);

    if (from.category == _UnitCategory.temperature) {
      final celsius = from.toBase(value);
      final formattedCelsius = genUiFormatPrecise(celsius, precision);
      return [
        '$formattedValue ${from.symbol} -> $formattedCelsius C',
        '$formattedCelsius C -> $formattedResult ${to.symbol}',
        '$formattedValue ${from.symbol} = $formattedResult ${to.symbol}',
      ];
    }

    return [
      'Convert ${from.symbol} to base unit: $formattedValue x '
          '${genUiFormatPrecise(from.toBaseFactor, precision)}',
      'Convert base unit to ${to.symbol}: divide by '
          '${genUiFormatPrecise(to.toBaseFactor, precision)}',
      '$formattedValue ${from.symbol} = $formattedResult ${to.symbol}',
    ];
  }

  static String _defaultNote(_UnitCategory category) {
    return switch (category) {
      _UnitCategory.length =>
        'Length conversions compare distances using meters as the shared '
            'base unit.',
      _UnitCategory.mass =>
        'Mass conversions compare quantities using grams as the shared base '
            'unit.',
      _UnitCategory.time =>
        'Time conversions compare durations using seconds as the shared base '
            'unit.',
      _UnitCategory.area =>
        'Area units grow by the square of the length conversion.',
      _UnitCategory.volume =>
        'Volume units grow by the cube of the length conversion.',
      _UnitCategory.speed =>
        'Speed compares distance traveled per unit of time.',
      _UnitCategory.temperature =>
        'Temperature uses formulas, not simple multiplication, because the '
            'scales have different zero points.',
    };
  }
}

class _UnitDefinition {
  const _UnitDefinition({
    required this.name,
    required this.symbol,
    required this.category,
    required this.aliases,
    this.toBaseFactor = 1,
    double Function(double value)? toBase,
    double Function(double value)? fromBase,
  }) : _toBase = toBase,
       _fromBase = fromBase;

  final String name;
  final String symbol;
  final _UnitCategory category;
  final List<String> aliases;
  final double toBaseFactor;
  final double Function(double value)? _toBase;
  final double Function(double value)? _fromBase;

  double toBase(double value) => _toBase?.call(value) ?? value * toBaseFactor;
  double fromBase(double value) =>
      _fromBase?.call(value) ?? value / toBaseFactor;

  static _UnitDefinition? lookup(dynamic value) {
    if (value == null) {
      return null;
    }

    final key = _normalizeUnit(value.toString());
    for (final unit in _units) {
      if (unit.aliases.any((alias) => _normalizeUnit(alias) == key)) {
        return unit;
      }
    }
    return null;
  }
}

enum _UnitCategory { length, mass, time, area, volume, speed, temperature }

String _normalizeUnit(String value) {
  return value.trim().toLowerCase().replaceAll('_', ' ');
}

const _units = [
  _UnitDefinition(
    name: 'Millimeter',
    symbol: 'mm',
    category: _UnitCategory.length,
    toBaseFactor: 0.001,
    aliases: ['mm', 'millimeter', 'millimeters'],
  ),
  _UnitDefinition(
    name: 'Centimeter',
    symbol: 'cm',
    category: _UnitCategory.length,
    toBaseFactor: 0.01,
    aliases: ['cm', 'centimeter', 'centimeters'],
  ),
  _UnitDefinition(
    name: 'Meter',
    symbol: 'm',
    category: _UnitCategory.length,
    aliases: ['m', 'meter', 'meters', 'metre', 'metres'],
  ),
  _UnitDefinition(
    name: 'Kilometer',
    symbol: 'km',
    category: _UnitCategory.length,
    toBaseFactor: 1000,
    aliases: ['km', 'kilometer', 'kilometers', 'kilometre', 'kilometres'],
  ),
  _UnitDefinition(
    name: 'Inch',
    symbol: 'in',
    category: _UnitCategory.length,
    toBaseFactor: 0.0254,
    aliases: ['in', 'inch', 'inches'],
  ),
  _UnitDefinition(
    name: 'Foot',
    symbol: 'ft',
    category: _UnitCategory.length,
    toBaseFactor: 0.3048,
    aliases: ['ft', 'foot', 'feet'],
  ),
  _UnitDefinition(
    name: 'Mile',
    symbol: 'mi',
    category: _UnitCategory.length,
    toBaseFactor: 1609.344,
    aliases: ['mi', 'mile', 'miles'],
  ),
  _UnitDefinition(
    name: 'Milligram',
    symbol: 'mg',
    category: _UnitCategory.mass,
    toBaseFactor: 0.001,
    aliases: ['mg', 'milligram', 'milligrams'],
  ),
  _UnitDefinition(
    name: 'Gram',
    symbol: 'g',
    category: _UnitCategory.mass,
    aliases: ['g', 'gram', 'grams'],
  ),
  _UnitDefinition(
    name: 'Kilogram',
    symbol: 'kg',
    category: _UnitCategory.mass,
    toBaseFactor: 1000,
    aliases: ['kg', 'kilogram', 'kilograms'],
  ),
  _UnitDefinition(
    name: 'Pound',
    symbol: 'lb',
    category: _UnitCategory.mass,
    toBaseFactor: 453.59237,
    aliases: ['lb', 'lbs', 'pound', 'pounds'],
  ),
  _UnitDefinition(
    name: 'Second',
    symbol: 's',
    category: _UnitCategory.time,
    aliases: ['s', 'sec', 'second', 'seconds'],
  ),
  _UnitDefinition(
    name: 'Minute',
    symbol: 'min',
    category: _UnitCategory.time,
    toBaseFactor: 60,
    aliases: ['min', 'minute', 'minutes'],
  ),
  _UnitDefinition(
    name: 'Hour',
    symbol: 'h',
    category: _UnitCategory.time,
    toBaseFactor: 3600,
    aliases: ['h', 'hr', 'hour', 'hours'],
  ),
  _UnitDefinition(
    name: 'Day',
    symbol: 'day',
    category: _UnitCategory.time,
    toBaseFactor: 86400,
    aliases: ['day', 'days'],
  ),
  _UnitDefinition(
    name: 'Square meter',
    symbol: 'm2',
    category: _UnitCategory.area,
    aliases: ['m2', 'sqm', 'square meter', 'square meters'],
  ),
  _UnitDefinition(
    name: 'Square centimeter',
    symbol: 'cm2',
    category: _UnitCategory.area,
    toBaseFactor: 0.0001,
    aliases: ['cm2', 'sqcm', 'square centimeter', 'square centimeters'],
  ),
  _UnitDefinition(
    name: 'Square kilometer',
    symbol: 'km2',
    category: _UnitCategory.area,
    toBaseFactor: 1000000,
    aliases: ['km2', 'sqkm', 'square kilometer', 'square kilometers'],
  ),
  _UnitDefinition(
    name: 'Liter',
    symbol: 'L',
    category: _UnitCategory.volume,
    aliases: ['l', 'liter', 'liters', 'litre', 'litres'],
  ),
  _UnitDefinition(
    name: 'Milliliter',
    symbol: 'mL',
    category: _UnitCategory.volume,
    toBaseFactor: 0.001,
    aliases: ['ml', 'milliliter', 'milliliters', 'millilitre', 'millilitres'],
  ),
  _UnitDefinition(
    name: 'Cubic meter',
    symbol: 'm3',
    category: _UnitCategory.volume,
    toBaseFactor: 1000,
    aliases: ['m3', 'cubic meter', 'cubic meters'],
  ),
  _UnitDefinition(
    name: 'Meter per second',
    symbol: 'm/s',
    category: _UnitCategory.speed,
    aliases: ['m/s', 'meter per second', 'meters per second'],
  ),
  _UnitDefinition(
    name: 'Kilometer per hour',
    symbol: 'km/h',
    category: _UnitCategory.speed,
    toBaseFactor: 0.2777777778,
    aliases: ['km/h', 'kph', 'kilometer per hour', 'kilometers per hour'],
  ),
  _UnitDefinition(
    name: 'Mile per hour',
    symbol: 'mph',
    category: _UnitCategory.speed,
    toBaseFactor: 0.44704,
    aliases: ['mph', 'mile per hour', 'miles per hour'],
  ),
  _UnitDefinition(
    name: 'Celsius',
    symbol: 'C',
    category: _UnitCategory.temperature,
    aliases: ['c', 'celsius'],
  ),
  _UnitDefinition(
    name: 'Fahrenheit',
    symbol: 'F',
    category: _UnitCategory.temperature,
    aliases: ['f', 'fahrenheit'],
    toBase: _fahrenheitToCelsius,
    fromBase: _celsiusToFahrenheit,
  ),
  _UnitDefinition(
    name: 'Kelvin',
    symbol: 'K',
    category: _UnitCategory.temperature,
    aliases: ['k', 'kelvin'],
    toBase: _kelvinToCelsius,
    fromBase: _celsiusToKelvin,
  ),
];

double _fahrenheitToCelsius(double value) => (value - 32) * 5 / 9;
double _celsiusToFahrenheit(double value) => value * 9 / 5 + 32;
double _kelvinToCelsius(double value) => value - 273.15;
double _celsiusToKelvin(double value) => value + 273.15;
