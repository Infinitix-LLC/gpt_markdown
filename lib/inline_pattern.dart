part of 'gpt_markdown.dart';

/// Builds the span for a single [InlinePattern] match.
///
/// [match] is the match produced by [InlinePattern.pattern]; [style] is the
/// text style in effect at that point in the document.
///
/// Returning a [TextSpan] keeps the content inside the surrounding paragraph —
/// it stays selectable, wraps across lines, and sits on the text baseline.
/// Return a [WidgetSpan] only when the content genuinely needs a widget.
typedef InlinePatternBuilder =
    InlineSpan Function(
      BuildContext context,
      RegExpMatch match,
      TextStyle style,
    );

/// A consumer-defined inline syntax, matched and rendered alongside the
/// built-in Markdown components.
///
/// Chat and social apps layer their own inline tokens on top of Markdown —
/// `@mention`, `#channel`, `:emoji:`. None of these are Markdown, and the same
/// spelling means different things in different products (`#2959` is a channel
/// in Slack, a topic on Mastodon, an issue on GitHub), so the package supplies
/// the mechanism and the app supplies the meaning.
///
/// ```dart
/// GptMarkdown(
///   text,
///   inlinePatterns: [
///     InlinePattern(
///       pattern: RegExp(r'@[A-Za-z0-9_]+'),
///       builder: (context, match, style) => TextSpan(
///         text: match.group(0),
///         style: style.copyWith(color: Colors.indigo),
///         recognizer: TapGestureRecognizer()..onTap = () => openProfile(...),
///       ),
///     ),
///   ],
/// )
/// ```
///
/// Patterns are matched before the built-in components, so a pattern always
/// wins over the default interpretation of the same text.
class InlinePattern {
  /// The syntax to match.
  ///
  /// Matched against the document as a whole, so anchor it with lookarounds
  /// rather than `^` and `$` unless a line-anchored match is what you want.
  final RegExp pattern;

  /// Builds the span for each match of [pattern].
  final InlinePatternBuilder builder;

  /// The nesting contexts this pattern applies in.
  ///
  /// Defaults to [MarkdownComponent.allScopesExceptLinkLabel]. A link label is
  /// already rendered inside the link's own [WidgetSpan]; a pattern that
  /// returns a second [WidgetSpan] there produces a nested placeholder, which
  /// does not paint on iOS. Opt back in with
  /// [MarkdownComponent.allScopes] if the builder returns a [TextSpan].
  final Set<MarkdownScope> scopes;

  /// Creates an inline pattern.
  const InlinePattern({
    required this.pattern,
    required this.builder,
    this.scopes = MarkdownComponent.allScopesExceptLinkLabel,
  });

  /// A pattern for prefixed tokens such as `@name`, `#channel` or `~room`.
  ///
  /// [knownNames] are matched exactly and take priority, longest first, so
  /// `#design-review` is not shadowed by a `#design` entry.
  ///
  /// [genericTokenPattern] is the fallback for tokens that are not in
  /// [knownNames]. Leave it null to match **only** known names — the right
  /// choice when an unknown token is more likely to mean something else. A
  /// generic `#` fallback is what makes an app claim `#2959` as a channel when
  /// the author meant issue 2959.
  ///
  /// Matches are bounded so `user@example.com` and `https://x/#frag` are not
  /// claimed, and are case-insensitive.
  factory InlinePattern.prefixed({
    required String prefix,
    required InlinePatternBuilder builder,
    Iterable<String> knownNames = const [],
    String? genericTokenPattern,
    Set<MarkdownScope> scopes = MarkdownComponent.allScopesExceptLinkLabel,
  }) {
    return InlinePattern(
      pattern: buildPrefixedPattern(
        prefix: prefix,
        knownNames: knownNames,
        genericTokenPattern: genericTokenPattern,
      ),
      builder: builder,
      scopes: scopes,
    );
  }

  /// The regex used by [InlinePattern.prefixed], exposed for consumers that
  /// build their own [InlinePattern] or [MarkdownComponent].
  ///
  /// Returns a regex that can never match when [knownNames] is empty and
  /// [genericTokenPattern] is null, so an app with nothing to link renders its
  /// text untouched.
  static RegExp buildPrefixedPattern({
    required String prefix,
    Iterable<String> knownNames = const [],
    String? genericTokenPattern,
  }) {
    final names =
        knownNames
            .map((name) => name.trim())
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList()
          ..sort((a, b) => b.length.compareTo(a.length));

    if (names.isEmpty && genericTokenPattern == null) {
      // Never matches. `generate` then skips this pattern entirely.
      return RegExp(r'(?!x)x');
    }

    final escapedPrefix = RegExp.escape(prefix);
    // Do not claim the `#` in `https://x/#frag` or the `@` in an email.
    const leadingBoundary = r'(?<![\w./:-])';
    const trailingBoundary = r'(?=$|[\s,;.!?:)\]}])';

    final alternatives = <String>[
      if (names.isNotEmpty)
        '(?:${names.map(RegExp.escape).join('|')})$trailingBoundary',
      if (genericTokenPattern != null)
        '(?:$genericTokenPattern)$trailingBoundary',
    ];

    return RegExp(
      '$leadingBoundary$escapedPrefix(?:${alternatives.join('|')})',
      caseSensitive: false,
      multiLine: true,
    );
  }
}

/// Adapts an [InlinePattern] to the [MarkdownComponent] pipeline.
///
/// Consumers do not construct this — pass [InlinePattern]s to
/// `GptMarkdown.inlinePatterns` instead.
class InlinePatternMd extends InlineMd {
  /// The pattern this component renders.
  final InlinePattern pattern;

  /// Wraps [pattern] as a markdown component.
  InlinePatternMd(this.pattern);

  @override
  RegExp get exp => pattern.pattern;

  @override
  Set<MarkdownScope> get scopes => pattern.scopes;

  @override
  InlineSpan span(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    final match = exp.firstMatch(text);
    if (match == null) {
      return TextSpan(text: text, style: config.style);
    }
    final span = pattern.builder(
      context,
      match,
      config.style ?? const TextStyle(),
    );
    if (span is WidgetSpan) {
      // A paragraph lays inline widgets out in scaled space — it hands them
      // `maxWidth / scale` and multiplies the reported size back — so a widget
      // that also scales its own text is counted twice. Every placeholder the
      // package builds opts out of scaling; consumer chips get the same
      // treatment, so they grow at the same rate as the text beside them
      // rather than several times faster.
      return WidgetSpan(
        alignment: span.alignment,
        baseline: span.baseline,
        style: span.style,
        child: MediaQuery.withNoTextScaling(child: span.child),
      );
    }
    return span;
  }
}
