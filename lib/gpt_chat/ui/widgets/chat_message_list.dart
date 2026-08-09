import 'package:flutter/material.dart';

import '../../data/models/chat_message.dart';
import 'chat_bubble.dart';

/// Scrollable transcript. Reversed so new tokens stay pinned to the bottom.
class ChatMessageList extends StatelessWidget {
  const ChatMessageList({super.key, required this.messages});

  final List<ChatMessage> messages;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      itemCount: messages.length,
      itemBuilder: (context, index) => ChatBubble(message: messages[messages.length - 1 - index]),
    );
  }
}
