import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_markdown/gpt_chat_gateway.dart';

import 'fakes.dart';

void main() {
  testWidgets('a widget directive in a reply is rendered', (tester) async {
    final directive = wrapGenUi(
      '{"bar_chart":{"title":"Study hours","values":[2,4,1,5]}}',
    );

    await tester.pumpWidget(
      scopedChat(child: ChatAnswer(message: reply('Here you go.\n\n$directive'))),
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
      scopedChat(child: ChatAnswer(message: reply(directive)), genUi: registry),
    );
    await tester.pumpAndSettle();

    expect(find.text('MY 3D'), findsOneWidget);
  });

  testWidgets('an unregistered type renders nothing, not an error', (tester) async {
    final directive = wrapGenUi('{"video":{"url":"https://x.dev/v.mp4"}}');

    await tester.pumpWidget(
      scopedChat(child: ChatAnswer(message: reply('Text stays.\n\n$directive'))),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Text stays.', findRichText: true), findsOneWidget);
  });

  testWidgets('an animation directive becomes an artifact card', (tester) async {
    final service = FakeArtifactService();
    final directive = wrapGenUi(
      '{"val_scene":{"id":"a1","name":"Seed","status":"queued","token":"tok"}}',
    );

    await tester.pumpWidget(
      scopedChat(child: ChatAnswer(message: reply(directive)), artifactService: service),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(ValArtifactCard), findsOneWidget);
    expect(service.watched, ['a1']);
  });

  testWidgets('the pre-2026-08 flat animation payload still renders', (tester) async {
    // Persisted sessions still hold them, and a stored reply that stops
    // rendering is indistinguishable from a bug in the answer itself.
    final service = FakeArtifactService();
    final directive = wrapGenUi(
      '{"type":"val_artifact","id":"a1","name":"Seed","status":"queued","token":"tok"}',
    );

    await tester.pumpWidget(
      scopedChat(child: ChatAnswer(message: reply(directive)), artifactService: service),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(ValArtifactCard), findsOneWidget);
    expect(service.watched, ['a1']);
  });

  testWidgets('an animation and a chart in one payload both render', (tester) async {
    // Only possible because val_scene goes through the registry like any other
    // widget. Special-casing the animation in the bubble rendered the card and
    // silently dropped the chart beside it.
    final service = FakeArtifactService();
    final directive = wrapGenUi(
      '{"val_scene":{"id":"a1","name":"Seed","status":"queued","token":"tok"},'
      '"bar_chart":{"title":"Rainfall","values":[1,2]}}',
    );

    await tester.pumpWidget(
      scopedChat(child: ChatAnswer(message: reply(directive)), artifactService: service),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(ValArtifactCard), findsOneWidget);
    expect(find.byType(GenBarChart), findsOneWidget);
  });

  testWidgets('a host keeps its own val_scene builder', (tester) async {
    final registry = GenUiRegistry.defaults()
      ..register('val_scene', (context, model) => const Text('MY ANIMATION'));

    await tester.pumpWidget(
      scopedChat(
        child: ChatAnswer(message: reply(wrapGenUi('{"val_scene":{"id":"a1"}}'))),
        genUi: registry,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('MY ANIMATION'), findsOneWidget);
    expect(find.byType(ValArtifactCard), findsNothing);
  });

  testWidgets('an unrenderable widget shows a notice instead of a gap', (tester) async {
    // The gateway sends genui_error precisely when something else could not be
    // rendered, so it must never be the thing that is missing.
    final directive = wrapGenUi(
      '{"genui_error":{"widget":"bar_chart","message":"This widget could not be rendered."}}',
    );

    await tester.pumpWidget(
      scopedChat(child: ChatAnswer(message: reply('As shown:\n\n$directive'))),
    );
    await tester.pumpAndSettle();

    expect(find.text('This widget could not be rendered.'), findsOneWidget);
  });
}
