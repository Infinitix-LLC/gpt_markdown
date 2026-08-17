import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_markdown/gpt_chat_gateway.dart';

void main() {
  Future<List<String>> decode(List<String> lines) =>
      decodeSse(Stream.fromIterable(lines)).toList();

  test('keeps data payloads only', () async {
    final result = await decode([
      ': keep-alive',
      'event: message',
      'data: {"a":1}',
      '',
      'data: {"b":2}',
    ]);

    expect(result, ['{"a":1}', '{"b":2}']);
  });

  test('drops the [DONE] sentinel and empty payloads', () async {
    expect(await decode(['data: ', 'data: [DONE]']), isEmpty);
  });
}
