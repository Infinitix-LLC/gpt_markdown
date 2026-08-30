import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'chat_config.dart';

/// One turn in the conversation sent to the model.
class ChatMessage {
  const ChatMessage(this.role, this.content);

  const ChatMessage.user(String content) : this('user', content);
  const ChatMessage.assistant(String content) : this('assistant', content);

  final String role;
  final String content;

  Map<String, Object?> toJson() => {'role': role, 'content': content};
}

/// Raised when the endpoint answers with a non-2xx status, carrying whatever
/// body it returned so the message on screen says something useful.
class ChatRequestException implements Exception {
  ChatRequestException(this.statusCode, this.body);

  final int statusCode;
  final String body;

  @override
  String toString() {
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      return 'Request failed with HTTP $statusCode.';
    }
    // Providers report the useful part under `error.message`; fall back to the
    // raw body when the shape is anything else.
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map && decoded['error'] is Map) {
        final message = (decoded['error'] as Map)['message'];
        if (message is String && message.isNotEmpty) {
          return 'HTTP $statusCode: $message';
        }
      }
    } on FormatException {
      // Not JSON — the raw body is the best available message.
    }
    return 'HTTP $statusCode: $trimmed';
  }
}

/// A streaming client for any endpoint that speaks the OpenAI
/// `/chat/completions` protocol — OpenAI, Groq, Together, OpenRouter,
/// Ollama, LM Studio, vLLM, and anything else with the same wire format.
class OpenAiClient {
  http.Client? _client;

  /// Whether a request is currently in flight.
  bool get isStreaming => _client != null;

  /// Streams the assistant's reply as content deltas.
  ///
  /// Each event is the *new* text only; the caller accumulates. That is the
  /// shape `GptMarkdown` wants — rebuild with the full text received so far
  /// and it re-renders only the tail.
  ///
  /// [onRequestId] fires once, as soon as the response headers arrive, with
  /// the id the proxy stored the exchange under.
  Stream<String> stream({
    required ChatConfig config,
    required List<ChatMessage> history,
    void Function(int requestId)? onRequestId,
  }) async* {
    cancel();
    final client = http.Client();
    _client = client;

    try {
      final request = http.Request('POST', config.chatCompletionsUri);
      request.headers.addAll({
        'content-type': 'application/json',
        'accept': 'text/event-stream',
        if (config.apiKey.trim().isNotEmpty)
          'authorization': 'Bearer ${config.apiKey.trim()}',
      });
      request.body = jsonEncode({
        'model': config.model.trim(),
        'stream': true,
        'messages': [
          if (config.systemPrompt.trim().isNotEmpty)
            {'role': 'system', 'content': config.systemPrompt.trim()},
          ...history.map((m) => m.toJson()),
        ],
      });

      final response = await client.send(request);

      // The ai-testing proxy records the exchange and returns its row id, so
      // an issue filed from this reply can point at the request that produced
      // it. Absent when talking to a provider directly.
      final recordedId = int.tryParse(response.headers['x-request-id'] ?? '');
      if (recordedId != null) onRequestId?.call(recordedId);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final body = await response.stream.bytesToString();
        throw ChatRequestException(response.statusCode, body);
      }

      final lines = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in lines) {
        // Server-sent events: blank lines separate events, `:` starts a
        // comment, and everything this protocol carries arrives on `data:`.
        if (line.isEmpty || line.startsWith(':')) continue;
        if (!line.startsWith('data:')) continue;

        final payload = line.substring(5).trim();
        if (payload.isEmpty) continue;
        if (payload == '[DONE]') break;

        final delta = _contentDelta(payload);
        if (delta != null && delta.isNotEmpty) {
          yield delta;
        }
      }
    } finally {
      if (identical(_client, client)) {
        _client = null;
      }
      client.close();
    }
  }

  /// Pulls `choices[0].delta.content` out of one SSE payload.
  ///
  /// A malformed chunk is skipped rather than killing the stream — a partial
  /// reply on screen beats an exception mid-answer.
  String? _contentDelta(String payload) {
    try {
      final json = jsonDecode(payload);
      if (json is! Map) return null;
      final choices = json['choices'];
      if (choices is! List || choices.isEmpty) return null;
      final first = choices.first;
      if (first is! Map) return null;

      final delta = first['delta'];
      if (delta is Map) {
        final content = delta['content'];
        if (content is String) return content;
      }
      // Some gateways send the non-streaming shape on the final chunk.
      final message = first['message'];
      if (message is Map && message['content'] is String) {
        return message['content'] as String;
      }
      return null;
    } on FormatException {
      return null;
    }
  }

  /// Aborts the in-flight request, if any. The stream ends without error.
  void cancel() {
    _client?.close();
    _client = null;
  }
}
