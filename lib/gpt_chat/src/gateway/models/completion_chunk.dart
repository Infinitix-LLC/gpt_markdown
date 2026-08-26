import 'val_artifact.dart';

/// One decoded slice of a response.
///
/// The gateway speaks OpenAI's **Responses** API. `/chat/completions` was
/// retired — its shape cannot carry built-in tools, conversation state or
/// reasoning items — so there are no `choices` and no `delta.content`.
///
/// Streaming arrives as typed events:
///
/// ```text
/// response.created            → nothing to show yet
/// response.output_text.delta  → one slice of text, on `delta`
/// response.output_text.done   → the finished text, already streamed
/// response.completed          → terminal
/// ```
///
/// Non-streaming arrives as one object with an `output` array of items, each
/// holding `content` parts of type `output_text`.
class CompletionChunk {
  const CompletionChunk({
    this.content = '',
    this.finishReason,
    this.artifacts = const [],
  });

  /// Text produced by this chunk. Empty for lifecycle-only or artifact-only
  /// events.
  final String content;

  /// Set once the response reaches a terminal state — `completed`, `failed`
  /// or `incomplete`. Named for the Chat Completions field it replaces so the
  /// layers above did not have to change.
  final String? finishReason;

  /// Animations announced on `x_plusfinity.artifacts`.
  final List<ValArtifact> artifacts;

  bool get isDone => finishReason != null;

  /// Reads one streamed event, or a whole non-streamed response.
  factory CompletionChunk.fromJson(Map<String, dynamic> json) {
    final artifacts = _artifacts(json);
    final type = json['type'];

    // A streamed event.
    if (type is String) {
      switch (type) {
        case 'response.output_text.delta':
          return CompletionChunk(
            content: json['delta'] as String? ?? '',
            artifacts: artifacts,
          );
        case 'response.completed':
        case 'response.failed':
        case 'response.incomplete':
          final response = json['response'];
          final status =
              response is Map<String, dynamic>
                  ? response['status'] as String?
                  : null;
          // `response.completed` carries the whole response, but its text has
          // already been streamed — emitting it again would duplicate it.
          return CompletionChunk(
            finishReason: status ?? type.substring('response.'.length),
            artifacts:
                artifacts.isEmpty && response is Map<String, dynamic>
                    ? _artifacts(response)
                    : artifacts,
          );
        default:
          // Lifecycle events — created, in_progress, output_item.added,
          // content_part.*, output_text.done — carry no new text.
          return CompletionChunk(artifacts: artifacts);
      }
    }

    // A non-streamed response object.
    return CompletionChunk(
      content: _outputText(json['output']),
      finishReason: json['status'] as String?,
      artifacts: artifacts,
    );
  }

  /// Concatenates every `output_text` part across every message item.
  static String _outputText(Object? output) {
    if (output is! List) {
      return '';
    }
    final buffer = StringBuffer();
    for (final item in output.whereType<Map<String, dynamic>>()) {
      final content = item['content'];
      if (content is! List) {
        continue;
      }
      for (final part in content.whereType<Map<String, dynamic>>()) {
        if (part['type'] == 'output_text') {
          buffer.write(part['text'] as String? ?? '');
        }
      }
    }
    return buffer.toString();
  }

  /// Pulls artifacts from `x_plusfinity`, wherever the gateway attaches it.
  ///
  /// Checked on the event itself and on a nested `response`, because the
  /// extension's placement under Responses is not something the endpoint
  /// documents and a plain reply never carries one to observe.
  static List<ValArtifact> _artifacts(Map<String, dynamic> json) {
    final direct = _artifactsIn(json['x_plusfinity']);
    if (direct.isNotEmpty) {
      return direct;
    }
    final response = json['response'];
    if (response is Map<String, dynamic>) {
      return _artifactsIn(response['x_plusfinity']);
    }
    return const [];
  }

  static List<ValArtifact> _artifactsIn(Object? extension) {
    if (extension is! Map<String, dynamic>) {
      return const [];
    }
    final artifacts = extension['artifacts'];
    if (artifacts is! List) {
      return const [];
    }
    return artifacts
        .whereType<Map<String, dynamic>>()
        .map(ValArtifact.fromJson)
        .toList();
  }
}
