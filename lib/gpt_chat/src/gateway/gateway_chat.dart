import 'package:flutter/material.dart';

import '../../../gen_ui/gen_ui_preview_page.dart';
import '../../../gen_ui/gen_ui_registry.dart';
import '../adapter/session_store.dart';
import '../builders/chat_builders.dart';
import '../controller/chat_controller.dart';
import '../theme/chat_theme.dart';
import '../widgets/gpt_chat.dart';
import 'artifact_scope.dart';
import 'chat_gen_ui.dart';
import 'gateway_chat_adapter.dart';
import 'gateway_model_source.dart';
import 'services/genui_parser.dart';
import 'val_artifact_card.dart';
import 'models/plusfinity_config.dart';

/// A chat screen wired to the Plusfinity Gateway.
///
/// ```dart
/// GatewayChat(config: PlusfinityConfig(apiKey: 'plus_live_…'))
/// ```
///
/// This is [GptChat] plus one prebuilt adapter, the model list, and the
/// animation cards. Everything about customization — [theme], [builders], the
/// slot system — is identical, because it *is* [GptChat] underneath.
class GatewayChat extends StatefulWidget {
  const GatewayChat({
    super.key,
    required this.config,
    this.builders = const ChatBuilders(),
    this.theme,
    this.genUiRegistry,
    this.artifactBuilder,
    this.sessionStore,
    this.adapter,
    this.showGenUiPreview = false,
    this.onControllerReady,
  });

  final PlusfinityConfig config;
  final ChatBuilders builders;
  final ChatTheme? theme;

  /// Renders the widgets the gateway draws inside replies. Defaults to
  /// `GenUiRegistry.defaults()` plus `val_scene`; pass a clone to add more.
  final GenUiRegistry? genUiRegistry;

  /// Draws a finished animation. Without one, the card shows the narration text
  /// and the VAL source.
  final ValArtifactBuilder? artifactBuilder;

  /// Persistence override. Defaults to in-memory.
  final ChatSessionStore? sessionStore;

  /// Provider override, mainly for tests. Disposed here only when created here.
  final GatewayChatAdapter? adapter;

  /// Adds an app-bar action opening the gen-UI preview page. Developer tool.
  final bool showGenUiPreview;

  final void Function(ChatController controller)? onControllerReady;

  @override
  State<GatewayChat> createState() => _GatewayChatState();
}

class _GatewayChatState extends State<GatewayChat> {
  late GatewayChatAdapter _adapter;
  late GatewayModelSource _models;
  late ArtifactStore _artifacts;
  late GenUiRegistry _genUi;
  bool _ownsAdapter = false;

  @override
  void initState() {
    super.initState();
    _create();
  }

  void _create() {
    _ownsAdapter = widget.adapter == null;
    _adapter =
        widget.adapter ??
        GatewayChatAdapter(config: widget.config, store: widget.sessionStore);
    _models = GatewayModelSource(adapter: _adapter);
    _artifacts = ArtifactStore(repository: _adapter.artifacts);
    _genUi = chatGenUiRegistry(widget.genUiRegistry);
  }

  void _teardown() {
    _artifacts.dispose();
    _models.dispose();
    if (_ownsAdapter) _adapter.dispose();
  }

  @override
  void didUpdateWidget(GatewayChat oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.config == oldWidget.config &&
        widget.adapter == oldWidget.adapter) {
      if (widget.genUiRegistry != oldWidget.genUiRegistry) {
        _genUi = chatGenUiRegistry(widget.genUiRegistry);
      }
      return;
    }

    _teardown();
    _create();
  }

  @override
  void dispose() {
    _teardown();
    super.dispose();
  }

  /// Replies from before 2026-08 carried a flat `{"type":"val_artifact"}`
  /// payload with no widget key to dispatch on, so they cannot go through the
  /// registry. Persisted sessions still hold them, and a stored reply that
  /// stops rendering is indistinguishable from a bug in the answer itself.
  Widget _buildGenUi(BuildContext context, String payload) {
    final legacy = parseLegacyGenUiArtifact(payload);
    if (legacy != null) return ValArtifactCard(initial: legacy);
    return _genUi.build(context, payload);
  }

  @override
  Widget build(BuildContext context) {
    return ArtifactScope(
      store: _artifacts,
      builder: widget.artifactBuilder,
      child: GptChat(
        adapter: _adapter,
        models: _models,
        builders: ChatBuilders(genUi: _buildGenUi).merge(widget.builders),
        theme: widget.theme,
        genUiRegistry: _genUi,
        onControllerReady: widget.onControllerReady,
        appBarActions: [
          if (widget.showGenUiPreview)
            IconButton(
              icon: const Icon(Icons.dashboard_customize_outlined),
              tooltip: 'Gen UI preview',
              onPressed:
                  () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => const GenUiPreviewPage(),
                    ),
                  ),
            ),
        ],
      ),
    );
  }
}
