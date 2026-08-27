import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:val_player/val_player.dart'
    show ValStreamEvent, decodeStreamLine;

import 'val_http_client.dart' if (dart.library.html) 'val_http_client_web.dart';

/// The deployed `streamArtifact` render endpoint.
///
/// Given an artifact id the server compiles the stored VAL script and streams
/// its render nodes as newline-delimited JSON. Nothing compiled is stored, so
/// the script is the artifact and the pixels are produced per play.
///
/// Unauthenticated with `CORS *`, so no key is attached — which is also why a
/// client can play an animation without holding gateway credentials.
const String kValStreamEndpoint =
    'https://stream-artifact-4nssw7ubpq-uc.a.run.app';

/// Streams the render events for [artifactId].
///
/// Yields a head, then interleaved frame / narration / beat events, then a
/// terminal end or error.
///
/// > A failure arrives **in band, with HTTP 200**: the server answers 200 and
/// > then emits a `StreamError` event. A caller that only checks the status
/// > code will sit forever waiting for frames that are never coming.
///
/// Only call this once the artifact reports `ready`. Asking earlier yields a
/// stream error rather than frames.
Stream<ValStreamEvent> streamValArtifact({
  required String artifactId,
  String? frame,
  int seed = 0,
  double frameRate = 60,
  String? endpoint,
  http.Client? client,
}) async* {
  // Injectable so the framing below can be tested against a real response
  // rather than against a copy of itself. A chunk boundary can land mid-line,
  // and the last line often has no trailing newline — both are easy to get
  // wrong and invisible until a scene plays half way.
  final transport = client ?? createValStreamClient();
  final ownsClient = client == null;
  try {
    final request =
        http.Request('POST', Uri.parse(endpoint ?? kValStreamEndpoint))
          ..headers.addAll({
            'Content-Type': 'application/json',
            'Accept': 'application/x-ndjson',
          })
          ..body = jsonEncode({
            'artifactId': artifactId,
            if (frame != null && frame.isNotEmpty) 'frame': frame,
            'seed': seed,
            'frameRate': frameRate,
          });

    // Generous: a long scene renders for a while, and the stream is the
    // playback — cutting it short truncates the animation rather than failing
    // it.
    final response = await transport
        .send(request)
        .timeout(const Duration(minutes: 5));
    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      throw Exception('Render stream failed (${response.statusCode}): $body');
    }

    var buffer = '';
    await for (final chunk in response.stream.transform(utf8.decoder)) {
      buffer += chunk;
      var newline = buffer.indexOf('\n');
      while (newline >= 0) {
        final line = buffer.substring(0, newline).trim();
        buffer = buffer.substring(newline + 1);
        if (line.isNotEmpty) {
          yield decodeStreamLine(line);
        }
        newline = buffer.indexOf('\n');
      }
    }
    // A final line with no trailing newline is still a line.
    final tail = buffer.trim();
    if (tail.isNotEmpty) {
      yield decodeStreamLine(tail);
    }
  } finally {
    if (ownsClient) {
      transport.close();
    }
  }
}
