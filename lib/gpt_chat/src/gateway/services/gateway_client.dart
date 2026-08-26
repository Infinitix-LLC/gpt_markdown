import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/chat_exception.dart';
import '../models/plusfinity_config.dart';
import 'sse_decoder.dart';

/// HTTP plumbing for the gateway: auth headers, JSON, SSE and error mapping.
/// Endpoint knowledge lives in the services above it.
class GatewayClient {
  GatewayClient({required this.config, http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  final PlusfinityConfig config;
  final http.Client _client;
  final bool _ownsClient;

  Future<Map<String, dynamic>> getJson(Uri uri) async {
    final response = await _client
        .get(uri, headers: config.requestHeaders)
        .timeout(config.timeout);
    return _decode(response.statusCode, response.body);
  }

  Future<Map<String, dynamic>> postJson(
    Uri uri,
    Map<String, dynamic> body,
  ) async {
    final response = await _client
        .post(uri, headers: config.requestHeaders, body: jsonEncode(body))
        .timeout(config.timeout);
    return _decode(response.statusCode, response.body);
  }

  /// Streams decoded `data:` frames. Sends [body] as POST when given, else GET.
  Stream<Map<String, dynamic>> sse(
    Uri uri, {
    Map<String, dynamic>? body,
  }) async* {
    final request = http.Request(body == null ? 'GET' : 'POST', uri)
      ..headers.addAll({
        ...config.requestHeaders,
        'Accept': 'text/event-stream',
      });
    if (body != null) request.body = jsonEncode(body);

    final response = await _client.send(request).timeout(config.timeout);
    if (response.statusCode >= 400) {
      throw ChatException.fromResponse(
        response.statusCode,
        await response.stream.bytesToString(),
      );
    }

    final lines = response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());
    await for (final payload in decodeSse(lines)) {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) yield decoded;
    }
  }

  Map<String, dynamic> _decode(int statusCode, String body) {
    if (statusCode >= 400) throw ChatException.fromResponse(statusCode, body);

    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const ChatException('Unexpected response from the gateway.');
    }
    return decoded;
  }

  void close() {
    if (_ownsClient) _client.close();
  }
}
