import 'package:flutter/widgets.dart';

import '../../../gen_ui/gen_ui_registry.dart';
import '../builders/chat_builders.dart';
import '../builders/chat_slots.dart';
import '../controller/chat_controller.dart';
import '../theme/chat_theme.dart';

/// Hands the controller, the builders and the resolved theme down the tree.
///
/// Put one of these above your own page and you can use the exported chat
/// widgets à la carte, without [GptChat] — the last rung of the customization
/// ladder.
class ChatScope extends InheritedWidget {
  const ChatScope({
    super.key,
    required this.controller,
    required this.theme,
    this.builders = const ChatBuilders(),
    GenUiRegistry? genUi,
    required super.child,
  }) : _genUi = genUi;

  /// State and actions.
  final ChatController controller;

  /// Fully resolved — every field non-null.
  final ChatTheme theme;

  final ChatBuilders builders;

  final GenUiRegistry? _genUi;

  /// Renders the widgets a model draws inside a reply.
  GenUiRegistry get genUi => _genUi ?? GenUiRegistry.defaults();

  static ChatScope of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<ChatScope>();
    assert(
      scope != null,
      'No ChatScope found. Wrap this widget in a GptChat, or in a ChatScope of '
      'your own.',
    );
    return scope!;
  }

  static ChatScope? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<ChatScope>();

  /// Applies a builder to a slot, falling back to the slot's default.
  ///
  /// Every default widget ends in a call to this, which is what makes each part
  /// individually replaceable.
  Widget build<S extends ChatSlot>(ChatBuild<S>? builder, S slot) =>
      builder?.call(slot) ?? slot.child;

  @override
  bool updateShouldNotify(ChatScope oldWidget) =>
      controller != oldWidget.controller ||
      builders != oldWidget.builders ||
      theme != oldWidget.theme ||
      _genUi != oldWidget._genUi;
}

/// Centres [child] and caps it at the theme's reading width.
///
/// The app bar and composer float *over* the transcript rather than boxing it
/// in, so everything shares one column and content scrolls under the bars.
class ChatColumn extends StatelessWidget {
  const ChatColumn({super.key, required this.child, this.maxWidth});

  final Widget child;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final width = maxWidth ?? ChatScope.of(context).theme.contentWidth;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width),
        child: child,
      ),
    );
  }
}
