import '../../../gen_ui/gen_ui_registry.dart';
import 'models/val_artifact.dart';
import 'val_artifact_card.dart';

/// A gen-UI registry that also knows how to draw an animation.
///
/// `GenUiRegistry.defaults()` lives in the generic rendering layer and cannot
/// reach [ValArtifactCard], which needs the chat's artifact view model — so
/// `val_scene` is added here, at the chat layer, rather than there.
///
/// Registering it means animations go through the SAME path as charts. A reply
/// holding both renders both, which special-casing the animation in the bubble
/// could never do.
///
/// [base] is cloned, so adding to it cannot mutate a registry the host also uses
/// elsewhere, and a host that has registered its own `val_scene` keeps it.
GenUiRegistry chatGenUiRegistry([GenUiRegistry? base]) {
  final registry = base?.clone() ?? GenUiRegistry.defaults();
  if (registry.contains('val_scene')) return registry;

  return registry..register(
    'val_scene',
    (context, model) =>
        ValArtifactCard(initial: ValArtifact.fromJson(model.attributes)),
  );
}
