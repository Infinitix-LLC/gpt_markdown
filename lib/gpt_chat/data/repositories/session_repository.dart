import '../models/chat_message.dart';
import '../models/chat_role.dart';
import '../models/chat_session.dart';
import '../services/id_generator.dart';
import '../services/session_store.dart';

/// Owns session lifecycle: creation, titling, message minting and persistence.
class SessionRepository {
  SessionRepository({ChatSessionStore? store, IdGenerator? ids})
    : _store = store ?? InMemorySessionStore(),
      _ids = ids ?? IdGenerator();

  final ChatSessionStore _store;
  final IdGenerator _ids;

  Future<List<ChatSession>> loadAll() => _store.loadAll();

  Future<ChatSession> create({String title = 'New chat'}) async {
    final now = DateTime.now();
    final session = ChatSession(id: _ids.next('sess'), title: title, createdAt: now, updatedAt: now);
    await _store.save(session);
    return session;
  }

  Future<void> save(ChatSession session) => _store.save(session);

  Future<void> delete(String sessionId) => _store.delete(sessionId);

  ChatMessage newMessage({
    required ChatRole role,
    required String content,
    ChatMessageStatus status = ChatMessageStatus.done,
  }) {
    return ChatMessage(
      id: _ids.next('msg'),
      role: role,
      content: content,
      createdAt: DateTime.now(),
      status: status,
    );
  }

  /// First user message becomes the session title.
  ChatSession titleFrom(ChatSession session, String text) {
    if (!session.isEmpty) return session;

    final trimmed = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    final title = trimmed.length > 40 ? '${trimmed.substring(0, 40)}…' : trimmed;
    return title.isEmpty ? session : session.copyWith(title: title);
  }
}
