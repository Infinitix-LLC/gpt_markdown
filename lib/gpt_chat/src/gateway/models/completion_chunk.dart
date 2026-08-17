import 'val_artifact.dart';

/// One decoded slice of a chat completion response.
class CompletionChunk {
  const CompletionChunk({this.content = '', this.finishReason, this.artifacts = const []});

  /// Text produced by this chunk. Empty for role-only or artifact-only chunks.
  final String content;
  final String? finishReason;

  /// Animations announced on `x_plusfinity.artifacts`.
  final List<ValArtifact> artifacts;

  bool get isDone => finishReason != null;

  /// Reads both streaming (`delta`) and non-streaming (`message`) payloads.
  factory CompletionChunk.fromJson(Map<String, dynamic> json) {
    final choices = json['choices'];
    final choice = choices is List && choices.isNotEmpty ? choices.first as Map<String, dynamic> : null;
    final part = (choice?['delta'] ?? choice?['message']) as Map<String, dynamic>?;

    return CompletionChunk(
      content: part?['content'] as String? ?? '',
      finishReason: choice?['finish_reason'] as String?,
      artifacts: _artifacts(json['x_plusfinity']),
    );
  }

  static List<ValArtifact> _artifacts(Object? extension) {
    if (extension is! Map<String, dynamic>) return const [];

    final artifacts = extension['artifacts'];
    if (artifacts is! List) return const [];
    return artifacts.whereType<Map<String, dynamic>>().map(ValArtifact.fromJson).toList();
  }
}
