import 'dart:async';

import '../models/chat_exception.dart';
import '../models/val_artifact.dart';
import '../services/artifact_service.dart';

/// Single store for animations, wherever they were first seen — the inline
/// `genui{...}` tag or `x_plusfinity.artifacts`. Watches each one to completion.
class ArtifactRepository {
  ArtifactRepository({required ArtifactService service}) : _service = service;

  final ArtifactService _service;
  final Map<String, ValArtifact> _artifacts = {};
  final Map<String, StreamSubscription<ValArtifact>> _watchers = {};
  final StreamController<ValArtifact> _updates = StreamController.broadcast();

  Stream<ValArtifact> get updates => _updates.stream;

  Map<String, ValArtifact> get snapshot => Map.unmodifiable(_artifacts);

  ValArtifact? operator [](String id) => _artifacts[id];

  /// Registers an artifact and starts watching it. Safe to call repeatedly.
  void track(ValArtifact artifact) {
    if (artifact.id.isEmpty) return;

    _put(artifact);
    if (artifact.status.isTerminal || _watchers.containsKey(artifact.id)) {
      return;
    }
    _watch(artifact.id);
  }

  void _watch(String id) {
    _watchers[id] = _service
        .watch(id, _artifacts[id]?.token)
        .listen(
          _put,
          onError: (Object error) => _fail(id, error),
          onDone: () => _watchers.remove(id),
          cancelOnError: true,
        );
  }

  void _put(ValArtifact artifact) {
    final existing = _artifacts[artifact.id];
    final merged = existing == null ? artifact : existing.mergedWith(artifact);

    _artifacts[merged.id] = merged;
    if (merged.status.isTerminal) _watchers.remove(merged.id)?.cancel();
    if (!_updates.isClosed) _updates.add(merged);
  }

  void _fail(String id, Object error) {
    _watchers.remove(id);
    final existing = _artifacts[id];
    if (existing == null || existing.status.isTerminal) return;

    _put(
      ValArtifact(
        id: id,
        name: existing.name,
        status: ArtifactStatus.failed,
        frame: existing.frame,
        token: existing.token,
        error: error is ChatException ? error.message : error.toString(),
      ),
    );
  }

  void dispose() {
    for (final watcher in _watchers.values) {
      watcher.cancel();
    }
    _watchers.clear();
    _updates.close();
    _service.dispose();
  }
}
