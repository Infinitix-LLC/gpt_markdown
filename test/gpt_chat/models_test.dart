import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_markdown/gpt_chat_gateway.dart';

ChatMessage message(String id, {String content = ''}) => SimpleChatMessage(
  id: id,
  role: ChatRole.user,
  content: content,
  createdAt: DateTime(2024),
);

void main() {
  group('CompletionChunk', () {
    test('reads a streaming delta', () {
      final chunk = CompletionChunk.fromJson({
        'choices': [
          {'delta': {'content': 'hi'}, 'finish_reason': null},
        ],
      });

      expect(chunk.content, 'hi');
      expect(chunk.isDone, isFalse);
    });

    test('reads a non-streaming message', () {
      final chunk = CompletionChunk.fromJson({
        'choices': [
          {'message': {'content': 'done'}, 'finish_reason': 'stop'},
        ],
      });

      expect(chunk.content, 'done');
      expect(chunk.isDone, isTrue);
    });

    test('reads artifacts from the x_plusfinity extension', () {
      final chunk = CompletionChunk.fromJson({
        'choices': [],
        'x_plusfinity': {
          'artifacts': [
            {'id': 'a1', 'name': 'Seed', 'status': 'queued', 'token': 't'},
          ],
        },
      });

      expect(chunk.artifacts.single.id, 'a1');
      expect(chunk.artifacts.single.token, 't');
    });

    test('tolerates an empty choices list', () {
      expect(CompletionChunk.fromJson({'choices': []}).content, isEmpty);
    });
  });

  group('ChatException', () {
    test('extracts the API error message', () {
      final error = ChatException.fromResponse(401, '{"error":{"message":"Invalid API key"}}');

      expect(error.message, 'Invalid API key');
      expect(error.statusCode, 401);
    });

    test('falls back to the status code', () {
      expect(ChatException.fromResponse(429, 'slow down').message, contains('429'));
    });
  });

  group('ValArtifact', () {
    test('parses a ready payload', () {
      final artifact = ValArtifact.fromJson({
        'id': 'a1',
        'name': 'Seed',
        'status': 'ready',
        'frame': 'landscape',
        'script': 'scene {}',
        'narrations': [
          {'text': 'A seed sprouts.', 'audio': 'https://x.dev/a.mp3', 'marks': [
            {'time': 0},
          ]},
        ],
      });

      expect(artifact.isReady, isTrue);
      expect(artifact.frame, ArtifactFrame.landscape);
      expect(artifact.script, 'scene {}');
      expect(artifact.narrations.single.audioUrl, 'https://x.dev/a.mp3');
      expect(artifact.narrations.single.marks, hasLength(1));
    });

    test('merge keeps the token from the original tag', () {
      const tagged = ValArtifact(id: 'a1', name: 'Seed', status: ArtifactStatus.queued, token: 't');
      const update = ValArtifact(id: 'a1', name: 'Seed', status: ArtifactStatus.generating);

      final merged = tagged.mergedWith(update);

      expect(merged.token, 't');
      expect(merged.status, ArtifactStatus.generating);
    });

    test('ready and failed are terminal', () {
      expect(ArtifactStatus.ready.isTerminal, isTrue);
      expect(ArtifactStatus.failed.isTerminal, isTrue);
      expect(ArtifactStatus.narrating.isTerminal, isFalse);
    });
  });

  group('ChatSession', () {
    final session = ChatSession(
      id: 's1',
      title: 't',
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
      messages: [message('m1', content: 'a')],
    );

    test('withMessage appends unknown ids', () {
      expect(session.withMessage(message('m2')).messages, hasLength(2));
    });

    test('withMessage replaces in place', () {
      final updated = session.withMessage(message('m1', content: 'b'));

      expect(updated.messages, hasLength(1));
      expect(updated.messages.single.content, 'b');
    });

    test('withoutMessage removes by id', () {
      expect(session.withoutMessage('m1').messages, isEmpty);
    });
  });

  group('PlusfinityConfig', () {
    const config = PlusfinityConfig(apiKey: 'k');

    test('defaults to the gateway base url', () {
      expect(
        config.completionsUri.toString(),
        'https://us-central1-yalagpt.cloudfunctions.net/v1/chat/completions',
      );
      expect(config.modelsUri.path, endsWith('/models'));
    });

    test('puts the artifact token in the query string', () {
      expect(config.artifactUri('a1', 'tok').toString(), endsWith('/artifacts/a1?token=tok'));
      expect(
        config.artifactEventsUri('a1', 'tok').toString(),
        endsWith('/artifacts/a1/events?token=tok'),
      );
    });

    test('sets the bearer header', () {
      expect(config.requestHeaders['Authorization'], 'Bearer k');
    });

    test('sends only the fields that differ from the default', () {
      const custom = PlusfinityConfig(
        apiKey: 'k',
        frame: ArtifactFrame.reels,
        languageCode: 'bn',
        artifactsEnabled: false,
      );

      expect(custom.requestExtension, {
        'widgets': 'all',
        'frame': 'reels',
        'languageCode': 'bn',
        'artifacts': false,
      });
    });

    test('widgets default to every widget and are always sent', () {
      expect(config.widgets, WidgetSelection.all);
      expect(config.requestExtension, {'widgets': 'all'});
    });

    test('widget selection maps to its wire value', () {
      expect(WidgetSelection.defaults.toWire(), true);
      expect(WidgetSelection.none.toWire(), false);
      expect(
        WidgetSelection.only(const ['bar_chart', 'surface_3d']).toWire(),
        ['bar_chart', 'surface_3d'],
      );
    });

    test('compares by value', () {
      expect(config, const PlusfinityConfig(apiKey: 'k'));
      expect(config, isNot(config.copyWith(model: 'gemini-3.6-flash')));
      expect(config, isNot(config.copyWith(widgets: WidgetSelection.none)));
      expect(
        config.copyWith(widgets: WidgetSelection.only(const ['bar_chart'])),
        config.copyWith(widgets: WidgetSelection.only(const ['bar_chart'])),
      );
    });
  });

  group('GenUiWidgetTypes', () {
    test('nine on by default, nine opt-in', () {
      expect(GenUiWidgetTypes.defaults, hasLength(9));
      expect(GenUiWidgetTypes.optIn, hasLength(9));
      expect(GenUiWidgetTypes.all, hasLength(18));
    });

    test('knows the documented names', () {
      expect(GenUiWidgetTypes.isKnown('bar_chart'), isTrue);
      expect(GenUiWidgetTypes.isKnown('spherical_surface_3d'), isTrue);
      expect(GenUiWidgetTypes.isKnown('nope'), isFalse);
    });
  });
}
