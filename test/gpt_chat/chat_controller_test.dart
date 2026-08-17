import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_markdown/gpt_chat_gateway.dart';

import 'fakes.dart';

SimpleChatMessage _message(String id, ChatRole role, String content) =>
    SimpleChatMessage(
      id: id,
      role: role,
      content: content,
      createdAt: DateTime(2024),
    );

void main() {
  group('ChatMessagePair', () {
    test('groups each question with the reply that follows it', () {
      final pairs = ChatMessagePair.fromMessages([
        _message('1', ChatRole.user, 'q1'),
        _message('2', ChatRole.assistant, 'a1'),
        _message('3', ChatRole.user, 'q2'),
        _message('4', ChatRole.assistant, 'a2'),
      ]);

      expect(pairs, hasLength(2));
      expect(pairs[0].question.content, 'q1');
      expect(pairs[0].answer?.content, 'a1');
      expect(pairs[1].question.content, 'q2');
      expect(pairs[1].answer?.content, 'a2');
    });

    test('keeps a question that has no reply yet', () {
      // Index-based pairing drops this one, so the question a user just sent
      // would not appear until the reply object existed.
      final pairs = ChatMessagePair.fromMessages([
        _message('1', ChatRole.user, 'q1'),
        _message('2', ChatRole.assistant, 'a1'),
        _message('3', ChatRole.user, 'q2'),
      ]);

      expect(pairs, hasLength(2));
      expect(pairs.last.question.content, 'q2');
      expect(pairs.last.answer, isNull);
      expect(pairs.last.isAwaitingAnswer, isTrue);
    });

    test('consecutive questions do not shift later pairs', () {
      final pairs = ChatMessagePair.fromMessages([
        _message('1', ChatRole.user, 'q1'),
        _message('2', ChatRole.user, 'q2'),
        _message('3', ChatRole.assistant, 'a2'),
      ]);

      expect(pairs, hasLength(2));
      expect(pairs[0].answer, isNull);
      expect(pairs[1].question.content, 'q2');
      expect(pairs[1].answer?.content, 'a2');
    });

    test('an assistant message with no question still renders', () {
      final pairs = ChatMessagePair.fromMessages([
        _message('1', ChatRole.assistant, 'greeting'),
      ]);

      expect(pairs, hasLength(1));
      expect(pairs.single.question.content, 'greeting');
    });

    test('system messages are context, not conversation', () {
      final pairs = ChatMessagePair.fromMessages([
        _message('0', ChatRole.system, 'you are helpful'),
        _message('1', ChatRole.user, 'q1'),
        _message('2', ChatRole.assistant, 'a1'),
      ]);

      expect(pairs, hasLength(1));
      expect(pairs.single.question.content, 'q1');
    });

    test('an empty transcript yields no pairs', () {
      expect(ChatMessagePair.fromMessages(const []), isEmpty);
    });
  });

  group('ChatController', () {
    Future<ChatController> pump(
      WidgetTester tester, {
      required ChatAdapter adapter,
      ChatModelSource? models,
    }) async {
      late ChatController controller;
      await tester.pumpWidget(
        MaterialApp(
          home: GptChat(
            adapter: adapter,
            models: models,
            onControllerReady: (value) => controller = value,
          ),
        ),
      );
      await tester.pumpAndSettle();
      return controller;
    }

    testWidgets('onSend clears the composer and appends the exchange', (
      tester,
    ) async {
      final controller = await pump(
        tester,
        adapter: FakeAdapter(deltas: ['hi']),
      );

      controller.input.text = 'question';
      await controller.onSend();
      await tester.pumpAndSettle();

      expect(controller.input.text, isEmpty);
      expect(controller.pairs, hasLength(1));
      expect(controller.pairs.single.question.content, 'question');
      expect(controller.pairs.single.answer?.content, 'hi');
    });

    testWidgets('canSend follows the composer and the in-flight reply', (
      tester,
    ) async {
      final adapter = ManualAdapter();
      final controller = await pump(tester, adapter: adapter);

      expect(controller.canSend, isFalse, reason: 'empty composer');

      controller.input.text = 'question';
      expect(controller.canSend, isTrue);

      await controller.onSend();
      await tester.pump();
      expect(controller.isResponding, isTrue);

      controller.input.text = 'another';
      expect(controller.canSend, isFalse, reason: 'a reply is in flight');

      adapter.finish();
      await tester.pumpAndSettle();
    });

    testWidgets('a staged attachment alone makes the draft sendable', (
      tester,
    ) async {
      final controller = await pump(tester, adapter: FakeAdapter());

      expect(controller.canSend, isFalse);
      controller.addAttachment(
        const ChatAttachment(id: 'a1', kind: ChatAttachmentKind.image),
      );
      await tester.pump();

      expect(controller.canSend, isTrue);
      expect(controller.draft.attachments, hasLength(1));

      controller.removeAttachment('a1');
      await tester.pump();
      expect(controller.canSend, isFalse);
    });

    testWidgets('sending clears the staged attachments', (tester) async {
      final controller = await pump(
        tester,
        adapter: FakeAdapter(deltas: ['ok']),
      );

      controller.addAttachment(
        const ChatAttachment(id: 'a1', kind: ChatAttachmentKind.file),
      );
      await controller.onSend('question');
      await tester.pumpAndSettle();

      expect(controller.attachments, isEmpty);
    });

    testWidgets('onModelChoose reaches the model source', (tester) async {
      final models = FakeModelSource();
      final controller = await pump(
        tester,
        adapter: FakeAdapter(),
        models: models,
      );

      controller.onModelChoose('gemini-3.6-flash');
      await tester.pump();

      expect(models.chosen, 'gemini-3.6-flash');
      expect(controller.selectedModel, 'gemini-3.6-flash');
    });

    testWidgets('onStop ends the reply and keeps the partial text', (
      tester,
    ) async {
      final adapter = ManualAdapter();
      final controller = await pump(tester, adapter: adapter);

      await controller.onSend('question');
      adapter.emit('partial');
      await tester.pump();

      // Fire-and-forget, as a button press would: awaiting it here would block
      // on work that only completes once frames are pumped.
      unawaited(controller.onStop());
      await tester.pumpAndSettle();

      expect(controller.isResponding, isFalse);
      expect(controller.pairs.single.answer?.content, 'partial');
    });

    testWidgets('onClearError dismisses the failure', (tester) async {
      final controller = await pump(
        tester,
        adapter: FakeAdapter(error: const ChatException('no credit')),
      );

      await controller.onSend('question');
      await tester.pumpAndSettle();
      expect(controller.error, 'no credit');

      controller.onClearError();
      await tester.pump();
      expect(controller.error, isNull);
    });

    testWidgets('prefill puts text in the composer', (tester) async {
      final controller = await pump(tester, adapter: FakeAdapter());

      controller.prefill('suggested question');
      await tester.pump();

      expect(controller.input.text, 'suggested question');
      expect(controller.canSend, isTrue);
    });
  });
}
