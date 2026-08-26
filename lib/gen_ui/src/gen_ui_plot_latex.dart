import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:plot_latex/plot_latex.dart';

import 'gen_ui_math.dart';
import 'gen_ui_values.dart';

/// `plot_latex`: an interactive 2D graph of one or more LaTeX equations.
///
/// Inline the plot is a static preview — panning inside a scrolling answer
/// would fight the scroll gesture — and tapping opens a dialog where pan and
/// zoom are live.
class GenPlotLatex extends StatelessWidget {
  const GenPlotLatex({super.key, required this.attributes});

  final Map<String, dynamic> attributes;

  /// Series colors, matching the rest of the gen-UI palette.
  static const List<Color> _equationColors = genUiPalette;

  /// Wraps a bare equation in `$…$` so the plot parser sees LaTeX; an
  /// already-delimited string is passed through untouched.
  static String plotTex(String equation) {
    final trimmed = equation.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    if (trimmed.startsWith(r'$') ||
        trimmed.startsWith(r'\(') ||
        trimmed.startsWith(r'\[')) {
      return trimmed;
    }
    return '\$$trimmed\$';
  }

  @override
  Widget build(BuildContext context) {
    final equation =
        genUiString(attributes['equation'] ?? attributes['equations']) ?? 'x^2';
    final controller = PlotController.fromTex(
      plotTex(equation),
      _equationColors,
    );

    if (controller.equations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: _PlotCard(
        controller: controller,
        title: genUiString(attributes['title']) ?? 'Graph',
        isDialog: false,
      ),
    );
  }
}

class _PlotCard extends StatelessWidget {
  const _PlotCard({
    required this.controller,
    required this.title,
    required this.isDialog,
  });

  final PlotController controller;
  final String title;
  final bool isDialog;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final body = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: isDialog ? 420 : double.infinity),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: _PlotHeader(title: title, isDialog: isDialog),
          ),
          AspectRatio(
            aspectRatio: (isDialog && !kIsWeb) ? 1 : 4 / 3,
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: PloatLatexView(
                        controller: controller,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerLowest,
                        xAxisColor: theme.colorScheme.onSurface,
                        yAxisColor: theme.colorScheme.onSurface,
                        lineColor: theme.colorScheme.onSurface,
                        textColor: theme.colorScheme.onSurface,
                        textBackgroundColor: theme.colorScheme.surface
                            .withAlpha(150),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: _PlotLegend(controller: controller),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (isDialog) {
      return Dialog(
        backgroundColor: theme.colorScheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        child: body,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap:
            () => showDialog<void>(
              context: context,
              builder:
                  (context) => _PlotCard(
                    controller: controller,
                    title: title,
                    isDialog: true,
                  ),
            ),
        // The preview must not swallow drags: the plot view would consume them
        // and the surrounding answer would stop scrolling.
        child: IgnorePointer(child: body),
      ),
    );
  }
}

class _PlotHeader extends StatelessWidget {
  const _PlotHeader({required this.title, required this.isDialog});

  final String title;
  final bool isDialog;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: Text(title, style: theme.textTheme.titleMedium),
            ),
            Row(
              mainAxisAlignment:
                  isDialog ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                if (!isDialog) ...const [
                  Icon(Icons.pan_tool_alt_outlined, size: 20),
                  SizedBox(width: 4),
                  Text('Open'),
                ],
                if (isDialog)
                  SizedBox(
                    width: 25,
                    height: 25,
                    child: IconButton.filledTonal(
                      style: IconButton.styleFrom(
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.close),
                    ),
                  ),
              ],
            ),
          ],
        ),
        if (isDialog) ...[
          const SizedBox(height: 10),
          const Row(
            children: [
              Icon(Icons.pan_tool_alt_outlined, size: 20),
              SizedBox(width: 10),
              Text('Touch to move'),
              Spacer(),
              Icon(Icons.pinch_outlined, size: 20),
              SizedBox(width: 10),
              Text('zoom in/out'),
            ],
          ),
        ],
      ],
    );
  }
}

class _PlotLegend extends StatelessWidget {
  const _PlotLegend({required this.controller});

  final PlotController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 100, maxHeight: 90),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Material(
          color: theme.colorScheme.surfaceContainerLowest,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: FittedBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final equation in controller.equations)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '~',
                          style: TextStyle(color: equation.color, fontSize: 22),
                        ),
                        const SizedBox(width: 5),
                        GenUiMath.tex(
                          equation.title,
                          textScaler: const TextScaler.linear(1.3),
                          textStyle: TextStyle(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
