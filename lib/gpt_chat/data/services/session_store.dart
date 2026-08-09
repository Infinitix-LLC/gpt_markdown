import '../models/chat_session.dart';

/// Persistence boundary for sessions. Swap in a disk/db backed implementation
/// without touching the repository or view model.
abstract class ChatSessionStore {
  Future<List<ChatSession>> loadAll();
  Future<void> save(ChatSession session);
  Future<void> delete(String sessionId);
}

/// Default store — lives for the lifetime of the widget.
class InMemorySessionStore implements ChatSessionStore {
  final Map<String, ChatSession> _sessions = {};

  @override
  Future<List<ChatSession>> loadAll() async {
    final all = _sessions.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return all;
  }

  @override
  Future<void> save(ChatSession session) async => _sessions[session.id] = session;

  @override
  Future<void> delete(String sessionId) async => _sessions.remove(sessionId);
}
