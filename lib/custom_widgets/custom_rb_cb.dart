import 'package:flutter/material.dart';

/// A custom radio button widget that extends StatelessWidget.
///
/// The [CustomRb] widget is used to create a radio button in the UI.
/// It takes a [child] parameter which is the content of the radio button,
/// a [value] parameter which is the value of the radio button,
/// and an optional [spacing] parameter to set the spacing between the radio button and its label.
class CustomRb extends StatelessWidget {
  const CustomRb({
    super.key,
    this.spacing = 5,
    required this.child,
    this.textDirection = TextDirection.ltr,
    required this.value,
  });
  final Widget child;
  final bool value;
  final double spacing;
  final TextDirection textDirection;

  @override
  Widget build(BuildContext context) {
    return Directionality(
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
                child: RadioGroup(
                  onChanged: (value) {},
                  groupValue: true,
                  child: Radio(
                    value: value,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ),
          ),
          Flexible(child: child),
        ],
      ),
    );
  }
}

/// A custom checkbox widget that extends StatelessWidget.
///
/// The [CustomCb] widget is used to create a checkbox in the UI.
/// It takes a [child] parameter which is the content of the checkbox,
/// a [value] parameter which is the value of the checkbox,
/// and an optional [spacing] parameter to set the spacing between the checkbox and its label.
class CustomCb extends StatelessWidget {
  const CustomCb({
    super.key,
    this.spacing = 5,
    required this.child,
    this.textDirection = TextDirection.ltr,
    required this.value,
  });
  final Widget child;
  final bool value;
  final double spacing;
  final TextDirection textDirection;

  @override
  Widget build(BuildContext context) {
    return Directionality(
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
                child: Checkbox(value: value, onChanged: (value) {}),
              ),
            ),
          ),
          Flexible(child: child),
        ],
      ),
    );
  }
}
