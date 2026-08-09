import 'package:flutter/material.dart';

import '../../../gen_ui/gen_ui_preview_page.dart';
import 'chat_empty_state.dart';
import 'chat_error_bar.dart';
import 'chat_input_box.dart';
import 'chat_message_list.dart';
import 'chat_scope.dart';
import 'model_selector.dart';
import 'session_drawer.dart';

/// Assembles the chat screen from the current view model state.
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
    final viewModel = ChatScope.of(context).chat;

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final state = viewModel.state;
        if (state.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          appBar: AppBar(
            title: showModelSelector
                ? const ModelSelector()
                : Text(state.activeSession?.title ?? 'Chat'),
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
              IconButton(
                icon: const Icon(Icons.add_comment_outlined),
                tooltip: 'New chat',
                onPressed: viewModel.newSession,
              ),
            ],
          ),
          drawer: showSessions
              ? SessionDrawer(sessions: state.sessions, activeSessionId: state.activeSessionId)
              : null,
          body: Column(
            children: [
              Expanded(
                child: state.isEmpty
                    ? (emptyState ?? const ChatEmptyState())
                    : ChatMessageList(messages: state.messages),
              ),
              if (state.error != null) ChatErrorBar(message: state.error!),
              ChatInputBox(isResponding: state.isResponding),
            ],
          ),
        );
      },
    );
  }
}
