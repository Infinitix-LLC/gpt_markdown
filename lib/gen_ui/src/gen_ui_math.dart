import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

/// LaTeX rendering for gen-UI cards.
///
/// Wraps `Math.tex` so the formula inherits the ambient [DefaultTextStyle] —
/// size, weight, and color — instead of the library defaults, which is what
/// makes a formula sit correctly inside a card next to normal text.
class GenUiMath extends StatelessWidget {
  const GenUiMath.tex(
    this.tex, {
    super.key,
    this.textScaler,
    this.options,
    this.textStyle,
    this.mathStyle = MathStyle.display,
    this.onErrorFallback = genUiMathErrorFallback,
  });

  final String tex;
  final TextScaler? textScaler;
  final MathOptions? options;
  final TextStyle? textStyle;
  final MathStyle mathStyle;
  final Widget Function(FlutterMathException) onErrorFallback;

  @override
  Widget build(BuildContext context) {
    return Math.tex(
      tex,
      textStyle: textStyle,
      onErrorFallback: onErrorFallback,
      options: options ?? _optionsFromTextStyle(context),
      mathStyle: mathStyle,
    );
  }

  MathOptions _optionsFromTextStyle(BuildContext context) {
    var effectiveTextStyle = DefaultTextStyle.of(context).style.merge(textStyle);
    if (MediaQuery.boldTextOf(context)) {
      effectiveTextStyle = effectiveTextStyle.merge(
        const TextStyle(fontWeight: FontWeight.bold),
      );
    }

    final fontSize = effectiveTextStyle.fontSize ?? 14;
    final fontWeight = effectiveTextStyle.fontWeight;

    return MathOptions(
      style: mathStyle,
      fontSize: (textScaler ?? MediaQuery.textScalerOf(context)).scale(fontSize),
      mathFontOptions: fontWeight != null && fontWeight != FontWeight.normal
          ? FontOptions(fontWeight: fontWeight)
          : null,
      color: effectiveTextStyle.color ??
          DefaultTextStyle.of(context).style.color ??
          Theme.of(context).colorScheme.onSurface,
    );
  }
}

/// Shows the parse error rather than an empty box: a formula that silently
/// vanishes reads as a rendering bug, while the message points at the payload.
Widget genUiMathErrorFallback(FlutterMathException error) =>
    SelectableText(error.messageWithType);
