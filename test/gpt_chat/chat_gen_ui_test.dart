import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_markdown/gpt_chat/gpt_chat.dart';

import 'fakes.dart';

ChatMessage reply(String content) =>
    ChatMessage(id: 'm1', role: ChatRole.assistant, content: content, createdAt: DateTime(2024));

void main() {
  testWidgets('a widget directive in a reply is rendered', (tester) async {
    final directive = wrapGenUi(
      '{"bar_chart":{"title":"Study hours","values":[2,4,1,5]}}',
    );

    await tester.pumpWidget(
      scopedChat(child: ChatBubble(message: reply('Here you go.\n\n$directive'))),
    );
    await tester.pumpAndSettle();

    expect(find.byType(GenBarChart), findsOneWidget);
    expect(find.text('Study hours'), findsOneWidget);
  });

  testWidgets('an opt-in type falls through to the host registry', (tester) async {
    final registry = GenUiRegistry.defaults()
      ..register('surface_3d', (context, model) => const Text('MY 3D'));
    final directive = wrapGenUi('{"surface_3d":{"z":"sin(x)"}}');

    await tester.pumpWidget(
      scopedChat(child: ChatBubble(message: reply(directive)), genUi: registry),
    );
    await tester.pumpAndSettle();

    expect(find.text('MY 3D'), findsOneWidget);
  });

  testWidgets('an unregistered type renders nothing, not an error', (tester) async {
    final directive = wrapGenUi('{"video":{"url":"https://x.dev/v.mp4"}}');

    await tester.pumpWidget(
      scopedChat(child: ChatBubble(message: reply('Text stays.\n\n$directive'))),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Text stays.', findRichText: true), findsOneWidget);
  });

  testWidgets('an animation directive still becomes an artifact card', (tester) async {
    final service = FakeArtifactService();
    final directive = wrapGenUi(
      '{"type":"val_artifact","id":"a1","name":"Seed","status":"queued","token":"tok"}',
    );

    await tester.pumpWidget(
      scopedChat(child: ChatBubble(message: reply(directive)), artifactService: service),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(ValArtifactCard), findsOneWidget);
    expect(service.watched, ['a1']);
  });
}
