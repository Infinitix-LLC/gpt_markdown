import 'package:flutter/foundation.dart';

import 'chat_message.dart';
import 'chat_session.dart';

/// The immutable picture of a conversation the UI renders.
///
/// A host with no notion of sessions passes [messages] alone; a host with a
/// session list passes [sessions] + [activeSessionId] and lets [messages] derive
/// from the active one.
@immutable
class ChatSnapshot {
  const ChatSnapshot({
    this.sessions = const [],
    this.activeSessionId,
    List<ChatMessage>? messages,
    this.isLoading = false,
    this.isResponding = false,
    this.error,
    this.hasMoreSessions = false,
    this.isLoadingSessions = false,
  }) : _messages = messages;

  final List<ChatSession> sessions;
  final String? activeSessionId;

  final List<ChatMessage>? _messages;

  /// True while the conversation is still being restored — the screen shows the
  /// loading slot instead of the transcript.
  final bool isLoading;

  /// A reply is in flight.
  final bool isResponding;

  /// The last failure, shown as a dismissible banner. Null once cleared.
  final String? error;

  /// More sessions exist beyond the ones loaded.
  final bool hasMoreSessions;

  /// A page of sessions is being fetched.
  final bool isLoadingSessions;

  ChatSession? get activeSession {
    for (final session in sessions) {
      if (session.id == activeSessionId) return session;
    }
    return null;
  }

  /// Explicit [messages] when the adapter supplied them, else the active
  /// session's.
  List<ChatMessage> get messages =>
      _messages ?? activeSession?.messages ?? const [];

  bool get isEmpty => messages.isEmpty;

  ChatSnapshot copyWith({
    List<ChatSession>? sessions,
    String? activeSessionId,
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isResponding,
    String? error,
    bool clearError = false,
    bool? hasMoreSessions,
    bool? isLoadingSessions,
  }) {
    return ChatSnapshot(
      sessions: sessions ?? this.sessions,
      activeSessionId: activeSessionId ?? this.activeSessionId,
      messages: messages ?? _messages,
      isLoading: isLoading ?? this.isLoading,
      isResponding: isResponding ?? this.isResponding,
      error: clearError ? null : (error ?? this.error),
      hasMoreSessions: hasMoreSessions ?? this.hasMoreSessions,
      isLoadingSessions: isLoadingSessions ?? this.isLoadingSessions,
    );
  }
}
