import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'src/gen_ui_basic_widgets.dart';
import 'src/gen_ui_data_widgets.dart';
import 'src/gen_ui_learning_widgets.dart';

/// One widget request from a gen-UI payload: the top-level key is [type], its
/// value is [attributes].
@immutable
class GenUiModel {
  const GenUiModel({required this.type, required this.attributes});

  final String type;
  final Map<String, dynamic> attributes;

  @override
  String toString() => 'GenUiModel($type, ${attributes.keys.toList()})';
}

/// Outcome of decoding a gen-UI payload. [error] is non-null when the payload
/// was not a JSON object; [models] is then empty.
@immutable
class GenUiPayload {
  const GenUiPayload({required this.models, this.error});

  final List<GenUiModel> models;
  final String? error;

  bool get hasError => error != null;
}

/// Decodes the JSON object between the gen-UI markers.
///
/// Every top-level key becomes one [GenUiModel]. Values that are not objects
/// are wrapped as `{'value': <value>}` so simple forms such as
/// `{"text": "hi"}` still work.
GenUiPayload parseGenUiPayload(String payload) {
  final trimmed = payload.trim();
  if (trimmed.isEmpty) {
    return const GenUiPayload(models: [], error: 'Empty gen UI payload');
  }

  final Object? decoded;
  try {
    decoded = jsonDecode(trimmed);
  } on FormatException catch (error) {
    return GenUiPayload(models: const [], error: 'Invalid JSON: ${error.message}');
  }

  if (decoded is! Map) {
    return const GenUiPayload(
      models: [],
      error: 'Gen UI payload must be a JSON object',
    );
  }

  return GenUiPayload(
    models: [
      for (final entry in decoded.entries)
        GenUiModel(
          type: entry.key.toString(),
          attributes: entry.value is Map
              ? Map<String, dynamic>.from(entry.value as Map)
              : <String, dynamic>{'value': entry.value},
        ),
    ],
  );
}

/// Builds the widget for one decoded [GenUiModel].
typedef GenUiWidgetBuilder = Widget Function(
  BuildContext context,
  GenUiModel model,
);

/// Maps gen-UI widget types to builders.
///
/// [GenUiRegistry.defaults] pre-registers everything this package renders
/// without extra dependencies. Types the package does not own — `plot_latex`,
/// `surface_3d`, `polar_surface_3d`, `spherical_surface_3d`,
/// `cylindrical_surface_3d`, `video`, `val_scene` — are left unregistered so a
/// host app can plug in its own renderers:
///
/// ```dart
/// final registry = GenUiRegistry.defaults()
///   ..register('video', (context, model) => MyVideo(model.attributes))
///   ..register('bar_chart', (context, model) => MyBranded(model.attributes));
///
/// GptMarkdown(text, genUiBuilder: registry.build);
/// ```
class GenUiRegistry {
  /// A registry with no builders. Every type falls through to
  /// [unknownBuilder].
  GenUiRegistry.empty({this.unknownBuilder, this.errorBuilder});

  /// Registry with all built-in widgets registered.
  ///
  /// [onAction] receives `button` presses; without it, buttons render
  /// disabled.
  factory GenUiRegistry.defaults({
    GenUiActionCallback? onAction,
    GenUiWidgetBuilder? unknownBuilder,
    Widget Function(BuildContext context, String message)? errorBuilder,
  }) {
    return GenUiRegistry.empty(
      unknownBuilder: unknownBuilder,
      errorBuilder: errorBuilder,
    )..registerAll({
        // Always registered, regardless of which widgets a host wires up: the
        // gateway sends this precisely when something else could not be
        // rendered, so leaving it out would reinstate the gap it exists to fill.
        'genui_error': (context, model) => GenUiError(attributes: model.attributes),
        'text': (context, model) => GenText(attributes: model.attributes),
        'image': (context, model) => GenImage(attributes: model.attributes),
        'button': (context, model) =>
            GenButton(attributes: model.attributes, onAction: onAction),
        'line_chart': (context, model) =>
            GenLineChart(attributes: model.attributes),
        'area_chart': (context, model) =>
            GenLineChart(attributes: model.attributes, showArea: true),
        'bar_chart': (context, model) =>
            GenBarChart(attributes: model.attributes),
        'pie_chart': (context, model) =>
            GenPieChart(attributes: model.attributes),
        'comparison_chart': (context, model) =>
            GenComparisonChart(attributes: model.attributes),
        'progress_list': (context, model) =>
            GenProgressList(attributes: model.attributes),
        'metric_grid': (context, model) =>
            GenMetricGrid(attributes: model.attributes),
        'unit_converter': (context, model) =>
            GenUnitConverter(attributes: model.attributes),
        'timeline_flow': (context, model) =>
            GenTimelineFlow(attributes: model.attributes),
      });
  }

  final Map<String, GenUiWidgetBuilder> _builders = {};

  /// Renders types with no registered builder. Defaults to rendering nothing.
  final GenUiWidgetBuilder? unknownBuilder;

  /// Renders decode failures. Defaults to a debug-only error chip.
  final Widget Function(BuildContext context, String message)? errorBuilder;

  /// Widget types this registry can render.
  Iterable<String> get types => _builders.keys;

  bool contains(String type) => _builders.containsKey(type);

  GenUiWidgetBuilder? builderFor(String type) => _builders[type];

  /// Registers (or replaces) the builder for [type].
  void register(String type, GenUiWidgetBuilder builder) {
    _builders[type] = builder;
  }

  void registerAll(Map<String, GenUiWidgetBuilder> builders) {
    _builders.addAll(builders);
  }

  void unregister(String type) {
    _builders.remove(type);
  }

  /// A copy of this registry, so a host can extend the defaults without
  /// mutating a shared instance.
  GenUiRegistry clone() {
    return GenUiRegistry.empty(
      unknownBuilder: unknownBuilder,
      errorBuilder: errorBuilder,
    )..registerAll(_builders);
  }

  /// Builds one model, going through [unknownBuilder] for unregistered types.
  Widget buildModel(BuildContext context, GenUiModel model) {
    final builder = _builders[model.type];
    if (builder != null) {
      return builder(context, model);
    }
    return unknownBuilder?.call(context, model) ?? const SizedBox.shrink();
  }

  /// Decodes [payload] and builds every widget in it, stacked in a column.
  ///
  /// Matches `GenUiBuilder`, so it can be passed straight to
  /// `GptMarkdown(genUiBuilder: registry.build)`.
  Widget build(BuildContext context, String payload) {
    final parsed = parseGenUiPayload(payload);
    if (parsed.hasError) {
      return _buildError(context, parsed.error!);
    }
    if (parsed.models.isEmpty) {
      return const SizedBox.shrink();
    }
    if (parsed.models.length == 1) {
      return buildModel(context, parsed.models.single);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final model in parsed.models) buildModel(context, model),
      ],
    );
  }

  Widget _buildError(BuildContext context, String message) {
    final builder = errorBuilder;
    if (builder != null) {
      return builder(context, message);
    }
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: theme.colorScheme.onErrorContainer,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// Renders a raw gen-UI payload with [registry], or with a fresh default
/// registry when none is given.
class GenUiView extends StatelessWidget {
  const GenUiView({super.key, required this.payload, this.registry});

  final String payload;
  final GenUiRegistry? registry;

  @override
  Widget build(BuildContext context) {
    return (registry ?? GenUiRegistry.defaults()).build(context, payload);
  }
}
