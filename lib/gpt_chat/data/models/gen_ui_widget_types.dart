/// Gen-UI widget names the gateway understands, as sent in
/// `x_plusfinity.widgets`. An unknown name returns `400` naming it.
///
/// These are wire values. Whether a widget can actually be drawn depends on
/// the `GenUiRegistry` handed to the chat — the [optIn] ones need a renderer
/// you register yourself.
abstract final class GenUiWidgetTypes {
  /// Enabled by `"widgets": true`, and rendered by `GenUiRegistry.defaults()`.
  static const List<String> defaults = [
    'line_chart',
    'area_chart',
    'bar_chart',
    'pie_chart',
    'comparison_chart',
    'progress_list',
    'metric_grid',
    'unit_converter',
    'timeline_flow',
  ];

  /// Described to the model only when named, or by `"widgets": "all"`.
  static const List<String> optIn = [
    'text',
    'image',
    'button',
    'video',
    'plot_latex',
    'surface_3d',
    'polar_surface_3d',
    'spherical_surface_3d',
    'cylindrical_surface_3d',
  ];

  static const List<String> all = [...defaults, ...optIn];

  static bool isKnown(String type) => all.contains(type);
}
