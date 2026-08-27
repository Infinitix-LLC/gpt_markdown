import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_markdown/gpt_chat_gateway.dart';

import 'fakes.dart';

const _tag =
    'Here is the animation.\n\n'
    '$genUiOpenMarker'
    '{"type":"val_artifact","id":"a1","name":"Seed Germination",'
    '"frame":"square","status":"queued","token":"tok"}'
    '$genUiCloseMarker';

void main() {
  /// A pending artifact spins forever, so frames are pumped one at a time.
  Future<FakeArtifactService> pumpCard(
    WidgetTester tester, {
    ValArtifactBuilder? builder,
  }) async {
    final service = FakeArtifactService();
    await tester.pumpWidget(
      scopedChat(
        child: ChatAnswer(message: reply(_tag)),
        artifactService: service,
        artifactBuilder: builder,
      ),
    );
    await tester.pump();
    await tester.pump();
    return service;
  }

  testWidgets('a genui tag in the reply becomes an artifact card', (
    tester,
  ) async {
    final service = await pumpCard(tester);

    expect(find.byType(ValArtifactCard), findsOneWidget);
    expect(find.text('Seed Germination'), findsOneWidget);
    expect(find.text('Queued'), findsOneWidget);
    expect(service.watched, [
      'a1',
    ], reason: 'the card registers the artifact it renders');
  });

  testWidgets('status updates follow the artifact stream', (tester) async {
    final service = await pumpCard(tester);

    service.emit(
      'a1',
      const ValArtifact(id: 'a1', name: '', status: ArtifactStatus.narrating),
    );
    await tester.pump();

    expect(find.text('Recording narration'), findsOneWidget);
  });

  testWidgets('a ready artifact offers to play, captioned by its narration', (
    tester,
  ) async {
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

    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    // The narration says what the scene is about, which is a better caption
    // than the word "Animation".
    expect(find.text('A seed sprouts.'), findsOneWidget);
  });

  testWidgets('a ready artifact with no narration still invites a play', (
    tester,
  ) async {
    final service = await pumpCard(tester);

    service.emit(
      'a1',
      const ValArtifact(id: 'a1', name: '', status: ArtifactStatus.ready),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tap to play'), findsOneWidget);
  });

  testWidgets('tapping the poster opens the player', (tester) async {
    final service = await pumpCard(tester);

    service.emit(
      'a1',
      const ValArtifact(
        id: 'a1',
        name: 'Bouncing ball',
        status: ArtifactStatus.ready,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // The sheet is up and titled by the artifact. Playback itself needs the
    // render endpoint, so this stops at the seam rather than reaching for it.
    expect(find.byType(ValSceneSheet), findsOneWidget);
    expect(find.text('Bouncing ball'), findsWidgets);

    // Leaves nothing running behind it.
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(ValSceneSheet), findsNothing);
  });

  testWidgets('a custom builder replaces the default ready view', (
    tester,
  ) async {
    final service = await pumpCard(
      tester,
      builder: (context, artifact) => Text('rendered ${artifact.id}'),
    );

    service.emit(
      'a1',
      const ValArtifact(id: 'a1', name: '', status: ArtifactStatus.ready),
    );
    await tester.pumpAndSettle();

    expect(find.text('rendered a1'), findsOneWidget);
    expect(find.text('VAL script'), findsNothing);
  });
}
