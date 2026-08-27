import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_markdown/gpt_chat_gateway.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:val_player/val_player.dart' show StreamEnd, StreamError;

/// A client that answers with [chunks] as the body, so a test controls exactly
/// where the network splits the payload.
MockClient _client(
  List<String> chunks, {
  int status = 200,
  void Function(http.BaseRequest request, String body)? onRequest,
}) {
  return MockClient.streaming((request, bodyStream) async {
    onRequest?.call(request, await bodyStream.bytesToString());
    return http.StreamedResponse(
      Stream.fromIterable(chunks.map(utf8.encode)),
      status,
      request: request,
    );
  });
}

String _line(Map<String, Object?> event) => jsonEncode(event);

void main() {
  group('request', () {
    test('posts the artifact id and frame as NDJSON', () async {
      String? body;
      http.BaseRequest? seen;

      await streamValArtifact(
        artifactId: 'a1',
        frame: 'reels',
        client: _client(
          [
            '${_line({'t': 'end', 'count': 1})}\n',
          ],
          onRequest: (request, sent) {
            seen = request;
            body = sent;
          },
        ),
      ).toList();

      final decoded = jsonDecode(body!) as Map<String, dynamic>;
      expect(decoded['artifactId'], 'a1');
      expect(decoded['frame'], 'reels');
      expect(seen?.headers['Accept'], 'application/x-ndjson');
      // Unauthenticated by design — a client can play a scene without holding
      // gateway credentials, and sending one would be a leak, not a feature.
      expect(seen?.headers.containsKey('Authorization'), isFalse);
    });

    test('omits an empty frame rather than sending a blank one', () async {
      String? body;

      await streamValArtifact(
        artifactId: 'a1',
        frame: '',
        client: _client([
          '${_line({'t': 'end', 'count': 1})}\n',
        ], onRequest: (_, sent) => body = sent),
      ).toList();

      expect(
        (jsonDecode(body!) as Map<String, dynamic>).containsKey('frame'),
        isFalse,
      );
    });
  });

  group('framing', () {
    test('decodes one event per line', () async {
      final events =
          await streamValArtifact(
            artifactId: 'a1',
            client: _client([
              '${_line({'t': 'beat', 'name': 'a', 'tMs': 0})}\n'
                  '${_line({'t': 'end', 'count': 1})}\n',
            ]),
          ).toList();

      expect(events, hasLength(2));
      expect(events.last, isA<StreamEnd>());
    });

    test('joins a line split across chunks', () async {
      // A chunk boundary lands wherever the network puts it, including the
      // middle of a JSON object.
      final whole = _line({'t': 'end', 'count': 1});
      final events =
          await streamValArtifact(
            artifactId: 'a1',
            client: _client([whole.substring(0, 5), whole.substring(5), '\n']),
          ).toList();

      expect(events, hasLength(1));
      expect(events.single, isA<StreamEnd>());
    });

    test('emits a final line that has no trailing newline', () async {
      // The terminal event is the one that says the scene finished. Dropping
      // it leaves a player waiting for frames that already stopped coming.
      final events =
          await streamValArtifact(
            artifactId: 'a1',
            client: _client([
              _line({'t': 'end', 'count': 1}),
            ]),
          ).toList();

      expect(events, hasLength(1));
    });

    test('skips blank keep-alive lines', () async {
      final events =
          await streamValArtifact(
            artifactId: 'a1',
            client: _client([
              '\n\n${_line({'t': 'end', 'count': 1})}\n\n',
            ]),
          ).toList();

      expect(events, hasLength(1));
    });
  });

  group('failure', () {
    test('a non-200 throws with the body attached', () async {
      expect(
        streamValArtifact(
          artifactId: 'a1',
          client: _client(['artifact not ready'], status: 409),
        ).toList(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            allOf(contains('409'), contains('not ready')),
          ),
        ),
      );
    });

    test('a failure inside a 200 arrives as an event, not a throw', () async {
      // The trap in this API: the server answers 200 and then reports the
      // failure in band. A caller that trusts the status code sits waiting for
      // frames that are never coming.
      final events =
          await streamValArtifact(
            artifactId: 'a1',
            client: _client([
              '${_line({'t': 'error', 'kind': 'compile', 'message': 'compile failed'})}\n',
            ]),
          ).toList();

      expect(events.single, isA<StreamError>());
    });
  });

  group('endpoint', () {
    test('defaults to the deployed render service', () {
      expect(kValStreamEndpoint, startsWith('https://'));
      expect(kValStreamEndpoint, contains('stream-artifact'));
    });

    test('can be pointed elsewhere', () async {
      Uri? url;

      await streamValArtifact(
        artifactId: 'a1',
        endpoint: 'https://example.test/render',
        client: _client([
          '${_line({'t': 'end', 'count': 1})}\n',
        ], onRequest: (request, _) => url = request.url),
      ).toList();

      expect(url.toString(), 'https://example.test/render');
    });
  });
}
