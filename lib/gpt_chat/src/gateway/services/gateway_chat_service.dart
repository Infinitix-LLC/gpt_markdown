import '../../adapter/chat_message.dart';
import '../models/completion_chunk.dart';
import '../models/gateway_model.dart';
import '../models/plusfinity_config.dart';
import 'gateway_client.dart';

/// Talks to `/chat/completions` and `/models` in OpenAI schema.
class GatewayChatService {
  GatewayChatService({required this.config, GatewayClient? client})
    : _client = client ?? GatewayClient(config: config);

  final PlusfinityConfig config;
  final GatewayClient _client;

  /// Emits chunks as they arrive when streaming, or a single chunk otherwise.
  Stream<CompletionChunk> complete(List<ChatMessage> messages, {String? model}) {
    final body = _body(messages, model ?? config.model, stream: config.stream);

    if (!config.stream) {
      return _client.postJson(config.completionsUri, body).then(CompletionChunk.fromJson).asStream();
    }
    return _client.sse(config.completionsUri, body: body).map(CompletionChunk.fromJson);
  }

  Future<List<GatewayModel>> listModels() async {
    final json = await _client.getJson(config.modelsUri);
    final data = json['data'];
    if (data is! List) return const [];
    return data.whereType<Map<String, dynamic>>().map(GatewayModel.fromJson).toList();
  }

  /// Only documented parameters are sent — the gateway rejects unknown ones with 400.
  Map<String, dynamic> _body(List<ChatMessage> messages, String model, {required bool stream}) {
    return {
      'model': model,
      'stream': stream,
      'messages': messages.map((m) => m.toRequestJson()).toList(),
      if (config.temperature != null) 'temperature': config.temperature,
      if (config.maxTokens != null) 'max_tokens': config.maxTokens,
      if (config.reasoningEffort != null)
        'reasoning_effort': config.reasoningEffort!.wireName,
      'x_plusfinity': config.requestExtension,
    };
  }

  void dispose() => _client.close();
}
