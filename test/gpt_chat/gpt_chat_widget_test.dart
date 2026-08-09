import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_markdown/gpt_chat/gpt_chat.dart';

import 'fakes.dart';

void main() {
  Future<void> pumpChat(WidgetTester tester, ChatRepository repository) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GptChat(config: testConfig, chatRepository: repository, showModelSelector: false),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the empty state before the first message', (tester) async {
    await pumpChat(tester, FakeChatRepository());

    expect(find.text('Ask anything'), findsOneWidget);
  });

  testWidgets('sending renders both the prompt and the reply', (tester) async {
    await pumpChat(tester, FakeChatRepository(deltas: ['Hi there']));

    await tester.enterText(find.byType(TextField), 'hello');
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: find.byType(ChatBubble), matching: find.text('hello')),
      findsOneWidget,
    );
    expect(find.textContaining('Hi there', findRichText: true), findsOneWidget);
  });

  testWidgets('the composer clears after sending', (tester) async {
    await pumpChat(tester, FakeChatRepository());

    await tester.enterText(find.byType(TextField), 'hello');
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();

    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);
  });

  testWidgets('a failure shows the error bar', (tester) async {
    await pumpChat(tester, FakeChatRepository(error: const ChatException('no credit')));

    await tester.enterText(find.byType(TextField), 'hello');
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();

    expect(find.text('no credit'), findsWidgets);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('the drawer lists sessions', (tester) async {
    await pumpChat(tester, FakeChatRepository());

    await tester.enterText(find.byType(TextField), 'hello');
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();

    expect(find.text('New chat'), findsOneWidget);
    expect(find.text('hello'), findsWidgets);
  });

  testWidgets('picking a model tells the repository', (tester) async {
    final repository = FakeChatRepository();
    await tester.pumpWidget(
      MaterialApp(home: GptChat(config: testConfig, chatRepository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ModelSelector));
    await tester.pumpAndSettle();
    await tester.tap(find.text(testConfig.model).last);
    await tester.pumpAndSettle();

    expect(find.byType(ModelSelector), findsOneWidget);
    expect(repository.selectedModel, isNull, reason: 'reselecting the same model is a no-op');
  });
}
