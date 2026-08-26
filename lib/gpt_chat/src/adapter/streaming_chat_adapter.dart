import 'dart:async';

import 'chat_adapter.dart';
import 'chat_capabilities.dart';
import 'chat_delta.dart';
import 'chat_draft.dart';
import 'chat_message.dart';
import 'chat_session.dart';
import 'chat_snapshot.dart';
import 'session_store.dart';

/// A [ChatAdapter] for hosts with no state layer of their own.
///
/// Implements the whole conversation lifecycle — sessions, titling, message
/// minting, streaming, cancellation, retry, persistence — on top of one method:
///
/// ```dart
/// class EchoAdapter extends StreamingChatAdapter {
///   @override
///   Stream<ChatDelta> streamReply(List<ChatMessage> history) async* {
///     for (final word in history.last.content.split(' ')) {
///       await Future<void>.delayed(const Duration(milliseconds: 60));
///       yield ChatDelta('$word ');
///     }
///   }
/// }
/// ```
///
/// Hosts that already own their conversation state should extend [ChatAdapter]
/// directly instead — this class would be a second source of truth.
abstract class StreamingChatAdapter extends ChatAdapter {
  StreamingChatAdapter({ChatSessionStore? store, IdGenerator? ids})
    : _store = store ?? InMemorySessionStore(),
      _ids = ids ?? IdGenerator();

  final ChatSessionStore _store;
  final IdGenerator _ids;

  ChatSnapshot _snapshot = const ChatSnapshot(isLoading: true);
  StreamSubscription<ChatDelta>? _subscription;
  bool _initialised = false;

  @override
  ChatSnapshot get snapshot => _snapshot;

  @override
  ChatCapabilities get capabilities => const ChatCapabilities();

  /// Emits the reply to [history], in order. Throw to fail the reply — the
  /// exception's `toString()` becomes the error shown to the user.
  Stream<ChatDelta> streamReply(List<ChatMessage> history);

  /// Title given to a conversation before the first message.
  String get newSessionTitle => 'New chat';

  /// Longest title derived from the first user message.
  int get titleLength => 40;

  // ------------------------------------------------------------ lifecycle ---

  @override
  Future<void> init() async {
    if (_initialised) return;
    _initialised = true;

    final stored = await _store.loadAll();
    final active = stored.isNotEmpty ? stored.first : await _createSession();

    _emit(
      _snapshot.copyWith(
        sessions: stored.isNotEmpty ? stored : [active],
        activeSessionId: active.id,
        isLoading: false,
      ),
    );
  }

  @override
  Future<void> newSession() async {
    final current = _snapshot.activeSession;
    if (current != null && current.isEmpty) return selectSession(current.id);

    await _cancel();
    final session = await _createSession();
    _emit(
      _upsert(session).copyWith(activeSessionId: session.id, clearError: true),
    );
  }

  @override
  Future<void> selectSession(String sessionId) async {
    if (sessionId == _snapshot.activeSessionId) return;

    await _cancel();
    _emit(
      _snapshot.copyWith(
        activeSessionId: sessionId,
        isResponding: false,
        clearError: true,
      ),
    );
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    await _store.delete(sessionId);
    final remaining =
        _snapshot.sessions.where((s) => s.id != sessionId).toList();
    final wasActive = sessionId == _snapshot.activeSessionId;

    if (wasActive) await _cancel();
    _emit(_snapshot.copyWith(sessions: remaining, isResponding: false));

    if (!wasActive) return;
    final next =
        remaining.isNotEmpty ? remaining.first : await _createSession();
    _emit(_upsert(next).copyWith(activeSessionId: next.id));
  }

  @override
  Future<void> renameSession(String sessionId, String title) async {
    final session = _sessionById(sessionId);
    if (session == null) return;

    final renamed = session.copyWith(title: title);
    await _store.save(renamed);
    _emit(_upsert(renamed));
  }

  // ---------------------------------------------------------------- send ---

  @override
  Future<void> send(ChatDraft draft) async {
    final prompt = draft.text.trim();
    if (prompt.isEmpty || _snapshot.isResponding) return;

    var session = _snapshot.activeSession ?? await _createSession();
    session = _titled(
      session,
      prompt,
    ).withMessage(newMessage(role: ChatRole.user, content: prompt));

    final reply = newMessage(
      role: ChatRole.assistant,
      content: '',
      status: ChatMessageStatus.streaming,
    );
    // Exercise the hook once, here, where the stack still points at the send.
    // Left to the stream, a missing `updateMessage` override surfaces as an
    // async error inside the subscription — and then again inside the error
    // handler that tries to record it. Debug-only, so release pays nothing.
    assert(() {
      updateMessage(reply);
      return true;
    }());
    session = session.withMessage(reply);

    _emit(
      _upsert(session).copyWith(
        activeSessionId: session.id,
        isResponding: true,
        clearError: true,
      ),
    );

    _listen(
      session.id,
      reply.id,
      session.messages.where((m) => m.id != reply.id).toList(),
    );
  }

  @override
  Future<void> retryLast() async {
    final session = _snapshot.activeSession;
    if (session == null || _snapshot.isResponding) return;

    final index = session.messages.lastIndexWhere((m) => m.hasFailed);
    if (index <= 0) return;

    final failed = session.messages[index];
    final prompt = session.messages[index - 1];
    _emit(_upsert(session.withoutMessage(failed.id).withoutMessage(prompt.id)));
    await send(ChatDraft(text: prompt.content));
  }

  /// Cancels the in-flight reply, keeping whatever text already arrived.
  ///
  /// The state flips before the transport is torn down. Cancelling a stream can
  /// take arbitrarily long — or hang, if the transport never acknowledges — and
  /// making the UI wait would leave the user staring at a Stop button that does
  /// nothing and a composer that refuses to send.
  @override
  Future<void> stop() async {
    final subscription = _subscription;
    _subscription = null;

    final session = _snapshot.activeSession;
    ChatSession? updated;

    if (session != null) {
      updated = session;
      for (final message in session.messages.where((m) => m.isStreaming)) {
        updated = updated!.withMessage(
          updateMessage(message, status: ChatMessageStatus.done),
        );
      }
      _emit(_upsert(updated!).copyWith(isResponding: false));
    } else {
      _emit(_snapshot.copyWith(isResponding: false));
    }

    await subscription?.cancel();
    if (updated != null) await _store.save(updated);
  }

  @override
  void clearError() => _emit(_snapshot.copyWith(clearError: true));

  // ---------------------------------------------------------- extensible ---

  /// Mints a message.
  ///
  /// Override to return **your own** [ChatMessage] type — the rest of this
  /// class only ever hands messages back through [updateMessage], so a host
  /// model with fields of its own flows through untouched.
  ChatMessage newMessage({
    required ChatRole role,
    required String content,
    ChatMessageStatus status = ChatMessageStatus.done,
  }) {
    return SimpleChatMessage(
      id: _ids.next('msg'),
      role: role,
      content: content,
      createdAt: DateTime.now(),
      status: status,
    );
  }

  /// Returns [message] with the given fields changed.
  ///
  /// The one hook a custom message type must override. Mutable models may
  /// mutate and return the same instance; immutable ones return a copy.
  ///
  /// ```dart
  /// @override
  /// ChatMessage updateMessage(ChatMessage message, {String? content, ...}) {
  ///   (message as MyMessage).update(content: content, ...);
  ///   return message;
  /// }
  /// ```
  ChatMessage updateMessage(
    ChatMessage message, {
    String? content,
    ChatMessageStatus? status,
    String? error,
  }) {
    if (message is! SimpleChatMessage) {
      throw StateError(
        'StreamingChatAdapter.newMessage returned a ${message.runtimeType}, so '
        'updateMessage must be overridden to know how to change one.',
      );
    }
    return message.copyWith(content: content, status: status, error: error);
  }

  /// Folds one chunk into the reply.
  ///
  /// [buffered] is the text accumulated so far, already accounting for
  /// [ChatDelta.replaces]. Override to also route [ChatDelta.payload] — sources,
  /// tool status, media — into fields of your own:
  ///
  /// ```dart
  /// @override
  /// ChatMessage applyDelta(ChatMessage reply, ChatDelta delta, String buffered) {
  ///   final chunk = delta.payload;
  ///   if (chunk is MyChunk) (reply as MyMessage).update(sources: chunk.sources);
  ///   return super.applyDelta(reply, delta, buffered);
  /// }
  /// ```
  ChatMessage applyDelta(ChatMessage reply, ChatDelta delta, String buffered) =>
      updateMessage(reply, content: buffered);

  // -------------------------------------------------------------- private ---

  Future<ChatSession> _createSession() async {
    final now = DateTime.now();
    final session = ChatSession(
      id: _ids.next('sess'),
      title: newSessionTitle,
      createdAt: now,
      updatedAt: now,
    );
    await _store.save(session);
    return session;
  }

  /// First user message becomes the session title.
  ChatSession _titled(ChatSession session, String text) {
    if (!session.isEmpty) return session;

    final trimmed = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    final title =
        trimmed.length > titleLength
            ? '${trimmed.substring(0, titleLength)}…'
            : trimmed;
    return title.isEmpty ? session : session.copyWith(title: title);
  }

  void _listen(String sessionId, String replyId, List<ChatMessage> history) {
    final buffer = StringBuffer();

    _subscription = streamReply(history).listen(
      (delta) {
        if (delta.replaces) {
          buffer
            ..clear()
            ..write(delta.text);
        } else {
          buffer.write(delta.text);
        }
        _updateReply(
          sessionId,
          replyId,
          (m) => applyDelta(m, delta, buffer.toString()),
        );
      },
      onError:
          (Object error) =>
              _failReply(sessionId, replyId, error, buffer.toString()),
      onDone: () => _finishReply(sessionId, replyId, buffer.toString()),
      cancelOnError: true,
    );
  }

  void _finishReply(String sessionId, String replyId, String content) {
    _subscription = null;
    _updateReply(
      sessionId,
      replyId,
      (m) => updateMessage(m, content: content, status: ChatMessageStatus.done),
      isResponding: false,
      persist: true,
    );
  }

  void _failReply(
    String sessionId,
    String replyId,
    Object error,
    String partial,
  ) {
    _subscription = null;
    final message = error.toString();

    _updateReply(
      sessionId,
      replyId,
      (m) => updateMessage(
        m,
        content: partial,
        status: ChatMessageStatus.error,
        error: message,
      ),
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
    if (persist) unawaited(_store.save(updated));

    _emit(_upsert(updated).copyWith(isResponding: isResponding, error: error));
  }

  ChatSession? _sessionById(String id) {
    for (final session in _snapshot.sessions) {
      if (session.id == id) return session;
    }
    return null;
  }

  /// Replaces a session in the list, newest activity first.
  ChatSnapshot _upsert(ChatSession session) {
    final next =
        _snapshot.sessions.where((s) => s.id != session.id).toList()
          ..add(session);
    next.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return _snapshot.copyWith(sessions: next);
  }

  Future<void> _cancel() async {
    final subscription = _subscription;
    _subscription = null;
    await subscription?.cancel();
  }

  void _emit(ChatSnapshot next) {
    _snapshot = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
