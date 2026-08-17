import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_markdown/gpt_chat_gateway.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _config = PlusfinityConfig(apiKey: 'plus_live_test', model: 'gpt-5.4');

ChatMessage user(String content) =>
    SimpleChatMessage(id: '1', role: ChatRole.user, content: content, createdAt: DateTime(2024));

GatewayChatService service(
  PlusfinityConfig config,
  http.Client client,
) => GatewayChatService(config: config, client: GatewayClient(config: config, client: client));

/// Replays canned SSE lines as a streamed response.
MockClient sseClient(List<String> lines, {int status = 200, void Function(String)? onBody}) {
  return MockClient.streaming((request, bodyStream) async {
    if (onBody != null) onBody(await bodyStream.bytesToString());
    return http.StreamedResponse(
      Stream.value(utf8.encode(lines.join('\n'))),
      status,
      request: request,
    );
  });
}

void main() {
  test('streams content deltas in order', () async {
    final chunks = await service(
      _config,
      sseClient([
        'data: {"choices":[{"delta":{"role":"assistant"}}]}',
        'data: {"choices":[{"delta":{"content":"He"}}]}',
        'data: {"choices":[{"delta":{"content":"llo"}}]}',
        'data: [DONE]',
      ]),
    ).complete([user('hi')]).toList();

    expect(chunks.map((c) => c.content), ['', 'He', 'llo']);
  });

  test('surfaces artifacts announced on an extra chunk', () async {
    final chunks = await service(
      _config,
      sseClient([
        'data: {"choices":[{"delta":{"content":"look"}}]}',
        'data: {"choices":[],"x_plusfinity":{"artifacts":[{"id":"a1","name":"Seed","status":"queued","token":"t"}]}}',
      ]),
    ).complete([user('hi')]).toList();

    expect(chunks.last.artifacts.single.id, 'a1');
  });

  test('sends only documented parameters', () async {
    String? body;
    await service(
      _config,
      sseClient(['data: [DONE]'], onBody: (b) => body = b),
    ).complete([user('hi')]).toList();

    expect(jsonDecode(body!), {
      'model': 'gpt-5.4',
      'stream': true,
      'messages': [
        {'role': 'user', 'content': 'hi'},
      ],
      'x_plusfinity': {'widgets': 'all'},
    });
  });

  test('adds the x_plusfinity fields that differ from the default', () async {
    String? body;
    await service(
      const PlusfinityConfig(apiKey: 'k', frame: ArtifactFrame.reels, languageCode: 'bn'),
      sseClient(['data: [DONE]'], onBody: (b) => body = b),
    ).complete([user('hi')]).toList();

    expect(jsonDecode(body!)['x_plusfinity'], {
      'widgets': 'all',
      'frame': 'reels',
      'languageCode': 'bn',
    });
  });

  test('x_plusfinity.widgets is always sent', () async {
    String? body;
    await service(
      PlusfinityConfig(
        apiKey: 'k',
        reasoningEffort: ReasoningEffort.high,
        widgets: WidgetSelection.only(const ['bar_chart']),
      ),
      sseClient(['data: [DONE]'], onBody: (b) => body = b),
    ).complete([user('hi')]).toList();

    final decoded = jsonDecode(body!) as Map<String, dynamic>;
    expect(decoded['reasoning_effort'], 'high');
    expect(decoded['x_plusfinity'], {
      'widgets': ['bar_chart'],
    });
  });

  test('a per-call model overrides the configured one', () async {
    String? body;
    await service(
      _config,
      sseClient(['data: [DONE]'], onBody: (b) => body = b),
    ).complete([user('hi')], model: 'gemini-3-flash-preview').toList();

    expect(jsonDecode(body!)['model'], 'gemini-3-flash-preview');
  });

  test('throws a readable ChatException on an error status', () {
    final stream = service(
      _config,
      sseClient(['{"error":{"message":"Invalid API key"}}'], status: 401),
    ).complete([user('hi')]);

    expect(
      stream.toList(),
      throwsA(isA<ChatException>().having((e) => e.message, 'message', 'Invalid API key')),
    );
  });

  test('non-streaming mode returns a single chunk', () async {
    final client = MockClient(
      (request) async => http.Response(
        jsonEncode({
          'choices': [
            {'message': {'content': 'full reply'}, 'finish_reason': 'stop'},
          ],
        }),
        200,
      ),
    );

    final chunks = await service(
      const PlusfinityConfig(apiKey: 'k', stream: false),
      client,
    ).complete([user('hi')]).toList();

    expect(chunks.single.content, 'full reply');
    expect(chunks.single.isDone, isTrue);
  });

  test('lists the models available to the key', () async {
    final client = MockClient(
      (request) async => http.Response(
        jsonEncode({
          'data': [
            {'id': 'gpt-5.4', 'owned_by': 'openai'},
            {'id': 'gemini-3.6-flash', 'owned_by': 'google'},
          ],
        }),
        200,
      ),
    );

    final models = await service(_config, client).listModels();

    expect(models.map((m) => m.id), ['gpt-5.4', 'gemini-3.6-flash']);
  });
}
