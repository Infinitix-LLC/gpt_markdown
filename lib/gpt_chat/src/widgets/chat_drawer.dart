import 'package:flutter/material.dart';

import '../adapter/chat_session.dart';
import '../builders/chat_slots.dart';
import '../controller/chat_controller.dart';
import 'chat_scope.dart';

/// The conversation list.
///
/// Rows are grouped by recency — Today, Yesterday, Previous 7 days, Older —
/// which is what makes a long history navigable. A search field appears once
/// there are enough conversations for grouping alone to stop being enough.
class ChatDrawer extends StatefulWidget {
  const ChatDrawer({super.key, required this.controller});

  final ChatController controller;

  /// Conversations past which the search field is shown.
  static const int searchThreshold = 8;

  @override
  State<ChatDrawer> createState() => _ChatDrawerState();
}

class _ChatDrawerState extends State<ChatDrawer> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final scope = ChatScope.of(context);
    final theme = scope.theme;
    final builders = scope.builders;
    final capabilities = controller.capabilities;

    final all = controller.sessions;
    final sessions =
        _query.isEmpty
            ? all
            : all
                .where((s) => s.title.toLowerCase().contains(_query))
                .toList(growable: false);

    ChatSlot plain(Widget child) => ChatSlot(
      context: context,
      controller: controller,
      theme: theme,
      child: child,
    );

    final newSessionButton = scope.build(
      builders.newSessionButton,
      plain(
        ListTile(
          leading: const Icon(Icons.add),
          title: const Text('New chat'),
          onTap: () {
            Navigator.maybePop(context);
            controller.onNewSession();
          },
        ),
      ),
    );

    final header = scope.build(
      builders.drawerHeader,
      plain(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            newSessionButton,
            if (all.length > ChatDrawer.searchThreshold)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                child: TextField(
                  controller: _search,
                  onChanged:
                      (value) =>
                          setState(() => _query = value.trim().toLowerCase()),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Search',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                  ),
                ),
              ),
            const Divider(height: 1),
          ],
        ),
      ),
    );

    final footer = scope.build(
      builders.drawerFooter,
      plain(const SizedBox.shrink()),
    );

    Widget tile(int index) {
      final session = sessions[index];
      return scope.build(
        builders.sessionTile,
        ChatSessionSlot(
          context: context,
          controller: controller,
          theme: theme,
          session: session,
          isActive: session.id == controller.activeSessionId,
          child: ChatSessionTile(
            controller: controller,
            session: session,
            isActive: session.id == controller.activeSessionId,
          ),
        ),
      );
    }

    // Paging applies to the whole history, not to a filtered view of what is
    // already loaded.
    final canPage =
        capabilities.sessionPaging &&
        controller.hasMoreSessions &&
        _query.isEmpty;

    final groups = _group(sessions);
    final list =
        sessions.isEmpty
            ? const _NoSessions()
            : ListView.builder(
              itemCount: groups.length + (canPage ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == groups.length) {
                  return _LoadMore(controller: controller);
                }

                final entry = groups[index];
                if (entry.label != null) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text(
                      entry.label!,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                return tile(entry.index!);
              },
            );

    final drawer = Drawer(
      child: SafeArea(
        child: Column(children: [header, Expanded(child: list), footer]),
      ),
    );

    return scope.build(
      builders.drawer,
      ChatDrawerSlot(
        context: context,
        controller: controller,
        theme: theme,
        sessions: sessions,
        tile: tile,
        header: header,
        footer: footer,
        newSessionButton: newSessionButton,
        list: list,
        child: drawer,
      ),
    );
  }

  /// Flattens the sessions into a list of headings and rows.
  static List<_Entry> _group(List<ChatSession> sessions) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entries = <_Entry>[];
    String? current;

    for (var i = 0; i < sessions.length; i++) {
      final days =
          today
              .difference(
                DateTime(
                  sessions[i].updatedAt.year,
                  sessions[i].updatedAt.month,
                  sessions[i].updatedAt.day,
                ),
              )
              .inDays;
      final label = switch (days) {
        <= 0 => 'Today',
        1 => 'Yesterday',
        <= 7 => 'Previous 7 days',
        <= 30 => 'Previous 30 days',
        _ => 'Older',
      };

      if (label != current) {
        current = label;
        entries.add(_Entry.heading(label));
      }
      entries.add(_Entry.row(i));
    }

    return entries;
  }
}

class _Entry {
  const _Entry.heading(this.label) : index = null;
  const _Entry.row(this.index) : label = null;

  final String? label;
  final int? index;
}

/// One conversation. Rename and delete live behind an overflow menu so the row
/// stays readable at a glance.
class ChatSessionTile extends StatelessWidget {
  const ChatSessionTile({
    super.key,
    required this.controller,
    required this.session,
    required this.isActive,
  });

  final ChatController controller;
  final ChatSession session;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final capabilities = controller.capabilities;
    final canRename = capabilities.renameSessions;
    final canDelete = capabilities.deleteSessions;

    return ListTile(
      selected: isActive,
      dense: true,
      title: Text(session.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: () {
        Navigator.maybePop(context);
        controller.onSelectSession(session.id);
      },
      trailing: switch ((canRename, canDelete)) {
        (false, false) => null,
        (false, true) => IconButton(
          icon: const Icon(Icons.delete_outline, size: 20),
          tooltip: 'Delete',
          onPressed: () => controller.onDeleteSession(session.id),
        ),
        _ => PopupMenuButton<_SessionAction>(
          tooltip: 'More',
          icon: const Icon(Icons.more_horiz, size: 20),
          onSelected:
              (action) => switch (action) {
                _SessionAction.rename => _rename(context),
                _SessionAction.delete => controller.onDeleteSession(session.id),
              },
          itemBuilder:
              (context) => [
                if (canRename)
                  const PopupMenuItem(
                    value: _SessionAction.rename,
                    child: Text('Rename'),
                  ),
                if (canDelete)
                  const PopupMenuItem(
                    value: _SessionAction.delete,
                    child: Text('Delete'),
                  ),
              ],
        ),
      },
    );
  }

  Future<void> _rename(BuildContext context) async {
    final title = await showDialog<String>(
      context: context,
      builder: (context) => _RenameDialog(initial: session.title),
    );

    final trimmed = title?.trim();
    if (trimmed == null || trimmed.isEmpty) return;
    await controller.onRenameSession(session.id, trimmed);
  }
}

/// Owns its own field controller: disposing one from the caller would kill it
/// while the dialog route is still animating out and still rebuilding.
class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.initial});

  final String initial;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final _field = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rename chat'),
      content: TextField(
        controller: _field,
        autofocus: true,
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_field.text),
          child: const Text('Rename'),
        ),
      ],
    );
  }
}

enum _SessionAction { rename, delete }

class _NoSessions extends StatelessWidget {
  const _NoSessions();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'No conversations',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _LoadMore extends StatelessWidget {
  const _LoadMore({required this.controller});

  final ChatController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.isLoadingSessions) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: TextButton(
          onPressed: controller.onLoadMoreSessions,
          child: const Text('Load more'),
        ),
      ),
    );
  }
}
