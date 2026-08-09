import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/chat_exception.dart';
import '../../data/models/chat_message.dart';
import '../../data/models/chat_role.dart';
import '../../data/models/chat_session.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/session_repository.dart';
import 'chat_state.dart';

/// Single source of truth for the chat UI. Widgets call these methods and
/// render [state]; they never touch repositories directly.
class ChatViewModel extends ChangeNotifier {
  ChatViewModel({required ChatRepository chatRepository, required SessionRepository sessionRepository})
    : _chat = chatRepository,
      _sessions = sessionRepository;

  final ChatRepository _chat;
  final SessionRepository _sessions;

  ChatState _state = const ChatState();
  ChatState get state => _state;

  StreamSubscription<String>? _replySubscription;

  /// Restores stored sessions and makes sure one is active.
  Future<void> init() async {
    final stored = await _sessions.loadAll();
    final active = stored.isNotEmpty ? stored.first : await _sessions.create();

    _emit(
      _state.copyWith(
        sessions: stored.isNotEmpty ? stored : [active],
        activeSessionId: active.id,
        isLoading: false,
      ),
    );
  }

  Future<void> newSession() async {
    final current = _state.activeSession;
    if (current != null && current.isEmpty) return selectSession(current.id);

    await _stopStream();
    final session = await _sessions.create();
    _emit(_upsert(session).copyWith(activeSessionId: session.id, clearError: true));
  }

  Future<void> selectSession(String sessionId) async {
    if (sessionId == _state.activeSessionId) return;

    await _stopStream();
    _emit(_state.copyWith(activeSessionId: sessionId, isResponding: false, clearError: true));
  }

  Future<void> deleteSession(String sessionId) async {
    await _sessions.delete(sessionId);
    final remaining = _state.sessions.where((s) => s.id != sessionId).toList();

    if (sessionId == _state.activeSessionId) await _stopStream();
    _emit(_state.copyWith(sessions: remaining, isResponding: false));

    if (sessionId == _state.activeSessionId) {
      final next = remaining.isNotEmpty ? remaining.first : await _sessions.create();
      _emit(_upsert(next).copyWith(activeSessionId: next.id));
    }
  }

  /// Appends the user message and streams the assistant reply into place.
  Future<void> send(String text) async {
    final prompt = text.trim();
    if (prompt.isEmpty || _state.isResponding) return;

    var session = _state.activeSession ?? await _sessions.create();
    session = _sessions
        .titleFrom(session, prompt)
        .withMessage(_sessions.newMessage(role: ChatRole.user, content: prompt));

    final reply = _sessions.newMessage(
      role: ChatRole.assistant,
      content: '',
      status: ChatMessageStatus.streaming,
    );
    session = session.withMessage(reply);

    _emit(_upsert(session).copyWith(activeSessionId: session.id, isResponding: true, clearError: true));
    _listen(session.id, reply.id, session.messages.where((m) => m.id != reply.id).toList());
  }

  /// Drops the failed reply and re-sends the message before it.
  Future<void> retryLast() async {
    final session = _state.activeSession;
    if (session == null || _state.isResponding) return;

    final index = session.messages.lastIndexWhere((m) => m.hasFailed);
    if (index <= 0) return;

    final failed = session.messages[index];
    final prompt = session.messages[index - 1];
    _emit(_upsert(session.withoutMessage(failed.id).withoutMessage(prompt.id)));
    await send(prompt.content);
  }

  /// Cancels the in-flight reply, keeping whatever text already arrived.
  Future<void> stop() async {
    await _stopStream();
    final session = _state.activeSession;
    if (session == null) return;

    final streaming = session.messages.where((m) => m.isStreaming).toList();
    var updated = session;
    for (final message in streaming) {
      updated = updated.withMessage(message.copyWith(status: ChatMessageStatus.done));
    }
    await _sessions.save(updated);
    _emit(_upsert(updated).copyWith(isResponding: false));
  }

  void clearError() => _emit(_state.copyWith(clearError: true));

  void _listen(String sessionId, String replyId, List<ChatMessage> history) {
    final buffer = StringBuffer();

    _replySubscription = _chat.streamReply(history).listen(
      (delta) {
        buffer.write(delta);
        _updateReply(sessionId, replyId, (m) => m.copyWith(content: buffer.toString()));
      },
      onError: (Object error) => _failReply(sessionId, replyId, error, buffer.toString()),
      onDone: () => _finishReply(sessionId, replyId, buffer.toString()),
      cancelOnError: true,
    );
  }

  void _finishReply(String sessionId, String replyId, String content) {
    _replySubscription = null;
    _updateReply(
      sessionId,
      replyId,
      (m) => m.copyWith(content: content, status: ChatMessageStatus.done),
      isResponding: false,
      persist: true,
    );
  }

  void _failReply(String sessionId, String replyId, Object error, String partial) {
    _replySubscription = null;
    final message = error is ChatException ? error.message : error.toString();

    _updateReply(
      sessionId,
      replyId,
      (m) => m.copyWith(content: partial, status: ChatMessageStatus.error, error: message),
      isResponding: false,
      persist: true,
      error: message,
    );
  }

  void _updateReply(
    String sessionId,
    String replyId,
    ChatMessage Function(ChatMessage) transform, {
    bool? isResponding,
    bool persist = false,
    String? error,
  }) {
    final session = _sessionById(sessionId);
    if (session == null) return;

    final index = session.messages.indexWhere((m) => m.id == replyId);
    if (index == -1) return;

    final updated = session.withMessage(transform(session.messages[index]));
    if (persist) unawaited(_sessions.save(updated));

    _emit(_upsert(updated).copyWith(isResponding: isResponding, error: error));
  }

  ChatSession? _sessionById(String id) {
    for (final session in _state.sessions) {
      if (session.id == id) return session;
    }
    return null;
  }

  /// Replaces a session in the list, newest activity first.
  ChatState _upsert(ChatSession session) {
    final next = _state.sessions.where((s) => s.id != session.id).toList()..add(session);
    next.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return _state.copyWith(sessions: next);
  }

  Future<void> _stopStream() async {
    final subscription = _replySubscription;
    _replySubscription = null;
    await subscription?.cancel();
  }

  void _emit(ChatState next) {
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _replySubscription?.cancel();
    _chat.dispose();
    super.dispose();
  }
}
