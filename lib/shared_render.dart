part of 'gpt_markdown.dart';

/// Rendering shared by the two parsers.
///
/// The regex pipeline ([MarkdownComponent.generate]) and the plusparse
/// renderer disagree about how a block's *content* is produced — one re-runs
/// components over a substring, the other already holds a parsed AST — but
/// everything after that point is identical: resolve the style, hand off to a
/// caller-supplied builder if there is one, otherwise build the default
/// widget. Keeping that half here means a change to a default, a style field
/// or a builder hook lands on both paths at once.
///
/// Each function takes the content as a already-built [Widget] or as a
/// callback, which is the only part the two parsers need to supply themselves.

/// The horizontal rule, honouring [GptMarkdownConfig.hrBuilder] and
/// [HrStyle].
Widget hrWidget(BuildContext context, GptMarkdownConfig config) {
  final gptTheme = GptMarkdownTheme.of(context);
  final style = (resolvedStyleSheet(context, config).hr ?? const HrStyle())
      .resolve(Theme.of(context).colorScheme);
  final builder = config.hrBuilder;
  if (builder != null) {
    return builder(context, style);
  }
  final padding = style.padding;
  return CustomDivider(
    height: style.thickness ?? gptTheme.hrLineThickness,
    color: style.color ?? gptTheme.hrLineColor,
    padding: padding is EdgeInsets ? padding : gptTheme.hrLinePadding,
  );
}

/// A task-list checkbox with [label] beside it, honouring
/// [GptMarkdownConfig.checkboxBuilder], [CheckboxStyle] and
/// [GptMarkdownConfig.onCheckboxChanged].
Widget checkboxWidget(
  BuildContext context,
  GptMarkdownConfig config, {
  required bool checked,
  required Widget label,
}) {
  final style = (resolvedStyleSheet(context, config).checkbox ??
          const CheckboxStyle())
      .resolve(Theme.of(context).colorScheme);
  final builder = config.checkboxBuilder;
  if (builder != null) {
    return builder(context, checked, label, style);
  }
  return CustomCb(
    value: checked,
    textDirection: config.textDirection,
    spacing: style.gapAfterBox ?? 5,
    style: style,
    onChanged: config.onCheckboxChanged,
    child: label,
  );
}

/// A radio option with [label] beside it, honouring
/// [GptMarkdownConfig.radioOptionBuilder] and [CheckboxStyle].
Widget radioWidget(
  BuildContext context,
  GptMarkdownConfig config, {
  required bool selected,
  required Widget label,
}) {
  final style = (resolvedStyleSheet(context, config).checkbox ??
          const CheckboxStyle())
      .resolve(Theme.of(context).colorScheme);
  final builder = config.radioOptionBuilder;
  if (builder != null) {
    return builder(context, selected, label, style);
  }
  return CustomRb(
    value: selected,
    textDirection: config.textDirection,
    spacing: style.gapAfterBox ?? 5,
    style: style,
    onChanged: config.onCheckboxChanged,
    child: label,
  );
}

/// A heading of [level], honouring [GptMarkdownConfig.headingBuilder] and
/// [HeadingStyle].
///
/// [buildChildren] receives the heading-scoped config — the level's text style
/// merged with any [HeadingStyle.textStyle] override, and
/// [MarkdownScope.heading] — and returns the spans for the heading's own
/// content. Each parser supplies that differently.
Widget headingWidget(
  BuildContext context,
  GptMarkdownConfig config, {
  required int level,
  required List<InlineSpan> Function(GptMarkdownConfig conf) buildChildren,
}) {
  final theme = GptMarkdownTheme.of(context);
  final headingStyle = (resolvedStyleSheet(context, config).heading ??
          const HeadingStyle())
      .resolve(Theme.of(context).colorScheme);
  final levelStyle =
      [theme.h1, theme.h2, theme.h3, theme.h4, theme.h5, theme.h6][level - 1];
  final override = headingStyle.textStyle;
  final conf = config.copyWith(
    scope: MarkdownScope.heading,
    style:
        override == null
            ? levelStyle
            : (levelStyle ?? const TextStyle()).merge(override),
  );

  final builder = config.headingBuilder;
  if (builder != null) {
    final content = config.getRich(TextSpan(children: buildChildren(conf)));
    return builder(context, level, content, headingStyle);
  }

  final dividerPadding = headingStyle.dividerPadding;
  final rich = config.getRich(
    TextSpan(
      children: [
        ...buildChildren(conf),
        if (level == 1 &&
            (headingStyle.showDivider ?? theme.autoAddDividerLineAfterH1)) ...[
          const TextSpan(text: "\n ", style: TextStyle(fontSize: 0, height: 0)),
          // Left uncompensated on purpose. The rule is a one-pixel decoration
          // with no text in it, so the paragraph scaling its box is invisible —
          // and compensating it made the space it takes at 1x differ from every
          // other scale.
          WidgetSpan(
            child: CustomDivider(
              height: headingStyle.dividerThickness ?? theme.hrLineThickness,
              color: headingStyle.dividerColor ?? theme.hrLineColor,
              padding:
                  dividerPadding is EdgeInsets
                      ? dividerPadding
                      : theme.hrLinePadding,
            ),
          ),
        ],
      ],
    ),
  );

  final headingPadding = headingStyle.padding;
  if (headingPadding == null) {
    return rich;
  }
  return Padding(padding: headingPadding, child: rich);
}

/// A block quote, honouring [GptMarkdownConfig.blockQuoteBuilder] and
/// [BlockQuoteStyle].
///
/// [buildContent] receives the quote-scoped config — the surrounding style
/// merged with any [BlockQuoteStyle.textStyle] override — and returns the
/// quote's rendered body.
InlineSpan blockQuoteSpan(
  BuildContext context,
  GptMarkdownConfig config, {
  required Widget Function(GptMarkdownConfig conf) buildContent,
}) {
  final style = (resolvedStyleSheet(context, config).blockQuote ??
          const BlockQuoteStyle())
      .resolve(Theme.of(context).colorScheme);

  var quotedConfig = config;
  final textStyle = style.textStyle;
  if (textStyle != null) {
    final base = config.style;
    quotedConfig = config.copyWith(
      style: base == null ? textStyle : base.merge(textStyle),
    );
  }
  final content = buildContent(quotedConfig);

  final builder = config.blockQuoteBuilder;
  final Widget quote =
      builder == null
          ? defaultQuoteWidget(context, content, style, config.textDirection)
          : builder(context, content, style);

  return TextSpan(
    children: [
      scaledWidgetSpan(
        config: config,
        alignment: PlaceholderAlignment.bottom,
        baseline: null,
        child: quote,
      ),
    ],
  );
}

/// The default block quote: a bar, optional padding, background and margin.
Widget defaultQuoteWidget(
  BuildContext context,
  Widget content,
  BlockQuoteStyle style,
  TextDirection direction,
) {
  final padding = style.padding;
  final margin = style.margin;
  final background = style.backgroundColor;

  Widget child = content;
  if (padding != null) {
    child = Padding(padding: padding, child: child);
  }
  child = BlockQuoteWidget(
    color: style.barColor ?? Theme.of(context).colorScheme.onSurfaceVariant,
    direction: direction,
    width: style.barWidth ?? 3,
    child: child,
  );
  if (background != null) {
    final radius = style.barRadius;
    child = DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: radius == null ? null : BorderRadius.all(radius),
      ),
      child: child,
    );
  }
  if (margin != null) {
    child = Padding(padding: margin, child: child);
  }
  return Directionality(textDirection: direction, child: child);
}

/// A citation tag such as `[1]`, honouring [GptMarkdownConfig.sourceTagBuilder],
/// [SourceTagStyle] and [GptMarkdownConfig.onSourceTagTap].
InlineSpan sourceTagSpan(
  BuildContext context,
  String id,
  GptMarkdownConfig config,
) {
  final style = (resolvedStyleSheet(context, config).sourceTag ??
          const SourceTagStyle())
      .resolve(Theme.of(context).colorScheme);
  final size = style.size ?? 20;
  Widget chip =
      config.sourceTagBuilder?.call(
        context,
        id,
        style.textStyle ?? const TextStyle(),
      ) ??
      SizedBox(
        width: size,
        height: size,
        child: Material(
          color:
              style.backgroundColor ??
              Theme.of(context).colorScheme.onInverseSurface,
          shape:
              style.shape == BoxShape.rectangle
                  ? const RoundedRectangleBorder()
                  : const OvalBorder(),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              id,
              style: style.textStyle,
              textDirection: config.textDirection,
            ),
          ),
        ),
      );

  final onTap = config.onSourceTagTap;
  if (onTap != null) {
    chip = GestureDetector(onTap: () => onTap(id), child: chip);
  }

  return scaledWidgetSpan(
    config: config,
    alignment: PlaceholderAlignment.middle,
    baseline: null,
    child: Padding(
      padding: style.padding ?? const EdgeInsets.all(2),
      child: chip,
    ),
  );
}

/// A fenced code block, honouring [GptMarkdownConfig.codeBuilder],
/// [CodeBlockStyle] and [GptMarkdownConfig.onCodeCopy].
Widget codeBlockWidget(
  BuildContext context,
  GptMarkdownConfig config, {
  required String name,
  required String code,
  required bool closed,
}) {
  final style = (resolvedStyleSheet(context, config).codeBlock ??
          const CodeBlockStyle())
      .resolve(Theme.of(context).colorScheme);
  return config.codeBuilder?.call(context, name, code, closed) ??
      CodeField(
        name: name,
        codes: code,
        style: style,
        onCopy: config.onCodeCopy,
      );
}

/// One bullet-list item, honouring [GptMarkdownConfig.unOrderedListBuilder]
/// and [ListStyle].
Widget unorderedListItem(
  BuildContext context,
  GptMarkdownConfig config,
  Widget child,
) {
  final builder = config.unOrderedListBuilder;
  if (builder != null) {
    return builder(context, child, config.copyWith());
  }
  final style = (resolvedStyleSheet(context, config).list ?? const ListStyle())
      .resolve(Theme.of(context).colorScheme);
  final fontSize =
      config.style?.fontSize ??
      DefaultTextStyle.of(context).style.fontSize ??
      kDefaultFontSize;
  return UnorderedListView(
    bulletColor:
        style.bulletColor ??
        config.style?.color ??
        DefaultTextStyle.of(context).style.color,
    padding: style.indent ?? 7,
    spacing: style.gapAfterMarker ?? 10,
    bulletSize: style.bulletSize ?? 0.3 * fontSize,
    textDirection: config.textDirection,
    child: child,
  );
}

/// One numbered-list item, honouring [GptMarkdownConfig.orderedListBuilder]
/// and [ListStyle]. [no] is the number without its trailing dot.
Widget orderedListItem(
  BuildContext context,
  GptMarkdownConfig config,
  String no,
  Widget child,
) {
  final builder = config.orderedListBuilder;
  if (builder != null) {
    return builder(context, no, child, config.copyWith());
  }
  final style = (resolvedStyleSheet(context, config).list ?? const ListStyle())
      .resolve(Theme.of(context).colorScheme);
  final marker = style.markerTextStyle;
  final base = (config.style ?? const TextStyle()).copyWith(
    fontWeight: FontWeight.w100,
  );
  return OrderedListView(
    no: "$no.",
    textDirection: config.textDirection,
    style: marker == null ? base : base.merge(marker),
    // 6 is what `OrderedListView` used before this was configurable; the
    // bullet list uses different numbers, so neither is a shared default.
    padding: style.indent ?? 6,
    spacing: style.gapAfterMarker ?? 6,
    child: child,
  );
}

/// An image, honouring [GptMarkdownConfig.imageBuilder], [ImageStyle] and
/// [GptMarkdownConfig.onImageTap].
InlineSpan imageSpan(
  BuildContext context,
  GptMarkdownConfig config, {
  required String url,
  double? width,
  double? height,
}) {
  final builder = config.imageBuilder;
  final Widget image;
  if (builder != null) {
    image = builder(context, url, width, height);
  } else {
    image = SizedBox(
      width: width,
      height: height,
      child: Image(
        image: NetworkImage(url),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          final total = loadingProgress.expectedTotalBytes;
          return CustomImageLoading(
            progress:
                total == null
                    ? 1
                    : loadingProgress.cumulativeBytesLoaded / total,
          );
        },
        fit: BoxFit.fill,
        errorBuilder: (context, error, stackTrace) => const CustomImageError(),
      ),
    );
  }

  final imageStyle = (resolvedStyleSheet(context, config).image ??
          const ImageStyle())
      .resolve(Theme.of(context).colorScheme);
  Widget decorated = image;
  final imageRadius = imageStyle.borderRadius;
  if (imageRadius != null) {
    decorated = ClipRRect(
      borderRadius: BorderRadius.all(imageRadius),
      child: decorated,
    );
  }
  final imagePadding = imageStyle.padding;
  if (imagePadding != null) {
    decorated = Padding(padding: imagePadding, child: decorated);
  }
  final onImageTap = config.onImageTap;
  if (onImageTap != null) {
    decorated = GestureDetector(onTap: () => onImageTap(url), child: decorated);
  }
  return scaledWidgetSpan(
    config: config,
    alignment: PlaceholderAlignment.bottom,
    baseline: null,
    child: decorated,
  );
}

/// Rendered maths, honouring [GptMarkdownConfig.latexBuilder],
/// [GptMarkdownConfig.latexWorkaround] and [LatexStyle].
///
/// [inline] picks between an inline formula and a display block; only the
/// block form takes [LatexStyle]'s padding, background and horizontal scroll.
Widget latexWidget(
  BuildContext context,
  GptMarkdownConfig config, {
  required String tex,
  required bool inline,
}) {
  final workaround = config.latexWorkaround ?? (String tex) => tex;
  final builder =
      config.latexBuilder ??
      (BuildContext context, String tex, TextStyle textStyle, bool inline) =>
          SelectableAdapter(
            selectedText: tex,
            child: Math.tex(
              tex,
              textStyle: textStyle,
              mathStyle: MathStyle.display,
              textScaleFactor: 1,
              settings: const TexParserSettings(strict: Strict.ignore),
              options: MathOptions(
                sizeUnderTextStyle: MathSize.large,
                color:
                    config.style?.color ??
                    Theme.of(context).colorScheme.onSurface,
                fontSize:
                    config.style?.fontSize ??
                    Theme.of(context).textTheme.bodyMedium?.fontSize,
                mathFontOptions: FontOptions(
                  fontFamily: "Main",
                  fontWeight: config.style?.fontWeight ?? FontWeight.normal,
                  fontShape: FontStyle.normal,
                ),
                textFontOptions: FontOptions(
                  fontFamily: "Main",
                  fontWeight: config.style?.fontWeight ?? FontWeight.normal,
                  fontShape: FontStyle.normal,
                ),
                style: MathStyle.display,
              ),
              onErrorFallback:
                  (err) => Text(
                    workaround(tex),
                    textDirection: config.textDirection,
                    style: textStyle.copyWith(
                      color:
                          (!kDebugMode)
                              ? null
                              : Theme.of(context).colorScheme.error,
                    ),
                  ),
            ),
          );

  final latexStyle = (resolvedStyleSheet(context, config).latex ??
          const LatexStyle())
      .resolve(Theme.of(context).colorScheme);
  final override = latexStyle.textStyle;
  final base = config.style ?? const TextStyle();
  Widget maths = builder(
    context,
    workaround(tex),
    override == null ? base : base.merge(override),
    inline,
  );
  if (inline) {
    return maths;
  }

  if (latexStyle.scrollBlockHorizontally ?? false) {
    // Rendered maths cannot wrap, so a wide formula overflows a phone.
    maths = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: maths,
    );
  }
  final background = latexStyle.backgroundColor;
  if (background != null) {
    final radius = latexStyle.borderRadius;
    maths = DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: radius == null ? null : BorderRadius.all(radius),
      ),
      child: maths,
    );
  }
  final padding = latexStyle.padding;
  if (padding != null) {
    maths = Padding(padding: padding, child: maths);
  }
  return maths;
}
