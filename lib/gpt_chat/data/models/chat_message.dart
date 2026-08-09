import 'chat_role.dart';

/// Delivery state of a single message.
enum ChatMessageStatus { sending, streaming, done, error }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.status = ChatMessageStatus.done,
    this.error,
  });

  final String id;
  final ChatRole role;
  final String content;
  final DateTime createdAt;
  final ChatMessageStatus status;
  final String? error;

  bool get isUser => role == ChatRole.user;
  bool get isStreaming => status == ChatMessageStatus.streaming;
  bool get hasFailed => status == ChatMessageStatus.error;

  ChatMessage copyWith({
    String? content,
    ChatMessageStatus? status,
    String? error,
  }) {
    return ChatMessage(
      id: id,
      role: role,
      content: content ?? this.content,
      createdAt: createdAt,
      status: status ?? this.status,
      error: error ?? this.error,
    );
  }

  /// Request payload shape expected by `/chat/completions`.
  Map<String, dynamic> toRequestJson() => {
    'role': role.wireName,
    'content': content,
  };
}
