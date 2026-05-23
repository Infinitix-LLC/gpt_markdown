part of 'gpt_markdown.dart';

/// It creates a markdown widget closed to each other.
class MdWidget extends StatefulWidget {
  const MdWidget(
    this.context,
    this.exp,
    this.includeGlobalComponents, {
    super.key,
    required this.config,
  });

  /// The expression to be displayed.
  final String exp;
  final BuildContext context;

  /// Whether to include global components.
  final bool includeGlobalComponents;

  /// The configuration of the markdown widget.
  final GptMarkdownConfig config;

  @visibleForTesting
  static int get debugParseCacheLength => _MdWidgetParseCache.length;

  @visibleForTesting
  static void debugClearParseCache() {
    _MdWidgetParseCache.clear();
  }

  @override
  State<MdWidget> createState() => _MdWidgetState();
}

class _MdWidgetState extends State<MdWidget> {
  List<InlineSpan> list = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshList();
  }

  @override
  void didUpdateWidget(covariant MdWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exp != widget.exp ||
        oldWidget.includeGlobalComponents != widget.includeGlobalComponents ||
        !oldWidget.config.isSame(widget.config)) {
      _refreshList();
    }
  }

  void _refreshList() {
    list = _MdWidgetParseCache.parse(
      context: context,
      exp: widget.exp,
      config: widget.config,
      includeGlobalComponents: widget.includeGlobalComponents,
    );
  }

  @override
  Widget build(BuildContext context) {
    // List<InlineSpan> list = MarkdownComponent.generate(
    //   context,
    //   widget.exp,
    //   widget.config,
    //   widget.includeGlobalComponents,
    // );
    return widget.config.getRich(
      TextSpan(children: list, style: widget.config.style?.copyWith()),
    );
  }
}

class _MdWidgetParseCache {
  static const int _limit = 128;
  static final LinkedHashMap<_MdWidgetParseCacheKey, List<InlineSpan>> _cache =
      LinkedHashMap<_MdWidgetParseCacheKey, List<InlineSpan>>();

  static int get length => _cache.length;

  static void clear() {
    _cache.clear();
  }

  static List<InlineSpan> parse({
    required BuildContext context,
    required String exp,
    required GptMarkdownConfig config,
    required bool includeGlobalComponents,
  }) {
    final key = _MdWidgetParseCacheKey(
      exp: exp,
      contextIdentity: identityHashCode(context),
      includeGlobalComponents: includeGlobalComponents,
      signature: _MdWidgetRenderSignature.from(
        config: config,
        theme: GptMarkdownTheme.of(context),
      ),
    );
    final cached = _cache.remove(key);
    if (cached != null) {
      _cache[key] = cached;
      return cached;
    }

    final list = MarkdownComponent.generate(
      context,
      exp,
      config,
      includeGlobalComponents,
    );
    if (_cache.length >= _limit) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = list;
    return list;
  }
}

class _MdWidgetParseCacheKey {
  final String exp;
  final int contextIdentity;
  final bool includeGlobalComponents;
  final _MdWidgetRenderSignature signature;

  const _MdWidgetParseCacheKey({
    required this.exp,
    required this.contextIdentity,
    required this.includeGlobalComponents,
    required this.signature,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _MdWidgetParseCacheKey &&
        exp == other.exp &&
        contextIdentity == other.contextIdentity &&
        includeGlobalComponents == other.includeGlobalComponents &&
        signature == other.signature;
  }

  @override
  int get hashCode =>
      Object.hash(exp, contextIdentity, includeGlobalComponents, signature);
}

class _MdWidgetRenderSignature {
  final List<Object?> values;
  final int _hashCode;

  _MdWidgetRenderSignature._(this.values) : _hashCode = Object.hashAll(values);

  factory _MdWidgetRenderSignature.from({
    required GptMarkdownConfig config,
    required GptMarkdownThemeData theme,
  }) {
    return _MdWidgetRenderSignature._([
      config.style,
      config.textDirection,
      config.textAlign,
      config.textScaler,
      config.maxLines,
      config.overflow,
      config.followLinkColor,
      config.addNewLineAfterH1,
      config.addDividerAfterH1,
      _componentListSignature(config.components),
      _componentListSignature(config.inlineComponents),
      theme.highlightColor,
      theme.h1,
      theme.h2,
      theme.h3,
      theme.h4,
      theme.h5,
      theme.h6,
      theme.hrLineThickness,
      theme.hrLineColor,
      theme.hrHeight,
      theme.hrLinePadding,
      theme.linkColor,
      theme.linkHoverColor,
      theme.autoAddDividerLineAfterH1,
    ]);
  }

  static Object? _componentListSignature(List<MarkdownComponent>? components) {
    if (components == null) return null;
    return Object.hashAll([
      components.length,
      for (final component in components)
        Object.hash(component.runtimeType, identityHashCode(component)),
    ]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _MdWidgetRenderSignature &&
        _listEquals(values, other.values);
  }

  @override
  int get hashCode => _hashCode;
}

bool _listEquals(List<Object?> a, List<Object?> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// A custom table column width.
class CustomTableColumnWidth extends TableColumnWidth {
  @override
  double maxIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) {
    double width = 50;
    for (var each in cells) {
      each.layout(const BoxConstraints(), parentUsesSize: true);
      width = max(width, each.size.width);
    }
    return min(containerWidth, width);
  }

  @override
  double minIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) {
    return 50;
  }
}
