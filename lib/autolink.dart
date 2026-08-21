part of 'gpt_markdown.dart';

/// Bare URLs, `www.` hosts, email addresses and `<...>` autolinks.
///
/// Markdown itself only links `[label](url)`. Chat and AI output is full of
/// bare URLs, so apps normally pre-process the raw text and rewrite them into
/// `[url](url)` before rendering. That guesswork is where the bugs live: the
/// pre-processor cannot tell where Markdown syntax ends and the URL begins, so
/// `**https://example.com**` turns into `[https://example.com](https://example.com**)`
/// and the trailing `**` ends up inside the href.
///
/// A component does not have that problem. `BoldMd` claims the `**` first — it
/// starts earlier — strips it, and recurses on the inner text, so this only
/// ever sees a clean URL. The same holds for `` `code` ``, headings and table
/// cells.
///
/// Two grammars are implemented:
///
/// * **Bare autolinks** follow the GFM autolink extension, including its two
///   awkward rules: trailing punctuation is excluded (`see https://x.com.`
///   leaves the period outside the link), and a trailing `)` is only part of
///   the link when the parentheses balance.
/// * **Angle autolinks** follow CommonMark §6.5 — `<https://x.com>`,
///   `<mailto:a@b.com>`, `<a@b.com>`.
///
/// Bare autolinks are restricted to `http`, `https`, `mailto` and `xmpp` plus
/// whatever [GptMarkdown.autolinkSchemes] adds, because a bare `foo://bar` in
/// prose is usually not meant as a link. Angle autolinks accept any scheme, as
/// CommonMark specifies — the author wrote the brackets deliberately.
class AutolinkMd extends InlineMd {
  /// Schemes linked without `<>` unless the consumer opts into more.
  static const Set<String> defaultSchemes = {'http', 'https', 'mailto', 'xmpp'};

  /// Trailing characters GFM excludes from a bare autolink.
  static const String _trailingPunctuation = '?!.,:*_~';

  /// A link cannot start in the middle of a word, a path, or an address.
  static const String _leftBoundary = r'(?<![\w@.+/-])';

  static final RegExp _pattern = RegExp(
    <String>[
      // <scheme:...>
      r'<[A-Za-z][A-Za-z0-9+.\-]{1,31}:[^<>\x00-\x20]*>',
      // <email@host>
      r'''<[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9]'''
          r'(?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?'
          r'(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)*>',
      // scheme://rest
      '$_leftBoundary'
          r'[A-Za-z][A-Za-z0-9+.\-]*://[^\s<]+',
      // mailto:/xmpp: — the two schemeless-authority forms GFM lists
      '$_leftBoundary'
          r'(?:mailto|xmpp):[^\s<]+',
      // www.host/rest
      '$_leftBoundary'
          r'www\.[^\s<]+',
      // bare email
      '$_leftBoundary'
          r'[A-Za-z0-9._+-]+@[A-Za-z0-9][A-Za-z0-9._-]*\.[A-Za-z0-9-]+',
    ].join('|'),
    caseSensitive: false,
  );

  @override
  RegExp get exp => _pattern;

  /// A link inside a link label is not a link, and the label is already
  /// rendered inside the outer link's own [WidgetSpan].
  @override
  Set<MarkdownScope> get scopes => MarkdownComponent.allScopesExceptLinkLabel;

  @override
  InlineSpan span(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    if (!config.autolink) {
      return TextSpan(text: text, style: config.style);
    }

    final resolved =
        text.startsWith('<')
            ? _parseAngle(text)
            : _parseBare(text, config.autolinkSchemes);
    if (resolved == null) {
      return TextSpan(text: text, style: config.style);
    }

    return TextSpan(
      children: [
        buildLinkSpan(
          context,
          config,
          url: resolved.url,
          label: resolved.label,
          // The label is the URL itself; re-running it through the inline
          // components would let `ItalicMd` eat the underscores out of
          // `https://example.com/a_b_c`.
          parseLabel: false,
        ),
        if (resolved.trailing.isNotEmpty)
          TextSpan(text: resolved.trailing, style: config.style),
      ],
    );
  }

  /// CommonMark §6.5. The brackets are explicit, so any scheme is accepted and
  /// nothing is trimmed.
  static _Autolink? _parseAngle(String text) {
    if (!text.endsWith('>') || text.length < 3) {
      return null;
    }
    final inner = text.substring(1, text.length - 1);
    if (inner.isEmpty) {
      return null;
    }
    final scheme = RegExp(r'^[A-Za-z][A-Za-z0-9+.\-]{1,31}:').firstMatch(inner);
    return _Autolink(
      url: scheme != null ? inner : 'mailto:$inner',
      label: inner,
      trailing: '',
    );
  }

  /// The GFM autolink extension.
  static _Autolink? _parseBare(String text, Set<String> extraSchemes) {
    var url = text;
    var trailing = '';

    // Trailing punctuation, unbalanced closing parens and trailing entity
    // references are not part of the link.
    var trimming = true;
    while (trimming && url.isNotEmpty) {
      trimming = false;
      final last = url[url.length - 1];

      if (_trailingPunctuation.contains(last)) {
        trailing = '$last$trailing';
        url = url.substring(0, url.length - 1);
        trimming = true;
        continue;
      }

      if (last == ')' && _count(url, ')') > _count(url, '(')) {
        trailing = ')$trailing';
        url = url.substring(0, url.length - 1);
        trimming = true;
        continue;
      }

      if (last == ';') {
        final entity = RegExp(r'&[A-Za-z0-9]+;$').firstMatch(url);
        if (entity != null) {
          trailing = '${entity[0]}$trailing';
          url = url.substring(0, entity.start);
          trimming = true;
        }
      }
    }

    if (url.isEmpty) {
      return null;
    }

    final schemeMatch = RegExp(r'^([A-Za-z][A-Za-z0-9+.\-]*):').firstMatch(url);

    if (schemeMatch != null) {
      final scheme = schemeMatch[1]!.toLowerCase();
      final allowed =
          defaultSchemes.contains(scheme) ||
          extraSchemes.map((e) => e.toLowerCase()).contains(scheme);
      if (!allowed) {
        return null;
      }
      final rest = url.substring(schemeMatch.end).replaceFirst('//', '');
      if (rest.isEmpty) {
        return null;
      }
      // The domain rule is a web rule. `mailto:`/`xmpp:` carry an address, so
      // it applies after the `@`; an app scheme such as `myapp://settings` has
      // no domain at all, and requiring one would reject every deep link.
      if (rest.contains('@')) {
        if (!_isValidDomain(rest.split('@').last)) {
          return null;
        }
      } else if (scheme == 'http' || scheme == 'https') {
        if (!_isValidDomain(rest)) {
          return null;
        }
      }
      return _Autolink(url: url, label: url, trailing: trailing);
    }

    if (url.contains('@')) {
      final at = url.lastIndexOf('@');
      if (!_isValidDomain(url.substring(at + 1))) {
        return null;
      }
      return _Autolink(url: 'mailto:$url', label: url, trailing: trailing);
    }

    if (!_isValidDomain(url)) {
      return null;
    }
    // GFM links a bare `www.` host over plain http.
    return _Autolink(url: 'http://$url', label: url, trailing: trailing);
  }

  /// GFM's valid-domain rule: alphanumeric, `_` and `-` segments separated by
  /// periods, at least one period, and no underscore in the last two segments.
  static bool _isValidDomain(String candidate) {
    final host = candidate.split(RegExp(r'[/?#]')).first;
    final segments = host.split('.');
    if (segments.length < 2) {
      return false;
    }
    for (final segment in segments) {
      if (segment.isEmpty || !RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(segment)) {
        return false;
      }
    }
    return !segments[segments.length - 1].contains('_') &&
        !segments[segments.length - 2].contains('_');
  }

  static int _count(String text, String char) {
    var total = 0;
    for (var i = 0; i < text.length; i++) {
      if (text[i] == char) {
        total++;
      }
    }
    return total;
  }
}

/// A parsed autolink: where it points, what it shows, and the characters that
/// were matched but do not belong to it.
class _Autolink {
  const _Autolink({
    required this.url,
    required this.label,
    required this.trailing,
  });

  final String url;
  final String label;
  final String trailing;
}
