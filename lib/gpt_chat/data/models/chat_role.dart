/// Author of a chat message, mapped to the OpenAI `role` field.
enum ChatRole {
  system('system'),
  user('user'),
  assistant('assistant');

  const ChatRole(this.wireName);

  /// Value sent to / received from the API.
  final String wireName;

  static ChatRole fromWire(String value) =>
      ChatRole.values.firstWhere((e) => e.wireName == value, orElse: () => ChatRole.assistant);
}
