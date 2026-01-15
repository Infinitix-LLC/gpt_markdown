part of 'gpt_markdown.dart';

/// Theme defined for `GptMarkdown` widget
class GptMarkdownThemeData extends ThemeExtension<GptMarkdownThemeData> {
  GptMarkdownThemeData._({
    required this.highlightColor,
    required this.h1,
    required this.h2,
    required this.h3,
    required this.h4,
    required this.h5,
    required this.h6,
    required this.hrLineThickness,
    required this.hrLineColor,
    required this.linkColor,
    required this.linkHoverColor,
  });

  /// A factory constructor for `GptMarkdownThemeData`.
  factory GptMarkdownThemeData({
    required Brightness brightness,
    Color? highlightColor,
    TextStyle? h1,
    TextStyle? h2,
    TextStyle? h3,
    TextStyle? h4,
    TextStyle? h5,
    TextStyle? h6,
    double? hrLineThickness,
    Color? hrLineColor,
    Color? linkColor,
    Color? linkHoverColor,
  }) {
    ThemeData themeData = ThemeData(
      brightness: brightness,
      colorScheme: brightness == Brightness.dark
          ? const ColorScheme.dark()
          : const ColorScheme.light(),
    );
    return GptMarkdownThemeData._fromTheme(themeData, themeData.textTheme).copyWith(
      highlightColor: highlightColor,
      h1: h1,
      h2: h2,
      h3: h3,
      h4: h4,
      h5: h5,
      h6: h6,
      hrLineThickness: hrLineThickness,
      hrLineColor: hrLineColor,
      linkColor: linkColor,
      linkHoverColor: linkHoverColor,
    );
  }

  factory GptMarkdownThemeData._fromTheme(
    ThemeData theme,
    TextTheme textTheme,
  ) {
    // Explicitly apply onSurface color to ensure headings have proper
    // text color, since TextTheme styles may rely on inheritance which
    // doesn't work reliably in all widget tree contexts.
    final Color textColor = theme.colorScheme.onSurface;
    return GptMarkdownThemeData._(
      highlightColor: theme.colorScheme.onSurfaceVariant.withAlpha(50),
      h1: textTheme.headlineLarge?.copyWith(color: textColor),
      h2: textTheme.headlineMedium?.copyWith(color: textColor),
      h3: textTheme.headlineSmall?.copyWith(color: textColor),
      h4: textTheme.titleLarge?.copyWith(color: textColor),
      h5: textTheme.titleMedium?.copyWith(color: textColor),
      h6: textTheme.titleSmall?.copyWith(color: textColor),
      hrLineThickness: 1,
      hrLineColor: theme.colorScheme.outline,
      linkColor: Colors.blue,
      linkHoverColor: Colors.red,
    );
  }

  /// The highlight color.
  Color highlightColor;

  /// The style of the h1 text.
  TextStyle? h1;

  /// The style of the h2 text.
  TextStyle? h2;

  /// The style of the h3 text.
  TextStyle? h3;

  /// The style of the h4 text.
  TextStyle? h4;

  /// The style of the h5 text.
  TextStyle? h5;

  /// The style of the h6 text.
  TextStyle? h6;
  double hrLineThickness;

  /// The color of the horizontal line.
  Color hrLineColor;

  /// The color of the link.
  Color linkColor;

  /// The color of the link when hovering.
  Color linkHoverColor;

  /// A method to copy the `GptMarkdownThemeData`.
  @override
  GptMarkdownThemeData copyWith({
    Color? highlightColor,
    TextStyle? h1,
    TextStyle? h2,
    TextStyle? h3,
    TextStyle? h4,
    TextStyle? h5,
    TextStyle? h6,
    double? hrLineThickness,
    Color? hrLineColor,
    Color? linkColor,
    Color? linkHoverColor,
  }) {
    return GptMarkdownThemeData._(
      highlightColor: highlightColor ?? this.highlightColor,
      h1: h1 ?? this.h1,
      h2: h2 ?? this.h2,
      h3: h3 ?? this.h3,
      h4: h4 ?? this.h4,
      h5: h5 ?? this.h5,
      h6: h6 ?? this.h6,
      hrLineThickness: hrLineThickness ?? this.hrLineThickness,
      hrLineColor: hrLineColor ?? this.hrLineColor,
      linkColor: linkColor ?? this.linkColor,
      linkHoverColor: linkHoverColor ?? this.linkHoverColor,
    );
  }

  @override
  GptMarkdownThemeData lerp(GptMarkdownThemeData? other, double t) {
    if (other == null) {
      return this;
    }
    return GptMarkdownThemeData._(
      highlightColor:
          Color.lerp(highlightColor, other.highlightColor, t) ?? highlightColor,
      h1: TextStyle.lerp(h1, other.h1, t) ?? h1,
      h2: TextStyle.lerp(h2, other.h2, t) ?? h2,
      h3: TextStyle.lerp(h3, other.h3, t) ?? h3,
      h4: TextStyle.lerp(h4, other.h4, t) ?? h4,
      h5: TextStyle.lerp(h5, other.h5, t) ?? h5,
      h6: TextStyle.lerp(h6, other.h6, t) ?? h6,
      hrLineThickness: Tween(
        begin: hrLineThickness,
        end: other.hrLineThickness,
      ).transform(t),
      hrLineColor: Color.lerp(hrLineColor, other.hrLineColor, t) ?? hrLineColor,
      linkColor: Color.lerp(linkColor, other.linkColor, t) ?? linkColor,
      linkHoverColor:
          Color.lerp(linkHoverColor, other.linkHoverColor, t) ?? linkHoverColor,
    );
  }
}

/// Wrap a `Widget` with `GptMarkdownTheme` to provide `GptMarkdownThemeData` in your intiar app.
class GptMarkdownTheme extends InheritedWidget {
  const GptMarkdownTheme({
    super.key,
    required this.gptThemeData,
    required super.child,
  });
  final GptMarkdownThemeData gptThemeData;

  /// A method to get the `GptMarkdownThemeData` from the `BuildContext`.
  static GptMarkdownThemeData of(BuildContext context) {
    var theme = Theme.of(context);
    final provider =
        context.dependOnInheritedWidgetOfExactType<GptMarkdownTheme>();
    if (provider != null) {
      return provider.gptThemeData;
    }
    final themeData = theme.extension<GptMarkdownThemeData>();
    if (themeData != null) {
      return themeData;
    }
    return GptMarkdownThemeData._fromTheme(theme, theme.textTheme);
  }

  @override
  bool updateShouldNotify(GptMarkdownTheme oldWidget) {
    return gptThemeData != oldWidget.gptThemeData;
  }
}
