import 'dart:async';

import 'package:flutter/widgets.dart';

import 'models/val_artifact.dart';
import 'repositories/artifact_repository.dart';

/// Renders a finished animation. Supply one to draw [ValArtifact.script];
/// without it the card falls back to the narration text and the VAL source.
typedef ValArtifactBuilder =
    Widget Function(BuildContext context, ValArtifact artifact);

/// Keeps the latest state of every animation seen in the conversation.
class ArtifactStore extends ChangeNotifier {
  ArtifactStore({required ArtifactRepository repository})
    : _repository = repository {
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

/// Hands the artifact store to the cards rendered inside replies.
///
/// Lives in the gateway half so the core chat UI stays free of animation
/// concepts.
class ArtifactScope extends InheritedWidget {
  const ArtifactScope({
    super.key,
    required this.store,
    this.builder,
    required super.child,
  });

  final ArtifactStore store;
  final ValArtifactBuilder? builder;

  static ArtifactScope of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<ArtifactScope>();
    assert(
      scope != null,
      'No ArtifactScope found. Wrap this in a GatewayChat.',
    );
    return scope!;
  }

  static ArtifactScope? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<ArtifactScope>();

  @override
  bool updateShouldNotify(ArtifactScope oldWidget) =>
      store != oldWidget.store || builder != oldWidget.builder;
}
