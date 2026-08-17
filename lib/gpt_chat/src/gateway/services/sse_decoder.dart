/// Turns raw SSE lines into `data:` payloads, dropping comments and the `[DONE]` sentinel.
Stream<String> decodeSse(Stream<String> lines) async* {
  await for (final line in lines) {
    if (!line.startsWith('data:')) continue;

    final payload = line.substring(5).trim();
    if (payload.isEmpty || payload == '[DONE]') continue;
    yield payload;
  }
}
