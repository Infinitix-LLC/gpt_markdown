import 'chat_session.dart';

/// Persistence boundary for [StreamingChatAdapter].
///
/// Hosts implementing [ChatAdapter] directly do not need this — their own data
/// layer already is the store.
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
  Future<void> save(ChatSession session) async =>
      _sessions[session.id] = session;

  @override
  Future<void> delete(String sessionId) async => _sessions.remove(sessionId);
}

/// Monotonic ids, unique within a process run. No external uuid dependency.
class IdGenerator {
  int _counter = 0;

  String next([String prefix = 'id']) {
    _counter++;
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}-$_counter';
  }
}
