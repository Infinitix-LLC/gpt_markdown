import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_markdown/gen_ui/gen_ui_markers.dart';
import 'package:gpt_markdown/gpt_chat/gpt_chat.dart';

import 'fakes.dart';

const _tag =
    'Here is the animation.\n\n'
    '$genUiOpenMarker'
    '{"type":"val_artifact","id":"a1","name":"Seed Germination",'
    '"frame":"square","status":"queued","token":"tok"}'
    '$genUiCloseMarker';

ChatMessage reply(String content) =>
    ChatMessage(id: 'm1', role: ChatRole.assistant, content: content, createdAt: DateTime(2024));

void main() {
  /// A pending artifact spins forever, so frames are pumped one at a time.
  Future<FakeArtifactService> pumpCard(WidgetTester tester, {ValArtifactBuilder? builder}) async {
    final service = FakeArtifactService();
    await tester.pumpWidget(
      scopedChat(
        child: ChatBubble(message: reply(_tag)),
        artifactService: service,
        artifactBuilder: builder,
      ),
    );
    await tester.pump();
    await tester.pump();
    return service;
  }

  testWidgets('a genui tag in the reply becomes an artifact card', (tester) async {
    final service = await pumpCard(tester);

    expect(find.byType(ValArtifactCard), findsOneWidget);
    expect(find.text('Seed Germination'), findsOneWidget);
    expect(find.text('Queued'), findsOneWidget);
    expect(service.watched, ['a1'], reason: 'the card registers the artifact it renders');
  });

  testWidgets('status updates follow the artifact stream', (tester) async {
    final service = await pumpCard(tester);

    service.emit('a1', const ValArtifact(id: 'a1', name: '', status: ArtifactStatus.narrating));
    await tester.pump();

    expect(find.text('Recording narration'), findsOneWidget);
  });

  testWidgets('a ready artifact shows the narration and the VAL source', (tester) async {
    final service = await pumpCard(tester);

    service.emit(
      'a1',
      const ValArtifact(
        id: 'a1',
        name: '',
        status: ArtifactStatus.ready,
        script: 'scene { seed }',
        narrations: [Narration(text: 'A seed sprouts.')],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('A seed sprouts.'), findsOneWidget);
    expect(find.text('VAL script'), findsOneWidget);
  });

  testWidgets('a custom builder replaces the default ready view', (tester) async {
    final service = await pumpCard(
      tester,
      builder: (context, artifact) => Text('rendered ${artifact.id}'),
    );

    service.emit('a1', const ValArtifact(id: 'a1', name: '', status: ArtifactStatus.ready));
    await tester.pumpAndSettle();

    expect(find.text('rendered a1'), findsOneWidget);
    expect(find.text('VAL script'), findsNothing);
  });
}
