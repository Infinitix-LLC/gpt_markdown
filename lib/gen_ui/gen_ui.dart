/// Built-in gen-UI widgets for `genui` markdown directives.
///
/// Wire them up by handing [GenUiRegistry.build] to `GptMarkdown`:
///
/// ```dart
/// final registry = GenUiRegistry.defaults();
///
/// GptMarkdown(markdown, genUiBuilder: registry.build);
/// ```
///
/// Registered out of the box: `text`, `image`, `button`, `line_chart`,
/// `area_chart`, `bar_chart`, `pie_chart`, `comparison_chart`,
/// `progress_list`, `metric_grid`, `unit_converter`, `timeline_flow`.
///
/// Everything here is painted with Flutter primitives, so the package adds no
/// charting, plotting, 3D, video, or backend dependencies.
library;

export 'gen_ui_markers.dart';
export 'gen_ui_mock_document.dart';
export 'gen_ui_preview_page.dart';
export 'gen_ui_registry.dart';
export 'src/gen_ui_basic_widgets.dart'
    show GenText, GenImage, GenButton, GenUiActionCallback;
export 'src/gen_ui_chart_painters.dart'
    show
        GenUiChartStyle,
        GenUiLineChartPainter,
        GenUiBarChartPainter,
        GenUiGroupedBarChartPainter,
        GenUiPieChartPainter;
export 'src/gen_ui_data_widgets.dart'
    show
        GenLineChart,
        GenBarChart,
        GenPieChart,
        GenComparisonChart,
        GenProgressList,
        GenMetricGrid;
export 'src/gen_ui_learning_widgets.dart' show GenUnitConverter, GenTimelineFlow;
export 'src/gen_ui_math.dart' show GenUiMath, genUiMathErrorFallback;
export 'src/gen_ui_plot_latex.dart' show GenPlotLatex;
export 'src/gen_ui_video.dart' show GenVideo;
export 'src/three_d/gen_ui_3d_graphs.dart'
    show
        GenUi3D,
        GenSurface3DGraph,
        GenPolarSurface3DGraph,
        GenSphericalSurface3DGraph,
        GenCylindricalSurface3DGraph;
export 'src/gen_ui_shells.dart'
    show
        GenUiChartCard,
        GenUiLearningCard,
        GenUiLegendItem,
        GenUiFormulaBox,
        GenUiLearningNote,
        GenUiSlider,
        genUiMutedStyle;
export 'src/gen_ui_values.dart'
    show
        GenUiPoint,
        GenUiItem,
        GenUiComparisonItem,
        GenUiMetricItem,
        genUiBool,
        genUiColor,
        genUiDouble,
        genUiFormatAxis,
        genUiFormatNumber,
        genUiFormatPrecise,
        genUiInt,
        genUiLabelsByIndex,
        genUiNiceTicks,
        genUiPalette,
        genUiPaletteColor,
        genUiString;
