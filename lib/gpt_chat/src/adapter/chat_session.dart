import 'chat_message.dart';

/// One conversation thread.
///
/// Hosts that already model conversations (threads, rooms, documents) map theirs
/// onto this for the drawer; nothing here is persisted by the package itself.
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

  /// Drives ordering in the drawer and the Today / Yesterday grouping.
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

  /// Replaces a message by id, keeping order. Appends when it is new.
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

  @override
  String toString() =>
      'ChatSession($id, "$title", ${messages.length} messages)';
}
