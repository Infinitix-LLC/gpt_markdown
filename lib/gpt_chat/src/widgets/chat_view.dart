import 'package:flutter/material.dart';

import '../builders/chat_slots.dart';
import '../controller/chat_controller.dart';
import '../theme/chat_theme.dart';
import 'chat_app_bar.dart';
import 'chat_composer.dart';
import 'chat_drawer.dart';
import 'chat_indicators.dart';
import 'chat_scope.dart';
import 'chat_transcript.dart';

/// Assembles the chat screen from the defaults, handing each part to
/// `ChatBuilders` on the way out.
///
/// The app bar and composer float *over* the transcript rather than boxing it
/// in, so content scrolls under them and the reading column keeps its full
/// height. Layers, bottom to top: background, transcript, app bar, composer.
class ChatView extends StatelessWidget {
  const ChatView({super.key, this.appBarActions = const []});

  /// Appended to the default app-bar actions.
  final List<Widget> appBarActions;

  @override
  Widget build(BuildContext context) {
    final scope = ChatScope.of(context);
    final controller = scope.controller;
    final theme = scope.theme;
    final builders = scope.builders;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        ChatSlot plain(Widget child) => ChatSlot(
          context: context,
          controller: controller,
          theme: theme,
          child: child,
        );

        if (controller.isLoading) {
          return Scaffold(
            body: scope.build(
              builders.loading,
              plain(const Center(child: CircularProgressIndicator())),
            ),
          );
        }

        final background = scope.build(
          builders.background,
          plain(const SizedBox.shrink()),
        );
        final body = _body(context, scope, controller);
        final appBar = ChatAppBar(
          controller: controller,
          extraActions: appBarActions,
        );
        final composer = ChatComposer(controller: controller);
        final jumpToLatest = scope.build(
          builders.jumpToLatest,
          plain(ChatJumpToLatest(controller: controller)),
        );

        final error = controller.error;
        final errorBar =
            error == null
                ? const SizedBox.shrink()
                : ChatColumn(
                  maxWidth: theme.composerWidth,
                  child: scope.build(
                    builders.errorBar,
                    ChatErrorSlot(
                      context: context,
                      controller: controller,
                      theme: theme,
                      message: error,
                      child: ChatErrorBar(message: error),
                    ),
                  ),
                );

        final drawer =
            controller.capabilities.sessions
                ? ChatDrawer(controller: controller)
                : null;

        final scaffold = Scaffold(
          drawer: drawer,
          body: Stack(
            children: [
              Positioned.fill(child: background),
              Positioned.fill(child: body),
              Align(alignment: Alignment.topCenter, child: appBar),
              Align(
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [errorBar, jumpToLatest, composer],
                ),
              ),
            ],
          ),
        );

        return scope.build(
          builders.scaffold,
          ChatScaffoldSlot(
            context: context,
            controller: controller,
            theme: theme,
            appBar: appBar,
            background: background,
            body: body,
            composer: composer,
            errorBar: errorBar,
            jumpToLatest: jumpToLatest,
            drawer: drawer,
            child: scaffold,
          ),
        );
      },
    );
  }

  Widget _body(
    BuildContext context,
    ChatScope scope,
    ChatController controller,
  ) {
    final builders = scope.builders;
    final theme = scope.theme;
    final isEmpty = controller.isEmpty;

    final empty = scope.build(
      builders.empty,
      ChatSlot(
        context: context,
        controller: controller,
        theme: theme,
        child: const ChatEmptyState(),
      ),
    );
    final list = ChatTranscript(controller: controller);

    return scope.build(
      builders.body,
      ChatBodySlot(
        context: context,
        controller: controller,
        theme: theme,
        list: list,
        empty: empty,
        isEmpty: isEmpty,
        child: isEmpty ? empty : list,
      ),
    );
  }
}
