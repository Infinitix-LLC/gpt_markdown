import '../../data/models/chat_message.dart';
import '../../data/models/chat_session.dart';

/// Immutable snapshot the widgets render. No logic beyond derived getters.
class ChatState {
  const ChatState({
    this.sessions = const [],
    this.activeSessionId,
    this.isLoading = true,
    this.isResponding = false,
    this.error,
  });

  final List<ChatSession> sessions;
  final String? activeSessionId;

  /// Sessions are still being restored from the store.
  final bool isLoading;

  /// A reply is in flight.
  final bool isResponding;

  /// Last failure, shown as a dismissible banner.
  final String? error;

  ChatSession? get activeSession {
    for (final session in sessions) {
      if (session.id == activeSessionId) return session;
    }
    return null;
  }

  List<ChatMessage> get messages => activeSession?.messages ?? const [];

  bool get isEmpty => messages.isEmpty;

  ChatState copyWith({
    List<ChatSession>? sessions,
    String? activeSessionId,
    bool? isLoading,
    bool? isResponding,
    String? error,
    bool clearError = false,
  }) {
    return ChatState(
      sessions: sessions ?? this.sessions,
      activeSessionId: activeSessionId ?? this.activeSessionId,
      isLoading: isLoading ?? this.isLoading,
      isResponding: isResponding ?? this.isResponding,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
