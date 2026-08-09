/// Any failure surfaced by the data layer, already turned into a readable message.
class ChatException implements Exception {
  const ChatException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  /// Pulls `error.message` out of an OpenAI error body, else uses the raw body.
  factory ChatException.fromResponse(int statusCode, String body) {
    return ChatException(
      _extractMessage(body) ?? 'Request failed ($statusCode)',
      statusCode: statusCode,
    );
  }

  static String? _extractMessage(String body) {
    final match = RegExp(r'"message"\s*:\s*"((?:[^"\\]|\\.)*)"').firstMatch(body);
    return match?.group(1)?.replaceAll(r'\"', '"');
  }

  @override
  String toString() => message;
}
