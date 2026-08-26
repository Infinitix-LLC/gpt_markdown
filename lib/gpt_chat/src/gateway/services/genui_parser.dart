import 'dart:convert';

import '../models/val_artifact.dart';

/// Reads a VAL animation out of a gen-UI payload.
///
/// The gateway emits one as a `val_scene` widget — the same shape as every other
/// gen-UI type, so a single registry renders animations and charts alike:
///
/// ```json
/// {"val_scene": {"id": "…", "name": "…", "frame": "reels", "status": "queued", "token": "…"}}
/// ```
///
/// Returns null for payloads that hold no animation.
ValArtifact? parseGenUiArtifact(String payload) {
  final json = _decodeObject(payload);
  if (json == null) return null;

  final scene = json['val_scene'];
  if (scene is Map) {
    return ValArtifact.fromJson(Map<String, dynamic>.from(scene));
  }

  return _legacy(json);
}

/// Reads only the pre-2026-08 form: a flat object with a `type` discriminator.
///
/// ```json
/// {"type": "val_artifact", "id": "…", "status": "queued", "token": "…"}
/// ```
///
/// Kept separate from [parseGenUiArtifact] because the two forms need different
/// handling: a `val_scene` has a widget key and belongs in the registry with
/// everything else, so that a payload carrying an animation AND a chart renders
/// both. The flat form has no key to dispatch on and can only be special-cased.
ValArtifact? parseLegacyGenUiArtifact(String payload) {
  final json = _decodeObject(payload);
  return json == null ? null : _legacy(json);
}

ValArtifact? _legacy(Map<String, dynamic> json) =>
    json['type'] == 'val_artifact' ? ValArtifact.fromJson(json) : null;

Map<String, dynamic>? _decodeObject(String payload) {
  try {
    final decoded = jsonDecode(payload);
    return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
  } on FormatException {
    return null;
  }
}
