/// Author of a chat message, mapped to the OpenAI `role` field.
enum ChatRole {
  system('system'),
  user('user'),
  assistant('assistant');

  const ChatRole(this.wireName);

  /// Value sent to / received from the API.
  final String wireName;

  static ChatRole fromWire(String value) => ChatRole.values.firstWhere(
    (e) => e.wireName == value,
    orElse: () => ChatRole.assistant,
  );
}

/// Delivery state of a single message.
enum ChatMessageStatus { sending, streaming, done, error }

/// What the chat UI needs in order to render a message.
///
/// This is an *interface*, not a base class, so a host can keep its own message
/// type exactly as it is — mutable, a `ChangeNotifier`, backed by a DTO — and
/// simply satisfy these six getters:
///
/// ```dart
/// class MyMessage extends ChangeNotifier implements ChatMessage {
///   @override String get id => …;
///   @override ChatRole get role => isFromUser ? ChatRole.user : ChatRole.assistant;
///   @override ChatMessageStatus get status =>
///       processing ? ChatMessageStatus.streaming : ChatMessageStatus.done;
///   // …plus every field of your own.
/// }
/// ```
///
/// When the implementation is also a [Listenable], the transcript subscribes to
/// each message individually, so a streaming reply rebuilds one bubble instead
/// of the whole list.
abstract interface class ChatMessage {
  String get id;
  ChatRole get role;

  /// Markdown, rendered by `GptMarkdown` for assistant messages.
  String get content;

  DateTime get createdAt;
  ChatMessageStatus get status;

  /// Failure text for [ChatMessageStatus.error], else null.
  String? get error;
}

/// Convenience predicates shared by every implementation.
extension ChatMessageX on ChatMessage {
  bool get isUser => role == ChatRole.user;
  bool get isAssistant => role == ChatRole.assistant;
  bool get isSystem => role == ChatRole.system;
  bool get isStreaming => status == ChatMessageStatus.streaming;
  bool get isSending => status == ChatMessageStatus.sending;
  bool get hasFailed => status == ChatMessageStatus.error;

  /// True while a reply has been requested but no token has arrived.
  bool get isAwaitingFirstToken => isStreaming && content.isEmpty;

  /// Request payload shape expected by an OpenAI-compatible `/chat/completions`.
  Map<String, dynamic> toRequestJson() => {
    'role': role.wireName,
    'content': content,
  };
}

/// The package's own immutable [ChatMessage].
///
/// Used by [StreamingChatAdapter] and by any host with nothing extra to carry.
/// Hosts with a richer model implement [ChatMessage] on their own type instead.
class SimpleChatMessage implements ChatMessage {
  const SimpleChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.status = ChatMessageStatus.done,
    this.error,
  });

  @override
  final String id;
  @override
  final ChatRole role;
  @override
  final String content;
  @override
  final DateTime createdAt;
  @override
  final ChatMessageStatus status;
  @override
  final String? error;

  SimpleChatMessage copyWith({
    String? content,
    ChatMessageStatus? status,
    String? error,
  }) {
    return SimpleChatMessage(
      id: id,
      role: role,
      content: content ?? this.content,
      createdAt: createdAt,
      status: status ?? this.status,
      error: error ?? this.error,
    );
  }

  @override
  String toString() => 'SimpleChatMessage($id, ${role.wireName}, $status)';
}
