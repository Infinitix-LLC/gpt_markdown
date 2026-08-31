import 'package:flutter/material.dart';

import '../gpt_markdown.dart';

/// Full-page visual check for the built-in gen-UI widgets.
///
/// Renders [kGenUiMockDocument] — the mock assistant reply that exercises
/// every widget [GenUiRegistry.defaults] registers — through [GptMarkdown], so
/// layout, theming, and interaction can be eyeballed without a live backend.
///
/// Open it from the chat screen with `ChatView(showGenUiPreview: true)`, or
/// push it directly:
///
/// ```dart
/// Navigator.of(context).push(
///   MaterialPageRoute<void>(builder: (_) => const GenUiPreviewPage()),
/// );
/// ```
class GenUiPreviewPage extends StatefulWidget {
  const GenUiPreviewPage({
    super.key,
    this.document,
    this.registry,
    this.title = 'Gen UI preview',
  });

  /// Markdown to render. Defaults to [kGenUiMockDocument].
  final String? document;

  /// Registry to render with. Defaults to [GenUiRegistry.defaults], wired so
  /// `button` presses show a snack bar.
  final GenUiRegistry? registry;

  final String title;

  /// The registry the preview uses when a host does not supply one.
  ///
  /// Public so a test can derive what the page should show rather than
  /// hardcoding a count that drifts every time a widget is added.
  static GenUiRegistry demoRegistry({
    GenUiActionCallback? onAction,
    GenUiWidgetBuilder? unknownBuilder,
  }) {
    return GenUiRegistry.defaults(
        onAction: onAction,
        unknownBuilder: unknownBuilder,
      )
      // `val_scene` is the one type `defaults()` leaves out, because it streams
      // from an artifact pipeline the package does not depend on. Standing a
      // demo builder in its place is exactly what a host app does, and it makes
      // the preview show the whole surface instead of a gap.
      ..register('val_scene', _valScene)
      ..register('val', _valScene);
  }

  @override
  State<GenUiPreviewPage> createState() => _GenUiPreviewPageState();
}

class _GenUiPreviewPageState extends State<GenUiPreviewPage> {
  late GenUiRegistry _registry;
  bool _showSource = false;
  bool _incremental = false;
  Brightness? _brightnessOverride;

  @override
  void initState() {
    super.initState();
    _registry = widget.registry ?? _defaultRegistry();
  }

  @override
  void didUpdateWidget(covariant GenUiPreviewPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.registry != widget.registry) {
      _registry = widget.registry ?? _defaultRegistry();
    }
  }

  GenUiRegistry _defaultRegistry() {
    return GenUiPreviewPage.demoRegistry(
      onAction: (action, attributes) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text('Gen UI action: $action'),
              duration: const Duration(seconds: 2),
            ),
          );
      },
      // Unregistered types are host-owned. Mark them visibly here so the
      // preview shows the gap instead of a silent blank line.
      unknownBuilder:
          (context, model) => _UnregisteredTypeChip(type: model.type),
    );
  }

  @override
  Widget build(BuildContext context) {
    final document = widget.document ?? kGenUiMockDocument;
    final baseTheme = Theme.of(context);
    final brightness = _brightnessOverride ?? baseTheme.brightness;
    final theme =
        brightness == baseTheme.brightness
            ? baseTheme
            : ThemeData(
              useMaterial3: baseTheme.useMaterial3,
              brightness: brightness,
              colorSchemeSeed: baseTheme.colorScheme.primary,
            );

    return Theme(
      data: theme,
      child: Builder(
        builder:
            (context) => Scaffold(
              appBar: AppBar(
                title: Text(widget.title),
                actions: [
                  IconButton(
                    icon: Icon(
                      brightness == Brightness.dark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                    ),
                    tooltip: 'Toggle brightness',
                    onPressed:
                        () => setState(() {
                          _brightnessOverride =
                              brightness == Brightness.dark
                                  ? Brightness.light
                                  : Brightness.dark;
                        }),
                  ),
                  IconButton(
                    icon: Icon(_incremental ? Icons.bolt : Icons.bolt_outlined),
                    tooltip:
                        _incremental
                            ? 'Incremental parsing: on'
                            : 'Incremental parsing: off',
                    onPressed:
                        () => setState(() => _incremental = !_incremental),
                  ),
                  IconButton(
                    icon: Icon(
                      _showSource ? Icons.visibility_outlined : Icons.code,
                    ),
                    tooltip: _showSource ? 'Show rendered' : 'Show source',
                    onPressed: () => setState(() => _showSource = !_showSource),
                  ),
                ],
              ),
              body: SafeArea(
                child: Column(
                  children: [
                    _RegistryBar(registry: _registry),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                        child:
                            _showSource
                                ? SelectableText(
                                  document,
                                  style: const TextStyle(
                                    fontFamily: 'JetBrainsMono',
                                    package: 'gpt_markdown',
                                    fontSize: 12,
                                    height: 1.5,
                                  ),
                                )
                                : GptMarkdown(
                                  document,
                                  incremental: _incremental,
                                  inlineDirectives: [_registry.directive],
                                  onLinkTap: (url, title) {
                                    ScaffoldMessenger.of(context)
                                      ..clearSnackBars()
                                      ..showSnackBar(
                                        SnackBar(content: Text('Link: $url')),
                                      );
                                  },
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }
}

/// Strip listing the types the registry can render, so a missing widget is
/// obvious at a glance.
class _RegistryBar extends StatelessWidget {
  const _RegistryBar({required this.registry});

  final GenUiRegistry registry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final types = registry.types.toList()..sort();

    return Container(
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${types.length} registered widget types',
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 6),
          Text(
            types.join(' · '),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _UnregisteredTypeChip extends StatelessWidget {
  const _UnregisteredTypeChip({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.extension_outlined,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '`$type` is host-owned — register a builder to render it',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Stand-in for a host's VAL scene: a real clip in the requested frame.
///
/// A live artifact arrives through the gateway's pipeline and is rendered by
/// the host. There is no backend behind the preview, so this plays a sample
/// video at the same aspect ratio a real scene would use — enough to check
/// framing, spacing and how the reply reads around it.
Widget _valScene(BuildContext context, GenUiModel model) {
  final frame = genUiString(model.attributes['frame']) ?? 'square';
  // Mirrors ArtifactFrame, without gen_ui depending on the gateway models.
  const ratios = {'square': 1.0, 'reels': 9 / 16, 'landscape': 16 / 9};
  final theme = Theme.of(context);

  return Container(
    margin: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.movie_outlined,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text('VAL scene', style: theme.textTheme.titleSmall),
            const SizedBox(width: 8),
            Text(
              frame,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: ratios[frame] ?? 1.0,
          child: GenVideo(
            attributes: {
              'url': _sampleClip,
              if (model.attributes['title'] != null)
                'title': model.attributes['title'],
            },
          ),
        ),
      ],
    ),
  );
}

/// Public sample clip, used only by the preview.
const _sampleClip =
    'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4';
