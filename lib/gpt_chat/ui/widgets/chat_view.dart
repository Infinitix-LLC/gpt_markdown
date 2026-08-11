import 'package:flutter/material.dart';

import '../../../gen_ui/gen_ui_preview_page.dart';
import '../controller/chat_controller.dart';
import 'chat_empty_state.dart';
import 'chat_error_bar.dart';
import 'chat_scope.dart';
import 'session_app_bar.dart';
import 'session_composer.dart';
import 'session_drawer.dart';
import 'session_layout.dart';
import 'session_transcript.dart';

/// Assembles the chat screen, delegating every part to `ChatBuilders` and
/// falling back to the defaults.
///
/// The app bar and composer float *over* the transcript rather than boxing it
/// in, so content scrolls under them and the reading column keeps its full
/// height. Layers, bottom to top: background, transcript, app bar, composer.
class ChatView extends StatelessWidget {
  const ChatView({
    super.key,
    required this.showSessions,
    required this.showModelSelector,
    this.emptyState,
    this.showGenUiPreview = false,
  });

  final bool showSessions;
  final bool showModelSelector;
  final Widget? emptyState;

  /// Adds an app-bar action opening [GenUiPreviewPage], which renders the
  /// gen-UI mock document. Off by default — it is a developer tool.
  final bool showGenUiPreview;

  @override
  Widget build(BuildContext context) {
    final scope = ChatScope.of(context);
    final controller = scope.controller;
    final builders = scope.builders;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final custom = builders.scaffold;
        if (custom != null) return custom(context, controller);

        if (controller.isLoading) {
          return Scaffold(
            body: builders.loading?.call(context, controller) ??
                const Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          drawer: showSessions
              ? (builders.drawer?.call(context, controller) ??
                  SessionDrawer(
                    sessions: controller.sessions,
                    activeSessionId: controller.activeSessionId,
                  ))
              : null,
          body: Stack(
            children: [
              if (builders.background != null)
                Positioned.fill(child: builders.background!(context, controller)),
              Positioned.fill(child: _body(context, controller)),
              Align(
                alignment: Alignment.topCenter,
                child: builders.appBar?.call(context, controller) ??
                    SessionAppBar(
                      controller: controller,
                      showSessions: showSessions,
                      actions: [
                        if (showGenUiPreview)
                          IconButton(
                            icon: const Icon(Icons.dashboard_customize_outlined),
                            tooltip: 'Gen UI preview',
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (context) => const GenUiPreviewPage(),
                              ),
                            ),
                          ),
                      ],
                    ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (controller.error != null)
                      SessionLayout.constrain(
                        builders.error?.call(
                              context,
                              controller,
                              controller.error!,
                            ) ??
                            ChatErrorBar(message: controller.error!),
                        maxWidth: SessionLayout.composerMaxWidth,
                      ),
                    builders.jumpToLatest?.call(context, controller) ??
                        SessionJumpToLatest(controller: controller),
                    builders.input?.call(context, controller) ??
                        SessionComposer(
                          controller: controller,
                          showModelSelector: showModelSelector,
                        ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _body(BuildContext context, ChatController controller) {
    final builders = ChatScope.of(context).builders;

    final custom = builders.body;
    if (custom != null) return custom(context, controller);

    if (controller.isEmpty) {
      return builders.empty?.call(context, controller) ??
          emptyState ??
          const ChatEmptyState();
    }

    return builders.messageList?.call(context, controller) ??
        SessionTranscript(controller: controller);
  }
}
