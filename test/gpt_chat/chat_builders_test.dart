import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_markdown/gpt_chat/gpt_chat.dart';

import 'fakes.dart';

/// A reply long enough that the transcript actually overflows its viewport.
String get _longReply => List.generate(60, (i) => 'Line $i of the reply.').join('\n\n');

void main() {
  Future<ChatController> pumpChat(
    WidgetTester tester, {
    ChatBuilders builders = const ChatBuilders(),
    ChatRepository? repository,
  }) async {
    late ChatController controller;
    await tester.pumpWidget(
      MaterialApp(
        home: GptChat(
          config: testConfig,
          chatRepository: repository ?? FakeChatRepository(),
          showModelSelector: false,
          builders: builders,
          onControllerReady: (value) => controller = value,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  group('ChatBuilders', () {
    testWidgets('scaffold replaces the whole screen', (tester) async {
      await pumpChat(
        tester,
        builders: ChatBuilders(
          scaffold: (context, controller) =>
              const Scaffold(body: Center(child: Text('my whole ui'))),
        ),
      );

      expect(find.text('my whole ui'), findsOneWidget);
      expect(find.byType(SessionComposer), findsNothing);
    });

    testWidgets('empty, appBar and input are each replaceable', (tester) async {
      await pumpChat(
        tester,
        builders: ChatBuilders(
          empty: (context, controller) => const Center(child: Text('nothing yet')),
          appBar: (context, controller) => const SizedBox(
            height: 72,
            child: Center(child: Text('my bar')),
          ),
          input: (context, controller) => const SizedBox(
            height: 60,
            child: Center(child: Text('my composer')),
          ),
        ),
      );

      expect(find.text('nothing yet'), findsOneWidget);
      expect(find.text('my bar'), findsOneWidget);
      expect(find.text('my composer'), findsOneWidget);
      expect(find.byType(SessionAppBar), findsNothing);
      expect(find.byType(SessionComposer), findsNothing);
    });

    testWidgets('question and answer builders receive the messages', (
      tester,
    ) async {
      final controller = await pumpChat(
        tester,
        repository: FakeChatRepository(deltas: ['the answer']),
        builders: ChatBuilders(
          question: (context, controller, message, isLast) =>
              Text('Q<${message.content}>'),
          answer: (context, controller, message, isLast) =>
              Text('A<${message.content}> last=$isLast'),
        ),
      );

      await controller.onSend('the question');
      await tester.pumpAndSettle();

      expect(find.text('Q<the question>'), findsOneWidget);
      expect(find.text('A<the answer> last=true'), findsOneWidget);
      expect(find.byType(SessionQuestion), findsNothing);
    });

    testWidgets('a custom pair builder owns the whole exchange', (tester) async {
      final controller = await pumpChat(
        tester,
        repository: FakeChatRepository(deltas: ['a']),
        builders: ChatBuilders(
          pair: (context, controller, pair, index, isLast) =>
              Text('pair $index awaiting=${pair.isAwaitingAnswer}'),
        ),
      );

      await controller.onSend('q');
      await tester.pumpAndSettle();

      expect(find.text('pair 0 awaiting=false'), findsOneWidget);
    });

    testWidgets('the error builder gets the message and can dismiss it', (
      tester,
    ) async {
      final controller = await pumpChat(
        tester,
        repository: FakeChatRepository(error: const ChatException('nope')),
        builders: ChatBuilders(
          error: (context, controller, message) => TextButton(
            onPressed: controller.onClearError,
            child: Text('err: $message'),
          ),
        ),
      );

      await controller.onSend('q');
      await tester.pumpAndSettle();
      expect(find.text('err: nope'), findsOneWidget);

      await tester.tap(find.text('err: nope'));
      await tester.pumpAndSettle();
      expect(find.text('err: nope'), findsNothing);
    });

    testWidgets('a custom send button drives onSend', (tester) async {
      final controller = await pumpChat(
        tester,
        repository: FakeChatRepository(deltas: ['ok']),
        builders: ChatBuilders(
          sendButton: (context, controller) => IconButton(
            icon: const Icon(Icons.rocket_launch),
            onPressed: controller.onSend,
          ),
        ),
      );

      controller.input.text = 'via custom button';
      await tester.pump();
      await tester.tap(find.byIcon(Icons.rocket_launch));
      await tester.pumpAndSettle();

      expect(controller.pairs.single.question.content, 'via custom button');
    });

    test('merge layers the other bundle on top', () {
      Widget a(BuildContext context, ChatController controller) =>
          const SizedBox.shrink();
      Widget b(BuildContext context, ChatController controller) =>
          const SizedBox.shrink();

      final base = ChatBuilders(appBar: a, input: a);
      final merged = base.merge(ChatBuilders(input: b));

      expect(merged.appBar, same(a), reason: 'not overridden');
      expect(merged.input, same(b), reason: 'overridden');
    });
  });

  group('question bubble and composer', _questionBubbleTests);

  group('transcript scrolling', () {
    testWidgets('a user scroll away from the bottom stops following', (
      tester,
    ) async {
      final controller = await pumpChat(
        tester,
        repository: FakeChatRepository(deltas: [_longReply]),
      );

      await controller.onSend('q');
      await tester.pumpAndSettle();

      expect(controller.isFollowingLatest, isTrue);
      expect(controller.canJumpToLatest, isFalse);

      // Drag the transcript downwards, i.e. back towards older content.
      await tester.drag(find.byType(SessionTranscript), const Offset(0, 600));
      await tester.pumpAndSettle();

      expect(controller.isFollowingLatest, isFalse);
      expect(controller.canJumpToLatest, isTrue);
    });

    testWidgets('jumping to latest resumes following', (tester) async {
      final controller = await pumpChat(
        tester,
        repository: FakeChatRepository(deltas: [_longReply]),
      );

      await controller.onSend('q');
      await tester.pumpAndSettle();
      await tester.drag(find.byType(SessionTranscript), const Offset(0, 600));
      await tester.pumpAndSettle();
      expect(controller.isFollowingLatest, isFalse);

      controller.onJumpToLatest();
      await tester.pumpAndSettle();

      expect(controller.isFollowingLatest, isTrue);
      expect(controller.canJumpToLatest, isFalse);
    });

    testWidgets('scrolling is never disabled while a reply streams', (
      tester,
    ) async {
      final repository = ManualChatRepository();
      final controller = await pumpChat(tester, repository: repository);

      await controller.onSend('q');
      repository.emit(_longReply);
      await tester.pump();

      // Markdown content nests its own scrollables, so target the transcript's
      // own list rather than any Scrollable in the subtree.
      final list = tester.widget<ListView>(
        find
            .descendant(
              of: find.byType(SessionTranscript),
              matching: find.byType(ListView),
            )
            .first,
      );
      expect(
        list.physics,
        isNot(isA<NeverScrollableScrollPhysics>()),
        reason: 'the user must keep control of the transcript mid-stream',
      );

      repository.finish();
      await tester.pumpAndSettle();
    });
  });
}

/// Bubble and composer behaviour that the plusfinity layout depends on.
void _questionBubbleTests() {
  testWidgets('a long question collapses behind a Show more toggle', (
    tester,
  ) async {
    final long = 'x' * 400;
    late ChatController controller;
    await tester.pumpWidget(
      MaterialApp(
        home: GptChat(
          config: testConfig,
          chatRepository: FakeChatRepository(deltas: ['a']),
          showModelSelector: false,
          onControllerReady: (value) => controller = value,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await controller.onSend(long);
    await tester.pumpAndSettle();

    final collapsed = tester.widget<Text>(
      find.descendant(
        of: find.byType(SessionQuestion),
        matching: find.textContaining('xxx'),
      ),
    );
    expect(collapsed.maxLines, 3);
    expect(find.text('Show more'), findsOneWidget);

    await tester.tap(find.text('Show more'));
    await tester.pumpAndSettle();

    final expanded = tester.widget<Text>(
      find.descendant(
        of: find.byType(SessionQuestion),
        matching: find.textContaining('xxx'),
      ),
    );
    expect(expanded.maxLines, isNull);
    expect(find.text('Show less'), findsOneWidget);
  });

  testWidgets('a short question shows no toggle', (tester) async {
    late ChatController controller;
    await tester.pumpWidget(
      MaterialApp(
        home: GptChat(
          config: testConfig,
          chatRepository: FakeChatRepository(deltas: ['a']),
          showModelSelector: false,
          onControllerReady: (value) => controller = value,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await controller.onSend('short question');
    await tester.pumpAndSettle();

    expect(find.text('Show more'), findsNothing);
    // Scoped: the session title in the drawer is derived from the prompt, so
    // an unscoped finder matches twice.
    expect(
      find.descendant(
        of: find.byType(SessionQuestion),
        matching: find.text('short question'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('showModelSelector false drops the pill', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GptChat(
          config: testConfig,
          chatRepository: FakeChatRepository(),
          showModelSelector: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SessionModelSelector), findsNothing);
    expect(find.byType(SessionSendButton), findsOneWidget);
  });
}
