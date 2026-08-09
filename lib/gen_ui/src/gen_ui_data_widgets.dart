import 'package:flutter/material.dart';

import 'gen_ui_chart_painters.dart';
import 'gen_ui_shells.dart';
import 'gen_ui_values.dart';

/// Data-visualization gen-UI widgets.
///
/// Each takes the raw `attributes` map from the gen-UI payload and renders
/// nothing (a zero-size box) when the payload has no usable data.

/// `line_chart` and, with [showArea], `area_chart`.
class GenLineChart extends StatelessWidget {
  const GenLineChart({
    super.key,
    required this.attributes,
    this.showArea = false,
  });

  final Map<String, dynamic> attributes;
  final bool showArea;

  @override
  Widget build(BuildContext context) {
    final points = GenUiPoint.fromList(attributes['points']);
    if (points.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final color = genUiColor(
      attributes['color'],
      fallback: theme.colorScheme.primary,
    );
    final maxY = points.map((point) => point.y).reduce((a, b) => a > b ? a : b);

    return GenUiChartCard(
      title: genUiString(attributes['title']),
      height: genUiDouble(attributes['height']) ?? 240,
      child: CustomPaint(
        size: Size.infinite,
        painter: GenUiLineChartPainter(
          points: points,
          color: color,
          style: GenUiChartStyle.of(context),
          curved: genUiBool(attributes['curved']) ?? true,
          showArea: showArea,
          minY: 0,
          maxY: maxY == 0 ? 1 : maxY * 1.2,
          textScaler: MediaQuery.textScalerOf(context),
          bottomLabels: genUiLabelsByIndex(attributes['labels']),
        ),
      ),
    );
  }
}

/// `bar_chart`.
class GenBarChart extends StatelessWidget {
  const GenBarChart({super.key, required this.attributes});

  final Map<String, dynamic> attributes;

  @override
  Widget build(BuildContext context) {
    final items = GenUiItem.fromList(attributes['values']);
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final fallbackColor = genUiColor(
      attributes['color'],
      fallback: theme.colorScheme.primary,
    );
    final maxY = items.map((item) => item.value).reduce((a, b) => a > b ? a : b);

    return GenUiChartCard(
      title: genUiString(attributes['title']),
      height: genUiDouble(attributes['height']) ?? 240,
      child: CustomPaint(
        size: Size.infinite,
        painter: GenUiBarChartPainter(
          values: [for (final item in items) item.value],
          colors: [
            for (final item in items)
              genUiColor(item.color, fallback: fallbackColor),
          ],
          labels: [for (final item in items) item.label],
          style: GenUiChartStyle.of(context),
          maxY: maxY == 0 ? 1 : maxY * 1.2,
          textScaler: MediaQuery.textScalerOf(context),
        ),
      ),
    );
  }
}

/// `pie_chart`, rendered as a donut with a legend beneath it.
class GenPieChart extends StatelessWidget {
  const GenPieChart({super.key, required this.attributes});

  final Map<String, dynamic> attributes;

  @override
  Widget build(BuildContext context) {
    final items = GenUiItem.fromList(attributes['values']);
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final colors = [
      for (var i = 0; i < items.length; i++)
        genUiColor(items[i].color, fallback: genUiPaletteColor(i)),
    ];

    return GenUiChartCard(
      title: genUiString(attributes['title']),
      height: genUiDouble(attributes['height']) ?? 260,
      child: Column(
        children: [
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: GenUiPieChartPainter(
                values: [for (final item in items) item.value],
                colors: colors,
                labels: [for (final item in items) item.label],
                style: GenUiChartStyle.of(context),
                textScaler: MediaQuery.textScalerOf(context),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              for (var i = 0; i < items.length; i++)
                GenUiLegendItem(
                  color: colors[i],
                  label:
                      '${items[i].label}: ${genUiFormatNumber(items[i].value)}',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// `comparison_chart`: grouped current-vs-target bars.
class GenComparisonChart extends StatelessWidget {
  const GenComparisonChart({super.key, required this.attributes});

  final Map<String, dynamic> attributes;

  @override
  Widget build(BuildContext context) {
    final items = GenUiComparisonItem.fromList(attributes['values']);
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final currentColor = genUiColor(
      attributes['currentColor'],
      fallback: theme.colorScheme.primary,
    );
    final targetColor = genUiColor(
      attributes['targetColor'],
      fallback: const Color(0xFF00CED1),
    );
    final maxY = items
        .expand((item) => [item.current, item.target])
        .reduce((a, b) => a > b ? a : b);

    return GenUiChartCard(
      title: genUiString(attributes['title']),
      height: genUiDouble(attributes['height']) ?? 280,
      child: Column(
        children: [
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: GenUiGroupedBarChartPainter(
                items: items,
                currentColor: currentColor,
                targetColor: targetColor,
                style: GenUiChartStyle.of(context),
                maxY: maxY == 0 ? 1 : maxY * 1.2,
                textScaler: MediaQuery.textScalerOf(context),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            children: [
              GenUiLegendItem(
                color: currentColor,
                label: genUiString(attributes['currentLabel']) ?? 'Current',
              ),
              GenUiLegendItem(
                color: targetColor,
                label: genUiString(attributes['targetLabel']) ?? 'Target',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// `progress_list`: labeled percentage bars.
class GenProgressList extends StatelessWidget {
  const GenProgressList({super.key, required this.attributes});

  final Map<String, dynamic> attributes;

  @override
  Widget build(BuildContext context) {
    final items = GenUiItem.fromList(attributes['values']);
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return GenUiChartCard(
      title: genUiString(attributes['title']),
      height: genUiDouble(attributes['height']) ?? (items.length * 48 + 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _ProgressRow(
              item: items[i],
              color: genUiColor(items[i].color, fallback: genUiPaletteColor(i)),
            ),
            if (i != items.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

/// `metric_grid`: compact metric tiles with an optional delta line.
class GenMetricGrid extends StatelessWidget {
  const GenMetricGrid({super.key, required this.attributes});

  final Map<String, dynamic> attributes;

  @override
  Widget build(BuildContext context) {
    final metrics = GenUiMetricItem.fromList(attributes['values']);
    if (metrics.isEmpty) {
      return const SizedBox.shrink();
    }

    return GenUiChartCard(
      title: genUiString(attributes['title']),
      height: genUiDouble(attributes['height']) ?? 180,
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (var i = 0; i < metrics.length; i++)
              _MetricTile(
                metric: metrics[i],
                color: genUiColor(
                  metrics[i].color,
                  fallback: genUiPaletteColor(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.item, required this.color});

  final GenUiItem item;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (item.value / 100).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(item.label, style: theme.textTheme.bodyMedium),
            ),
            Text(
              '${genUiFormatNumber(item.value)}%',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            color: color,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.metric, required this.color});

  final GenUiMetricItem metric;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 150,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(height: 10),
              Text(
                metric.value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                metric.label,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
              if (metric.delta != null && metric.delta!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  metric.delta!,
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
