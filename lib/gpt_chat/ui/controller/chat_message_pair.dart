import '../../data/models/chat_message.dart';

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

  /// Groups a flat message list into exchanges.
  ///
  /// Pairs by role rather than by index: a trailing question with no reply yet
  /// still yields a pair, and consecutive messages of the same role do not
  /// shift every later pair out of alignment.
  static List<ChatMessagePair> fromMessages(List<ChatMessage> messages) {
    final pairs = <ChatMessagePair>[];

    for (var i = 0; i < messages.length; i++) {
      final message = messages[i];
      if (!message.isUser) {
        // An assistant message with no question before it (a greeting, or a
        // restored session that starts mid-thread) still needs to render.
        if (pairs.isEmpty || pairs.last.answer != null) {
          pairs.add(ChatMessagePair(question: message, answer: null));
        }
        continue;
      }

      final next = i + 1 < messages.length ? messages[i + 1] : null;
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
