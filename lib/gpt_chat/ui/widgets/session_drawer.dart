import 'package:flutter/material.dart';

import '../../data/models/chat_session.dart';
import 'chat_scope.dart';

/// Session list with create and delete.
class SessionDrawer extends StatelessWidget {
  const SessionDrawer({super.key, required this.sessions, required this.activeSessionId});

  final List<ChatSession> sessions;
  final String? activeSessionId;

  @override
  Widget build(BuildContext context) {
    final viewModel = ChatScope.of(context).chat;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('New chat'),
              onTap: () {
                Navigator.maybePop(context);
                viewModel.newSession();
              },
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: sessions.length,
                itemBuilder: (context, index) {
                  final session = sessions[index];
                  return ListTile(
                    selected: session.id == activeSessionId,
                    title: Text(session.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () {
                      Navigator.maybePop(context);
                      viewModel.selectSession(session.id);
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      tooltip: 'Delete',
                      onPressed: () => viewModel.deleteSession(session.id),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
