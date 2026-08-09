import 'package:flutter/widgets.dart';

import '../../data/models/val_artifact.dart';
import '../view_models/artifact_view_model.dart';
import '../view_models/chat_view_model.dart';
import '../view_models/model_view_model.dart';

/// Renders a finished animation. Supply one to draw the VAL [ValArtifact.script].
typedef ValArtifactBuilder = Widget Function(BuildContext context, ValArtifact artifact);

/// Hands the view models down the tree. Widgets listen to the one they need
/// with a `ListenableBuilder`, so a token arriving does not rebuild the drawer.
class ChatScope extends InheritedWidget {
  const ChatScope({
    super.key,
    required this.chat,
    required this.artifacts,
    required this.models,
    this.artifactBuilder,
    required super.child,
  });

  final ChatViewModel chat;
  final ArtifactViewModel artifacts;
  final ModelViewModel models;
  final ValArtifactBuilder? artifactBuilder;

  static ChatScope of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<ChatScope>();
    assert(scope != null, 'No ChatScope found. Wrap this widget in a GptChat.');
    return scope!;
  }

  @override
  bool updateShouldNotify(ChatScope oldWidget) =>
      chat != oldWidget.chat ||
      artifacts != oldWidget.artifacts ||
      models != oldWidget.models ||
      artifactBuilder != oldWidget.artifactBuilder;
}
