import 'package:flutter/material.dart';

/// Shared chrome for the built-in gen-UI widgets: the card shells, the legend
/// row, and the slider used by interactive cards.
///
/// Everything here is theme-driven so a host app restyles the whole gen-UI set
/// through its [ThemeData] rather than through per-widget parameters.

/// Plain surface card used by the data-visualization widgets.
class GenUiChartCard extends StatelessWidget {
  const GenUiChartCard({
    super.key,
    required this.child,
    required this.height,
    this.title,
  });

  final Widget child;
  final String? title;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null && title!.isNotEmpty) ...[
                Text(title!, style: theme.textTheme.titleMedium),
                const SizedBox(height: 16),
              ],
              SizedBox(height: height, width: double.infinity, child: child),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card shell with a leading icon and optional subtitle, used by the
/// student-learning widgets.
class GenUiLearningCard extends StatelessWidget {
  const GenUiLearningCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outline.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(
                          alpha: 0.32,
                        ),
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: theme.colorScheme.onSurface,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: theme.textTheme.titleMedium),
                        if (subtitle != null && subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: genUiMutedStyle(theme, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Colored dot plus label, used under pie and comparison charts.
class GenUiLegendItem extends StatelessWidget {
  const GenUiLegendItem({super.key, required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

/// A boxed, monospaced-feeling list of derivation lines.
class GenUiFormulaBox extends StatelessWidget {
  const GenUiFormulaBox({super.key, required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < lines.length; i++) ...[
            Text(
              lines[i],
              style: theme.textTheme.bodySmall?.copyWith(
                color:
                    i == lines.length - 1
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight:
                    i == lines.length - 1 ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (i != lines.length - 1) const SizedBox(height: 5),
          ],
        ],
      ),
    );
  }
}

/// Tinted "did you notice" note shown at the bottom of learning cards.
class GenUiLearningNote extends StatelessWidget {
  const GenUiLearningNote({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            color: theme.colorScheme.primary,
            size: 17,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Slider styled to match the gen-UI cards: a wide flat track with an outlined
/// thumb.
class GenUiSlider extends StatelessWidget {
  const GenUiSlider({
    super.key,
    required this.min,
    required this.max,
    required this.value,
    required this.label,
    required this.onChanged,
    this.divisions,
  });

  final double min;
  final double max;
  final double value;
  final String label;
  final ValueChanged<double> onChanged;
  final int? divisions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 20,
        trackShape: const RoundedRectSliderTrackShape(),
        activeTrackColor: theme.colorScheme.outline.withValues(alpha: 0.14),
        inactiveTrackColor: theme.colorScheme.surfaceContainerLowest.withValues(
          alpha: 0.9,
        ),
        overlayColor: theme.colorScheme.outline.withValues(alpha: 0.14),
        valueIndicatorColor: theme.colorScheme.surfaceBright,
        valueIndicatorTextStyle: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        thumbShape: _OutlinedSliderThumbShape(
          fillColor: theme.colorScheme.outline.withValues(alpha: 0.14),
          outlineColor: theme.colorScheme.outline.withValues(alpha: 0.48),
        ),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 22),
        tickMarkShape: SliderTickMarkShape.noTickMark,
      ),
      child: Slider(
        padding: EdgeInsets.zero,
        min: min,
        max: max,
        value: value.clamp(min, max),
        divisions: divisions,
        label: label,
        onChanged: onChanged,
      ),
    );
  }
}

class _OutlinedSliderThumbShape extends SliderComponentShape {
  const _OutlinedSliderThumbShape({
    required this.fillColor,
    required this.outlineColor,
  });

  final Color fillColor;
  final Color outlineColor;
  static const double _radius = 11;
  static const double _outlineWidth = 1;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(_radius + _outlineWidth);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    final activeScale = 1 + activationAnimation.value * 0.08;
    final thumbRadius = _radius * activeScale;

    canvas.drawCircle(
      center,
      thumbRadius + 3,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.07)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(center, thumbRadius, Paint()..color = fillColor);
    canvas.drawCircle(
      center,
      thumbRadius - _outlineWidth / 2,
      Paint()
        ..color = outlineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = _outlineWidth,
    );
  }
}

/// Muted secondary text style shared by labels and captions.
TextStyle genUiMutedStyle(ThemeData theme, {double fontSize = 12}) {
  return theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontSize: fontSize,
      ) ??
      TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: fontSize);
}
