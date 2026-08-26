import '../adapter/chat_capabilities.dart';
import '../adapter/chat_delta.dart';
import '../adapter/chat_message.dart';
import '../adapter/streaming_chat_adapter.dart';
import 'models/plusfinity_config.dart';
import 'repositories/artifact_repository.dart';
import 'services/artifact_service.dart';
import 'services/gateway_chat_service.dart';

/// A [StreamingChatAdapter] for the Plusfinity Gateway (OpenAI-compatible).
///
/// Applies conversation policy — system prompt, history window, model choice —
/// and routes announced animations to the artifact repository so the inline
/// cards can follow them to completion.
class GatewayChatAdapter extends StreamingChatAdapter {
  GatewayChatAdapter({
    required this.config,
    GatewayChatService? service,
    ArtifactRepository? artifacts,
    super.store,
  }) : _service = service ?? GatewayChatService(config: config),
       _ownsService = service == null,
       artifacts =
           artifacts ??
           ArtifactRepository(service: ArtifactService(config: config)),
       _model = config.model;

  final PlusfinityConfig config;
  final GatewayChatService _service;
  final bool _ownsService;

  /// Animations announced in replies, followed to completion.
  final ArtifactRepository artifacts;

  String _model;
  String get model => _model;

  GatewayChatService get service => _service;

  /// Switching between an OpenAI and a Gemini model is a one-word change.
  void selectModel(String model) => _model = model;

  @override
  ChatCapabilities get capabilities => const ChatCapabilities(models: true);

  @override
  Stream<ChatDelta> streamReply(List<ChatMessage> history) {
    return _service
        .complete(_context(history), model: _model)
        .map((chunk) {
          chunk.artifacts.forEach(artifacts.track);
          return ChatDelta(chunk.content);
        })
        .where((delta) => !delta.isEmpty);
  }

  List<ChatMessage> _context(List<ChatMessage> history) {
    final usable = history.where((m) => m.content.trim().isNotEmpty).toList();
    final windowed =
        usable.length > config.historyLimit
            ? usable.sublist(usable.length - config.historyLimit)
            : usable;

    final prompt = config.systemPrompt;
    if (prompt == null || prompt.isEmpty) return windowed;

    return [
      SimpleChatMessage(
        id: 'system',
        role: ChatRole.system,
        content: prompt,
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      ),
      ...windowed,
    ];
  }

  @override
  void dispose() {
    artifacts.dispose();
    if (_ownsService) _service.dispose();
    super.dispose();
  }
}
