import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_markdown/gpt_chat_gateway.dart';

import 'fakes.dart';

/// A reply long enough that the transcript actually overflows its viewport.
String get _longReply =>
    List.generate(60, (i) => 'Line $i of the reply.').join('\n\n');

void main() {
  Future<ChatController> pumpChat(
    WidgetTester tester, {
    ChatBuilders builders = const ChatBuilders(),
    ChatAdapter? adapter,
    ChatTheme? theme,
  }) async {
    late ChatController controller;
    await tester.pumpWidget(
      MaterialApp(
        home: GptChat(
          adapter: adapter ?? FakeAdapter(),
          builders: builders,
          theme: theme,
          onControllerReady: (value) => controller = value,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  group('replacing', () {
    testWidgets('scaffold replaces the whole screen', (tester) async {
      await pumpChat(
        tester,
        builders: ChatBuilders(
          scaffold:
              (s) => const Scaffold(body: Center(child: Text('my whole ui'))),
        ),
      );

      expect(find.text('my whole ui'), findsOneWidget);
      expect(find.byType(ChatComposer), findsNothing);
    });

    testWidgets('empty, appBar and composer are each replaceable', (
      tester,
    ) async {
      await pumpChat(
        tester,
        builders: ChatBuilders(
          empty: (s) => const Center(child: Text('nothing yet')),
          appBar:
              (s) => const SizedBox(
                height: 72,
                child: Center(child: Text('my bar')),
              ),
          composer:
              (s) => const SizedBox(
                height: 60,
                child: Center(child: Text('my composer')),
              ),
        ),
      );

      expect(find.text('nothing yet'), findsOneWidget);
      expect(find.text('my bar'), findsOneWidget);
      expect(find.text('my composer'), findsOneWidget);
      // The host widget stays — it is what applies the builder — but nothing
      // it would have drawn by default survives.
      expect(find.byTooltip('New chat'), findsNothing);
      expect(find.byType(ChatComposerField), findsNothing);
    });

    testWidgets('question and answer builders receive the messages', (
      tester,
    ) async {
      final controller = await pumpChat(
        tester,
        adapter: FakeAdapter(deltas: ['the answer']),
        builders: ChatBuilders(
          question: (s) => Text('Q<${s.message.content}>'),
          answer: (s) => Text('A<${s.message.content}> last=${s.isLast}'),
        ),
      );

      await controller.onSend('the question');
      await tester.pumpAndSettle();

      expect(find.text('Q<the question>'), findsOneWidget);
      expect(find.text('A<the answer> last=true'), findsOneWidget);
      expect(find.byType(ChatQuestionText), findsNothing);
    });

    testWidgets('a custom pair builder owns the whole exchange', (
      tester,
    ) async {
      final controller = await pumpChat(
        tester,
        adapter: FakeAdapter(deltas: ['a']),
        builders: ChatBuilders(
          pair:
              (s) =>
                  Text('pair ${s.index} awaiting=${s.pair.isAwaitingAnswer}'),
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
        adapter: FakeAdapter(error: const ChatException('nope')),
        builders: ChatBuilders(
          errorBar:
              (s) => TextButton(
                onPressed: s.controller.onClearError,
                child: Text('err: ${s.message}'),
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
        adapter: FakeAdapter(deltas: ['ok']),
        builders: ChatBuilders(
          composerSend:
              (s) => IconButton(
                icon: const Icon(Icons.rocket_launch),
                onPressed: s.controller.onSend,
              ),
        ),
      );

      controller.input.text = 'via custom button';
      await tester.pump();
      await tester.tap(find.byIcon(Icons.rocket_launch));
      await tester.pumpAndSettle();

      expect(controller.pairs.single.question.content, 'via custom button');
    });
  });

  group('decorating — the parts come with the slot', () {
    testWidgets('a slot can wrap the default instead of replacing it', (
      tester,
    ) async {
      final controller = await pumpChat(
        tester,
        adapter: FakeAdapter(deltas: ['body text']),
        builders: ChatBuilders(
          answerText:
              (s) => Column(children: [const Text('decorated'), s.child]),
        ),
      );

      await controller.onSend('q');
      await tester.pumpAndSettle();

      expect(find.text('decorated'), findsOneWidget);
      expect(
        find.textContaining('body text', findRichText: true),
        findsOneWidget,
        reason: 'the default answer text is still rendered',
      );
    });

    testWidgets('a custom answer keeps the package-built parts', (
      tester,
    ) async {
      final controller = await pumpChat(
        tester,
        adapter: FakeAdapter(deltas: ['body text']),
        builders: ChatBuilders(
          answer:
              (s) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...s.above,
                  s.text,
                  const Text('my footer'),
                  s.actions,
                ],
              ),
          answerAbove: [(s) => const Text('my sources')],
        ),
      );

      await controller.onSend('q');
      await tester.pumpAndSettle();

      expect(find.text('my sources'), findsOneWidget);
      expect(find.text('my footer'), findsOneWidget);
      expect(
        find.textContaining('body text', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('a custom transcript keeps the package-built exchanges', (
      tester,
    ) async {
      final controller = await pumpChat(
        tester,
        adapter: FakeAdapter(deltas: ['reply text']),
        builders: ChatBuilders(
          messageList:
              (s) => ListView.builder(
                controller: s.scrollController,
                itemCount: s.count,
                itemBuilder: (context, index) => s.item(index),
              ),
        ),
      );

      await controller.onSend('the question');
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(ChatQuestion),
          matching: find.text('the question'),
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('reply text', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('a custom scaffold keeps the package-built regions', (
      tester,
    ) async {
      await pumpChat(
        tester,
        builders: ChatBuilders(
          scaffold:
              (s) => Scaffold(
                body: Column(
                  children: [
                    const Text('my shell'),
                    Expanded(child: s.body),
                    s.composer,
                  ],
                ),
              ),
        ),
      );

      expect(find.text('my shell'), findsOneWidget);
      expect(find.byType(ChatComposerField), findsOneWidget);
      expect(find.byType(ChatEmptyState), findsOneWidget);
    });

    testWidgets('answerBelow sections append in order', (tester) async {
      final controller = await pumpChat(
        tester,
        adapter: FakeAdapter(deltas: ['text']),
        builders: ChatBuilders(
          answerBelow: [
            (s) => const Text('first section'),
            (s) => const Text('second section'),
          ],
        ),
      );

      await controller.onSend('q');
      await tester.pumpAndSettle();

      expect(find.text('first section'), findsOneWidget);
      expect(find.text('second section'), findsOneWidget);
    });
  });

  group('awaiting the first token', _awaitingAnswerTests);

  group('theme', () {
    testWidgets('capabilities decide the chrome, not the call site', (
      tester,
    ) async {
      await pumpChat(tester, adapter: _MinimalAdapter());

      expect(find.byType(ChatModelPicker), findsNothing);
      expect(find.byTooltip('New chat'), findsNothing);
      expect(find.byTooltip('Conversations'), findsNothing);
    });

    testWidgets('showQuestionBubble false drops the bubble', (tester) async {
      final controller = await pumpChat(
        tester,
        adapter: FakeAdapter(deltas: ['a']),
        theme: const ChatTheme(showQuestionBubble: false),
      );

      await controller.onSend('q');
      await tester.pumpAndSettle();

      expect(find.byType(FractionallySizedBox), findsNothing);
    });

    testWidgets('a long question collapses behind a Show more toggle', (
      tester,
    ) async {
      final controller = await pumpChat(
        tester,
        adapter: FakeAdapter(deltas: ['a']),
      );

      await controller.onSend('x' * 400);
      await tester.pumpAndSettle();

      final collapsed = tester.widget<Text>(
        find.descendant(
          of: find.byType(ChatQuestionText),
          matching: find.textContaining('xxx'),
        ),
      );
      expect(collapsed.maxLines, 3);
      expect(find.text('Show more'), findsOneWidget);

      await tester.tap(find.text('Show more'));
      await tester.pumpAndSettle();

      final expanded = tester.widget<Text>(
        find.descendant(
          of: find.byType(ChatQuestionText),
          matching: find.textContaining('xxx'),
        ),
      );
      expect(expanded.maxLines, isNull);
      expect(find.text('Show less'), findsOneWidget);
    });

    testWidgets('questionCollapseThreshold zero disables collapsing', (
      tester,
    ) async {
      final controller = await pumpChat(
        tester,
        adapter: FakeAdapter(deltas: ['a']),
        theme: const ChatTheme(questionCollapseThreshold: 0),
      );

      await controller.onSend('x' * 400);
      await tester.pumpAndSettle();

      expect(find.text('Show more'), findsNothing);
    });
  });

  group('merge', () {
    test('layers the other bundle on top', () {
      Widget a(ChatSlot slot) => const SizedBox.shrink();
      Widget b(ChatSlot slot) => const SizedBox.shrink();

      final base = ChatBuilders(background: a, composerField: a);
      final merged = base.merge(ChatBuilders(composerField: b));

      expect(merged.background, same(a), reason: 'not overridden');
      expect(merged.composerField, same(b), reason: 'overridden');
    });
  });

  group('transcript scrolling', () {
    testWidgets('a user scroll away from the bottom stops following', (
      tester,
    ) async {
      final controller = await pumpChat(
        tester,
        adapter: FakeAdapter(deltas: [_longReply]),
      );

      await controller.onSend('q');
      await tester.pumpAndSettle();

      expect(controller.isFollowingLatest, isTrue);
      expect(controller.canJumpToLatest, isFalse);

      // Drag the transcript downwards, i.e. back towards older content.
      await tester.drag(find.byType(ChatTranscript), const Offset(0, 600));
      await tester.pumpAndSettle();

      expect(controller.isFollowingLatest, isFalse);
      expect(controller.canJumpToLatest, isTrue);
    });

    testWidgets('jumping to latest resumes following', (tester) async {
      final controller = await pumpChat(
        tester,
        adapter: FakeAdapter(deltas: [_longReply]),
      );

      await controller.onSend('q');
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ChatTranscript), const Offset(0, 600));
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
      final adapter = ManualAdapter();
      final controller = await pumpChat(tester, adapter: adapter);

      await controller.onSend('q');
      adapter.emit(_longReply);
      await tester.pump();

      // Markdown content nests its own scrollables, so target the transcript's
      // own list rather than any Scrollable in the subtree.
      final list = tester.widget<ListView>(
        find
            .descendant(
              of: find.byType(ChatTranscript),
              matching: find.byType(ListView),
            )
            .first,
      );
      expect(
        list.physics,
        isNot(isA<NeverScrollableScrollPhysics>()),
        reason: 'the user must keep control of the transcript mid-stream',
      );

      adapter.finish();
      await tester.pumpAndSettle();
    });
  });
}

/// Everything off but sending.
class _MinimalAdapter extends StreamingChatAdapter {
  @override
  ChatCapabilities get capabilities => ChatCapabilities.minimal;

  @override
  Stream<ChatDelta> streamReply(List<ChatMessage> history) =>
      Stream.value(const ChatDelta('ok'));
}

/// Regression: the answer slot must run from the moment a question is sent.
///
/// A host that replaces `answer` draws its own header, status line and progress
/// there. Short-circuiting to the typing indicator before consulting the
/// builder left all of that off screen until the first token arrived.
void _awaitingAnswerTests() {
  testWidgets('the answer builder runs before the first token', (tester) async {
    final adapter = ManualAdapter();
    late ChatController controller;
    await tester.pumpWidget(
      MaterialApp(
        home: GptChat(
          adapter: adapter,
          builders: ChatBuilders(
            answer:
                (s) =>
                    Column(children: [const Text('my answer header'), s.text]),
          ),
          onControllerReady: (value) => controller = value,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await controller.onSend('q');
    await tester.pump();

    expect(
      find.text('my answer header'),
      findsOneWidget,
      reason: 'the host header belongs on screen from the send',
    );
    expect(find.byType(ChatTypingDots), findsOneWidget);

    adapter.emit('the reply');
    await tester.pump();

    expect(find.text('my answer header'), findsOneWidget);
    expect(find.byType(ChatTypingDots), findsNothing);

    adapter.finish();
    await tester.pumpAndSettle();
  });

  testWidgets('a suppressed typing indicator leaves nothing behind', (
    tester,
  ) async {
    final adapter = ManualAdapter();
    late ChatController controller;
    await tester.pumpWidget(
      MaterialApp(
        home: GptChat(
          adapter: adapter,
          builders: ChatBuilders(
            typingIndicator: (s) => const SizedBox.shrink(),
            answer: (s) => const Text('always here'),
          ),
          onControllerReady: (value) => controller = value,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await controller.onSend('q');
    await tester.pump();

    expect(find.byType(ChatTypingDots), findsNothing);
    expect(find.text('always here'), findsOneWidget);

    adapter.finish();
    await tester.pumpAndSettle();
  });

  testWidgets('the default still shows dots and no answer body', (
    tester,
  ) async {
    final adapter = ManualAdapter();
    late ChatController controller;
    await tester.pumpWidget(
      MaterialApp(
        home: GptChat(
          adapter: adapter,
          onControllerReady: (value) => controller = value,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await controller.onSend('q');
    await tester.pump();

    expect(find.byType(ChatTypingDots), findsOneWidget);
    expect(find.byType(ChatAnswerText), findsNothing);

    adapter.finish();
    await tester.pumpAndSettle();
  });
}
