import 'chat_message.dart';

/// One conversation thread.
class ChatSession {
  const ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.messages = const [],
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatMessage> messages;

  bool get isEmpty => messages.isEmpty;

  ChatSession copyWith({
    String? title,
    DateTime? updatedAt,
    List<ChatMessage>? messages,
  }) {
    return ChatSession(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
    );
  }

  /// Replaces a message by id, keeping order.
  ChatSession withMessage(ChatMessage message) {
    final index = messages.indexWhere((m) => m.id == message.id);
    final next = [...messages];
    if (index == -1) {
      next.add(message);
    } else {
      next[index] = message;
    }
    return copyWith(messages: next, updatedAt: message.createdAt);
  }

  ChatSession withoutMessage(String messageId) =>
      copyWith(messages: messages.where((m) => m.id != messageId).toList());
}
