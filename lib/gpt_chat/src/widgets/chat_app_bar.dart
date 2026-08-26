import 'package:flutter/material.dart';

import '../builders/chat_slots.dart';
import '../controller/chat_controller.dart';
import '../theme/chat_theme.dart';
import 'chat_model_picker.dart';
import 'chat_scope.dart';

/// The bar floating over the top of the transcript.
///
/// It fades to transparent at its lower edge so text scrolling underneath
/// dissolves instead of being cut by a hard line.
///
/// When the adapter offers models the picker takes the title position — the
/// model is the most useful thing to see and change at the top of a chat.
class ChatAppBar extends StatelessWidget {
  const ChatAppBar({
    super.key,
    required this.controller,
    this.extraActions = const [],
  });

  /// Appended to the default actions. For wholesale replacement use
  /// `ChatBuilders.appBarActions`.
  final List<Widget> extraActions;

  final ChatController controller;

  @override
  Widget build(BuildContext context) {
    final scope = ChatScope.of(context);
    final theme = scope.theme;
    final builders = scope.builders;
    final capabilities = controller.capabilities;
    final topInset = MediaQuery.paddingOf(context).top;
    final surface = theme.surfaceColor ?? Theme.of(context).colorScheme.surface;

    ChatSlot plain(Widget child) => ChatSlot(
      context: context,
      controller: controller,
      theme: theme,
      child: child,
    );

    final leading = scope.build(
      builders.appBarLeading,
      plain(
        capabilities.sessions
            ? Builder(
              builder:
                  (context) => IconButton(
                    icon: const Icon(Icons.menu_rounded),
                    tooltip: 'Conversations',
                    onPressed: Scaffold.of(context).openDrawer,
                  ),
            )
            : const SizedBox(width: 12),
      ),
    );

    final modelSelector = scope.build(
      builders.modelSelector,
      plain(
        capabilities.models
            ? ChatModelPicker(controller: controller)
            : const SizedBox.shrink(),
      ),
    );

    final title = scope.build(
      builders.appBarTitle,
      plain(
        capabilities.models
            ? Align(alignment: Alignment.centerLeft, child: modelSelector)
            : Text(
              controller.activeSession?.title ?? 'Chat',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
      ),
    );

    final actions =
        builders.appBarActions
            ?.map((build) => build(plain(const SizedBox.shrink())))
            .toList() ??
        [
          ...extraActions,
          if (capabilities.sessions)
            IconButton(
              icon: const Icon(Icons.add_comment_outlined),
              tooltip: 'New chat',
              onPressed: controller.onNewSession,
            ),
        ];

    final bar = SizedBox(
      height: theme.barHeight + topInset,
      child: Container(
        padding: EdgeInsets.only(top: topInset),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [surface, surface, surface.withValues(alpha: 0)],
            stops: const [0, 0.62, 1],
          ),
        ),
        child: ChatColumn(
          maxWidth: theme.composerWidth,
          child: Row(children: [leading, Expanded(child: title), ...actions]),
        ),
      ),
    );

    return scope.build(
      builders.appBar,
      ChatAppBarSlot(
        context: context,
        controller: controller,
        theme: theme,
        leading: leading,
        title: title,
        modelSelector: modelSelector,
        actions: actions,
        child: bar,
      ),
    );
  }
}
