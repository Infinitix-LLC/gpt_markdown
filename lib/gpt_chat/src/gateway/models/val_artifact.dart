import 'artifact_frame.dart';

/// Lifecycle reported by `/artifacts/{id}`.
enum ArtifactStatus {
  queued('queued'),
  // Observed live from the gateway and previously absent, so it fell through
  // `fromWire`'s orElse and reported as "Queued" for the whole of generation —
  // the card looked stuck at the exact moment it was doing the work.
  running('running'),
  generating('generating'),
  narrating('narrating'),
  ready('ready'),
  failed('failed');

  const ArtifactStatus(this.wireName);

  final String wireName;

  /// No further updates will arrive.
  bool get isTerminal => this == ready || this == failed;

  static ArtifactStatus fromWire(String? value) =>
      ArtifactStatus.values.firstWhere(
        (s) => s.wireName == value,
        orElse: () => ArtifactStatus.queued,
      );
}

/// One narrated line of an animation. [marks] are passed through untouched —
/// their shape is decided by the gateway.
class Narration {
  const Narration({required this.text, this.audioUrl, this.marks = const []});

  final String text;
  final String? audioUrl;
  final List<Map<String, dynamic>> marks;

  factory Narration.fromJson(Map<String, dynamic> json) {
    final marks = json['marks'];
    return Narration(
      text: json['text'] as String? ?? '',
      audioUrl: (json['audio'] ?? json['audioUrl']) as String?,
      marks:
          marks is List
              ? marks.whereType<Map<String, dynamic>>().toList()
              : const [],
    );
  }
}

/// A VAL animation referenced by a `genui{...}` tag in the reply.
class ValArtifact {
  const ValArtifact({
    required this.id,
    required this.name,
    required this.status,
    this.frame = ArtifactFrame.square,
    this.token,
    this.script,
    this.narrations = const [],
    this.error,
  });

  final String id;
  final String name;

  /// Read-only credential scoped to this artifact, valid one hour.
  final String? token;
  final ArtifactStatus status;
  final ArtifactFrame frame;

  /// VAL source, present once [status] is ready.
  final String? script;
  final List<Narration> narrations;
  final String? error;

  bool get isReady => status == ArtifactStatus.ready;
  bool get hasFailed => status == ArtifactStatus.failed;

  /// Parses both the inline tag payload and the `/artifacts/{id}` body.
  factory ValArtifact.fromJson(Map<String, dynamic> json) {
    final narrations = json['narrations'];
    return ValArtifact(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Animation',
      token: json['token'] as String?,
      status: ArtifactStatus.fromWire(json['status'] as String?),
      frame: ArtifactFrame.fromWire(json['frame'] as String?),
      script: json['script'] as String?,
      narrations:
          narrations is List
              ? narrations
                  .whereType<Map<String, dynamic>>()
                  .map(Narration.fromJson)
                  .toList()
              : const [],
      error: json['error'] as String?,
    );
  }

  /// Later payloads omit the token, so it is carried over from the tag.
  ValArtifact mergedWith(ValArtifact update) => ValArtifact(
    id: id,
    name: update.name.isEmpty ? name : update.name,
    token: update.token ?? token,
    status: update.status,
    frame: update.frame,
    script: update.script ?? script,
    narrations: update.narrations.isEmpty ? narrations : update.narrations,
    error: update.error ?? error,
  );
}
