import 'package:flutter/material.dart';

import '../../../gen_ui/gen_ui_registry.dart';
import '../../data/models/plusfinity_config.dart';
import '../../data/repositories/artifact_repository.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/gateway_chat_repository.dart';
import '../../data/repositories/model_repository.dart';
import '../../data/repositories/session_repository.dart';
import '../../data/services/artifact_service.dart';
import '../../data/services/gateway_chat_service.dart';
import '../../data/services/session_store.dart';
import '../view_models/artifact_view_model.dart';
import '../view_models/chat_view_model.dart';
import '../view_models/model_view_model.dart';
import 'chat_gen_ui.dart';
import 'chat_scope.dart';
import 'chat_view.dart';

/// Drop-in chat screen for the Plusfinity Gateway.
///
/// ```dart
/// GptChat(config: PlusfinityConfig(apiKey: 'plus_live_test'))
/// ```
class GptChat extends StatefulWidget {
  const GptChat({
    super.key,
    required this.config,
    this.showSessions = true,
    this.showModelSelector = true,
    this.emptyState,
    this.genUiRegistry,
    this.artifactBuilder,
    this.sessionStore,
    this.chatRepository,
    this.showGenUiPreview = false,
  });

  final PlusfinityConfig config;

  /// Shows the session drawer. Turn off for a single-conversation screen.
  final bool showSessions;

  /// Shows the model picker in the app bar, backed by `GET /models`.
  final bool showModelSelector;
  final Widget? emptyState;

  /// Renders the widgets the gateway draws inside replies. Defaults to
  /// `GenUiRegistry.defaults()`; pass a clone to add the opt-in types.
  final GenUiRegistry? genUiRegistry;

  /// Draws a finished animation. Without one, the card shows the narration
  /// text and the VAL source.
  final ValArtifactBuilder? artifactBuilder;

  /// Persistence override. Defaults to in-memory.
  final ChatSessionStore? sessionStore;

  /// Provider override, mainly for tests.
  final ChatRepository? chatRepository;

  /// Adds an app-bar action opening the gen-UI preview page. Developer tool.
  final bool showGenUiPreview;

  @override
  State<GptChat> createState() => _GptChatState();
}

class _GptChatState extends State<GptChat> {
  late _ChatGraph _graph;
  late GenUiRegistry _genUi = chatGenUiRegistry(widget.genUiRegistry);

  @override
  void initState() {
    super.initState();
    _graph = _ChatGraph(widget.config, widget.sessionStore, widget.chatRepository);
  }

  @override
  void didUpdateWidget(GptChat oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.config == oldWidget.config && widget.chatRepository == oldWidget.chatRepository) {
      return;
    }
    _graph.dispose();
    _graph = _ChatGraph(widget.config, widget.sessionStore, widget.chatRepository);
    _genUi = chatGenUiRegistry(widget.genUiRegistry);
  }

  @override
  void dispose() {
    _graph.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChatScope(
      chat: _graph.chat,
      artifacts: _graph.artifacts,
      models: _graph.models,
      genUi: _genUi,
      artifactBuilder: widget.artifactBuilder,
      child: ChatView(
        showSessions: widget.showSessions,
        showModelSelector: widget.showModelSelector,
        emptyState: widget.emptyState,
        showGenUiPreview: widget.showGenUiPreview,
      ),
    );
  }
}

/// Wires services, repositories and view models for one configuration.
class _ChatGraph {
  _ChatGraph(PlusfinityConfig config, ChatSessionStore? store, ChatRepository? override)
    : _service = GatewayChatService(config: config),
      _ownsService = override != null {
    final artifactRepository = ArtifactRepository(service: ArtifactService(config: config));
    final chatRepository =
        override ??
        GatewayChatRepository(
          service: _service,
          artifacts: artifactRepository,
          model: config.model,
        );

    chat = ChatViewModel(
      chatRepository: chatRepository,
      sessionRepository: SessionRepository(store: store),
    );
    artifacts = ArtifactViewModel(repository: artifactRepository);
    models = ModelViewModel(
      repository: ModelRepository(service: _service),
      chat: chatRepository,
      initialModel: config.model,
    );
    chat.init();
  }

  final GatewayChatService _service;

  /// True when an injected repository owns no service, so this one is ours.
  final bool _ownsService;

  late final ChatViewModel chat;
  late final ArtifactViewModel artifacts;
  late final ModelViewModel models;

  void dispose() {
    chat.dispose();
    artifacts.dispose();
    models.dispose();
    if (_ownsService) _service.dispose();
  }
}
