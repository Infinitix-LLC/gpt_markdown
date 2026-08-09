import 'dart:convert';

import '../models/val_artifact.dart';

/// Reads a `genui{...}` payload. Returns null for tags this package does not
/// own, so the host app can handle its own gen-UI types.
ValArtifact? parseGenUiArtifact(String payload) {
  try {
    final json = jsonDecode(payload);
    if (json is! Map<String, dynamic> || json['type'] != 'val_artifact') return null;
    return ValArtifact.fromJson(json);
  } on FormatException {
    return null;
  }
}
