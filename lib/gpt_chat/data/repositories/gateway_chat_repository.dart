import '../models/chat_message.dart';
import '../models/chat_role.dart';
import '../models/plusfinity_config.dart';
import '../services/gateway_chat_service.dart';
import 'artifact_repository.dart';
import 'chat_repository.dart';

/// Applies conversation policy (system prompt, history window, model choice)
/// and routes announced animations to the artifact repository.
class GatewayChatRepository implements ChatRepository {
  GatewayChatRepository({
    required GatewayChatService service,
    required ArtifactRepository artifacts,
    required String model,
  }) : _service = service,
       _artifacts = artifacts,
       _model = model;

  final GatewayChatService _service;
  final ArtifactRepository _artifacts;
  String _model;

  PlusfinityConfig get config => _service.config;
  String get model => _model;

  @override
  void selectModel(String model) => _model = model;

  @override
  Stream<String> streamReply(List<ChatMessage> history) {
    return _service
        .complete(_buildContext(history), model: _model)
        .map((chunk) {
          chunk.artifacts.forEach(_artifacts.track);
          return chunk.content;
        })
        .where((content) => content.isNotEmpty);
  }

  List<ChatMessage> _buildContext(List<ChatMessage> history) {
    final usable = history.where((m) => m.content.trim().isNotEmpty).toList();
    final windowed = usable.length > config.historyLimit
        ? usable.sublist(usable.length - config.historyLimit)
        : usable;

    final prompt = config.systemPrompt;
    if (prompt == null || prompt.isEmpty) return windowed;

    return [
      ChatMessage(
        id: 'system',
        role: ChatRole.system,
        content: prompt,
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      ),
      ...windowed,
    ];
  }

  @override
  void dispose() => _service.dispose();
}
