import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_chat.dart';

/// The whole backend: no HTTP, no gateway, no config.
///
/// [StreamingChatAdapter] takes care of sessions, titling, cancellation, retry
/// and persistence; all it wants is a stream of deltas.
class EchoAdapter extends StreamingChatAdapter {
  @override
  ChatCapabilities get capabilities =>
      const ChatCapabilities(suggestions: true);

  @override
  Stream<ChatDelta> streamReply(List<ChatMessage> history) async* {
    final question = history.last.content;

    yield const ChatDelta('You asked:\n\n> ');
    for (final word in question.split(' ')) {
      await Future<void>.delayed(const Duration(milliseconds: 40));
      yield ChatDelta('$word ');
    }
    yield const ChatDelta(
      '\n\nHere is some **markdown**, a formula \$\\int_0^1 x^2 dx\$, '
      'and a code block:\n\n```dart\nvoid main() => print("hi");\n```',
    );
  }
}

/// Level 1 — nothing but a theme.
class PlainChat extends StatefulWidget {
  const PlainChat({super.key});

  @override
  State<PlainChat> createState() => _PlainChatState();
}

class _PlainChatState extends State<PlainChat> {
  final _adapter = EchoAdapter();

  @override
  void dispose() {
    _adapter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GptChat(
      adapter: _adapter,
      theme: const ChatTheme(
        contentMaxWidth: 720,
        questionBubbleRadius: BorderRadius.all(Radius.circular(22)),
        hintText: 'Say something',
      ),
    );
  }
}

/// Levels 2 and 3 — slots, showing that overriding one level never costs you
/// the levels beneath it.
class CustomisedChat extends StatefulWidget {
  const CustomisedChat({super.key});

  @override
  State<CustomisedChat> createState() => _CustomisedChatState();
}

class _CustomisedChatState extends State<CustomisedChat> {
  final _adapter = EchoAdapter();

  @override
  void dispose() {
    _adapter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GptChat(
      adapter: _adapter,
      builders: ChatBuilders(
        // A leaf, replaced outright.
        empty: (s) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Echo', style: TextStyle(fontSize: 32)),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => s.controller.prefill('Hello there'),
                child: const Text('Try it'),
              ),
            ],
          ),
        ),

        // A leaf, decorated: `s.child` is the widget the package would have
        // drawn.
        answerText: (s) => Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: s.child,
        ),

        // A section of our own, before the answer.
        answerAbove: [
          (s) => s.message.isStreaming
              ? const LinearProgressIndicator(minHeight: 2)
              : const SizedBox.shrink(),
        ],

        // The answer recomposed — every part still comes from the package.
        answer: (s) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...s.above,
            s.text,
            Text(
              'echoed at ${s.message.createdAt.hour}:${s.message.createdAt.minute}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            s.actions,
          ],
        ),

        // Our own list, the package's exchanges.
        messageList: (s) => ListView.builder(
          controller: s.scrollController,
          padding: const EdgeInsets.only(top: 90, bottom: 140),
          itemCount: s.count,
          itemBuilder: (context, index) => s.item(index),
        ),

        // Our own composer accessory.
        composerLeading: [
          (s) => IconButton(
                icon: const Icon(Icons.mood),
                tooltip: 'Prefill',
                onPressed: () => s.controller.prefill('😀 '),
              ),
        ],
      ),
    );
  }
}

/// A page offering both.
class AdapterDemoPage extends StatelessWidget {
  const AdapterDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adapter demo')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'The same EchoAdapter, rendered two ways. No gateway, no network.',
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (context) => const PlainChat()),
            ),
            child: const Text('Defaults + theme only'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const CustomisedChat(),
              ),
            ),
            child: const Text('With slot overrides'),
          ),
        ],
      ),
    );
  }
}
