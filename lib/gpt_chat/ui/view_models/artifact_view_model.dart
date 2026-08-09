import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/val_artifact.dart';
import '../../data/repositories/artifact_repository.dart';

/// Keeps the latest state of every animation seen in the conversation.
class ArtifactViewModel extends ChangeNotifier {
  ArtifactViewModel({required ArtifactRepository repository}) : _repository = repository {
    _subscription = _repository.updates.listen((_) => notifyListeners());
  }

  final ArtifactRepository _repository;
  late final StreamSubscription<ValArtifact> _subscription;

  Map<String, ValArtifact> get artifacts => _repository.snapshot;

  ValArtifact? byId(String id) => _repository[id];

  /// Called when a `genui{...}` tag is rendered, so an artifact is watched even
  /// if the `x_plusfinity` channel was not read.
  void track(ValArtifact artifact) => _repository.track(artifact);

  @override
  void dispose() {
    _subscription.cancel();
    _repository.dispose();
    super.dispose();
  }
}
