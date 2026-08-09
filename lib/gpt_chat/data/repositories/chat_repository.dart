import '../models/chat_message.dart';

/// Produces assistant replies for a conversation.
/// Implement this to swap providers or to fake the network in tests.
abstract class ChatRepository {
  /// Emits text deltas, in order. Throws [ChatException] on failure.
  /// Animations announced alongside the text are published to the artifact
  /// repository rather than returned here.
  Stream<String> streamReply(List<ChatMessage> history);

  /// Switching between an OpenAI and a Gemini model is a one-word change.
  void selectModel(String model);

  void dispose();
}
