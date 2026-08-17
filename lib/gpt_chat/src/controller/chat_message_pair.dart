import '../adapter/chat_message.dart';

/// One exchange: a user question and the assistant reply to it.
///
/// The default transcript renders pairs rather than a flat message list, so a
/// question and its answer stay visually joined and the separator falls between
/// exchanges instead of between every message.
class ChatMessagePair {
  const ChatMessagePair({required this.question, this.answer});

  final ChatMessage question;

  /// Null between sending a question and the reply being created — the pair is
  /// still rendered so the question appears immediately.
  final ChatMessage? answer;

  bool get isAwaitingAnswer => answer == null;
  bool get isStreaming => answer?.isStreaming ?? false;
  bool get hasFailed => answer?.hasFailed ?? false;

  /// Stable key for the exchange.
  String get id => question.id;

  /// Groups a flat message list into exchanges.
  ///
  /// Pairs by role rather than by index: a trailing question with no reply yet
  /// still yields a pair, and consecutive messages of the same role do not
  /// shift every later pair out of alignment. System messages are dropped —
  /// they are context, not conversation.
  static List<ChatMessagePair> fromMessages(List<ChatMessage> messages) {
    final visible = messages.where((m) => !m.isSystem).toList();
    final pairs = <ChatMessagePair>[];

    for (var i = 0; i < visible.length; i++) {
      final message = visible[i];
      if (!message.isUser) {
        // An assistant message with no question before it (a greeting, or a
        // restored session that starts mid-thread) still needs to render.
        if (pairs.isEmpty || pairs.last.answer != null) {
          pairs.add(ChatMessagePair(question: message, answer: null));
        }
        continue;
      }

      final next = i + 1 < visible.length ? visible[i + 1] : null;
      if (next != null && !next.isUser) {
        pairs.add(ChatMessagePair(question: message, answer: next));
        i++;
      } else {
        pairs.add(ChatMessagePair(question: message));
      }
    }

    return pairs;
  }
}
