import 'package:flutter/material.dart';

import '../controller/chat_controller.dart';
import 'session_layout.dart';

/// The bar floating over the top of the transcript.
///
/// It fades to transparent at its lower edge so text scrolling underneath
/// dissolves instead of being cut by a hard line.
class SessionAppBar extends StatelessWidget {
  const SessionAppBar({
    super.key,
    required this.controller,
    this.showSessions = true,
    this.actions = const [],
  });

  final ChatController controller;
  final bool showSessions;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final topInset = MediaQuery.paddingOf(context).top;

    return SizedBox(
      height: SessionLayout.appBarHeight + topInset,
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
        child: SessionLayout.constrain(
          Row(
            children: [
              if (showSessions)
                Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu_rounded),
                    tooltip: 'Sessions',
                    onPressed: Scaffold.of(context).openDrawer,
                  ),
                )
              else
                const SizedBox(width: 12),
              Expanded(
                child: Text(
                  controller.activeSession?.title ?? 'Chat',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              ...actions,
              IconButton(
                icon: const Icon(Icons.add_comment_outlined),
                tooltip: 'New chat',
                onPressed: controller.onNewSession,
              ),
            ],
          ),
          maxWidth: SessionLayout.composerMaxWidth,
        ),
      ),
    );
  }
}
