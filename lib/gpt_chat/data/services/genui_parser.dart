import 'dart:convert';

import '../models/val_artifact.dart';

/// Reads a VAL animation out of a gen-UI payload.
///
/// The gateway emits it as a `val_scene` widget — the same shape as every other
/// gen-UI type, so one `GenUiRegistry` renders animations and charts alike:
///
/// ```json
/// {"val_scene": {"id": "…", "name": "…", "frame": "reels", "status": "queued", "token": "…"}}
/// ```
///
/// Returns null for payloads that hold no animation, so the caller can fall
/// through to the widget registry.
ValArtifact? parseGenUiArtifact(String payload) {
  try {
    final json = jsonDecode(payload);
    if (json is! Map<String, dynamic>) return null;

    final scene = json['val_scene'];
    if (scene is Map<String, dynamic>) return ValArtifact.fromJson(scene);

    // Pre-2026-08 form: a flat object with a `type` discriminator. Kept so
    // sessions persisted before the change still render.
    if (json['type'] == 'val_artifact') return ValArtifact.fromJson(json);

    return null;
  } on FormatException {
    return null;
  }
}
