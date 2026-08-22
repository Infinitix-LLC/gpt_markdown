import 'package:flutter/material.dart';

import '../styles/checkbox_style.dart';

/// Constrains [child] to a square of [size].
///
/// A null size leaves the Material default alone, so a theme that sizes its
/// own checkboxes keeps working.
Widget _sized(double? size, Widget child) {
  if (size == null) {
    return child;
  }
  return SizedBox(width: size, height: size, child: child);
}

/// Wraps a marker and its label in the row layout both markers share.
///
/// The marker is rendered inside a `WidgetSpan`, and a paragraph lays inline
/// children out in scaled space — it hands them `maxWidth / scale` and
/// multiplies the reported size back. A child that also scales its own text is
/// counted twice, so the marker opts out, matching what `config.getRich` does
/// for nested paragraphs.
Widget _markerRow({
  required TextDirection textDirection,
  required double spacing,
  required Widget marker,
  required Widget child,
}) {
  return MediaQuery.withNoTextScaling(
    child: Directionality(
      textDirection: textDirection,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textBaseline: TextBaseline.alphabetic,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        children: [
          Text.rich(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  start: spacing,
                  end: spacing,
                ),
                child: marker,
              ),
            ),
          ),
          Flexible(child: child),
        ],
      ),
    ),
  );
}

/// A custom radio button widget that extends StatelessWidget.
class CustomRb extends StatelessWidget {
  const CustomRb({
    super.key,
    this.spacing = 5,
    required this.child,
    this.textDirection = TextDirection.ltr,
    required this.value,
    this.style = const CheckboxStyle(),
    this.onChanged,
  });

  /// The label beside the marker.
  final Widget child;

  /// Whether this option is selected.
  final bool value;

  /// Space either side of the marker.
  final double spacing;

  /// Text direction of the row.
  final TextDirection textDirection;

  /// Resolved appearance. Null fields keep the Material defaults.
  final CheckboxStyle style;

  /// Called when the marker is tapped, if [CheckboxStyle.interactive] is set.
  final void Function(bool value)? onChanged;

  @override
  Widget build(BuildContext context) {
    final checked = style.checkedColor;
    final interactive = style.interactive ?? false;
    final changed = onChanged;

    return _markerRow(
      textDirection: textDirection,
      spacing: spacing,
      marker: _sized(
        style.size,
        Radio<bool>(
          value: value,
          // Keep the package compatible with the declared Flutter >=3.0
          // range. RadioGroup is only available in newer Flutter SDKs.
          groupValue: true,
          onChanged: (v) {
            if (interactive && changed != null && v != null) {
              changed(v);
            }
          },
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          fillColor: checked == null ? null : WidgetStatePropertyAll(checked),
        ),
      ),
      child: child,
    );
  }
}

/// A custom checkbox widget that extends StatelessWidget.
class CustomCb extends StatelessWidget {
  const CustomCb({
    super.key,
    this.spacing = 5,
    required this.child,
    this.textDirection = TextDirection.ltr,
    required this.value,
    this.style = const CheckboxStyle(),
    this.onChanged,
  });

  /// The label beside the box.
  final Widget child;

  /// Whether the box is ticked.
  final bool value;

  /// Space either side of the box.
  final double spacing;

  /// Text direction of the row.
  final TextDirection textDirection;

  /// Resolved appearance. Null fields keep the Material defaults.
  final CheckboxStyle style;

  /// Called when the box is tapped, if [CheckboxStyle.interactive] is set.
  final void Function(bool value)? onChanged;

  @override
  Widget build(BuildContext context) {
    final unchecked = style.uncheckedColor;
    final radius = style.borderRadius;
    final interactive = style.interactive ?? false;
    final changed = onChanged;

    return _markerRow(
      textDirection: textDirection,
      spacing: spacing,
      marker: _sized(
        style.size,
        Checkbox(
          value: value,
          activeColor: style.checkedColor,
          checkColor: style.checkColor,
          side:
              unchecked == null ? null : BorderSide(color: unchecked, width: 2),
          shape:
              radius == null
                  ? null
                  : RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(radius),
                  ),
          onChanged: (next) {
            if (interactive && changed != null && next != null) {
              changed(next);
            }
          },
        ),
      ),
      child: child,
    );
  }
}
