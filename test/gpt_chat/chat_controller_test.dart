import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_markdown/gpt_chat/gpt_chat.dart';

import 'fakes.dart';

ChatMessage _message(String id, ChatRole role, String content) => ChatMessage(
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

      expect(pairs, hasLength(3 - 1));
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

    test('an empty transcript yields no pairs', () {
      expect(ChatMessagePair.fromMessages(const []), isEmpty);
    });
  });

  group('ChatController', () {
    testWidgets('onSend clears the composer and appends the exchange', (
      tester,
    ) async {
      late ChatController controller;
      await tester.pumpWidget(
        MaterialApp(
          home: GptChat(
            config: testConfig,
            chatRepository: FakeChatRepository(deltas: ['hi']),
            showModelSelector: false,
            onControllerReady: (value) => controller = value,
          ),
        ),
      );
      await tester.pumpAndSettle();

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
      late ChatController controller;
      final repository = ManualChatRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: GptChat(
            config: testConfig,
            chatRepository: repository,
            showModelSelector: false,
            onControllerReady: (value) => controller = value,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(controller.canSend, isFalse, reason: 'empty composer');

      controller.input.text = 'question';
      expect(controller.canSend, isTrue);

      await controller.onSend();
      await tester.pump();
      expect(controller.isResponding, isTrue);

      controller.input.text = 'another';
      expect(controller.canSend, isFalse, reason: 'a reply is in flight');

      repository.finish();
      await tester.pumpAndSettle();
    });

    testWidgets('onModelChoose reaches the repository', (tester) async {
      late ChatController controller;
      final repository = FakeChatRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: GptChat(
            config: testConfig,
            chatRepository: repository,
            onControllerReady: (value) => controller = value,
          ),
        ),
      );
      await tester.pumpAndSettle();

      controller.onModelChoose('gemini-3.6-flash');
      await tester.pump();

      expect(repository.selectedModel, 'gemini-3.6-flash');
      expect(controller.selectedModel, 'gemini-3.6-flash');
    });

    testWidgets('onStop ends the reply and keeps the partial text', (
      tester,
    ) async {
      late ChatController controller;
      final repository = ManualChatRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: GptChat(
            config: testConfig,
            chatRepository: repository,
            showModelSelector: false,
            onControllerReady: (value) => controller = value,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await controller.onSend('question');
      repository.emit('partial');
      await tester.pump();

      // Fire-and-forget, as a button press would: awaiting it here would block
      // on work that only completes once frames are pumped.
      unawaited(controller.onStop());
      await tester.pumpAndSettle();

      expect(controller.isResponding, isFalse);
      expect(controller.pairs.single.answer?.content, 'partial');
    });

    testWidgets('onClearError dismisses the failure', (tester) async {
      late ChatController controller;
      await tester.pumpWidget(
        MaterialApp(
          home: GptChat(
            config: testConfig,
            chatRepository: FakeChatRepository(
              error: const ChatException('no credit'),
            ),
            showModelSelector: false,
            onControllerReady: (value) => controller = value,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await controller.onSend('question');
      await tester.pumpAndSettle();
      expect(controller.error, 'no credit');

      controller.onClearError();
      await tester.pump();
      expect(controller.error, isNull);
    });
  });
}
