import '../../adapter/chat_message.dart';
import '../models/completion_chunk.dart';
import '../models/gateway_model.dart';
import '../models/plusfinity_config.dart';
import 'gateway_client.dart';

/// Talks to `/responses` and `/models` in OpenAI schema.
class GatewayChatService {
  GatewayChatService({required this.config, GatewayClient? client})
    : _client = client ?? GatewayClient(config: config);

  final PlusfinityConfig config;
  final GatewayClient _client;

  /// Emits chunks as they arrive when streaming, or a single chunk otherwise.
  Stream<CompletionChunk> complete(
    List<ChatMessage> messages, {
    String? model,
  }) {
    final body = _body(messages, model ?? config.model, stream: config.stream);

    if (!config.stream) {
      return _client
          .postJson(config.responsesUri, body)
          .then(CompletionChunk.fromJson)
          .asStream();
    }
    return _client
        .sse(config.responsesUri, body: body)
        .map(CompletionChunk.fromJson);
  }

  Future<List<GatewayModel>> listModels() async {
    final json = await _client.getJson(config.modelsUri);
    final data = json['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(GatewayModel.fromJson)
        .toList();
  }

  /// Only documented parameters are sent — the gateway rejects unknown ones with 400.
  Map<String, dynamic> _body(
    List<ChatMessage> messages,
    String model, {
    required bool stream,
  }) {
    final effort = config.reasoningEffort;
    return {
      'model': model,
      'stream': stream,
      // Responses names these differently from Chat Completions: `input`
      // rather than `messages`, `max_output_tokens` rather than `max_tokens`,
      // and reasoning effort nested rather than flat.
      'input': messages.map((m) => m.toRequestJson()).toList(),
      if (config.temperature != null) 'temperature': config.temperature,
      if (config.maxTokens != null) 'max_output_tokens': config.maxTokens,
      if (effort != null) 'reasoning': {'effort': effort.wireName},
      'x_plusfinity': config.requestExtension,
    };
  }

  void dispose() => _client.close();
}
