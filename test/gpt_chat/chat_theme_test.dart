import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_markdown/gpt_chat_gateway.dart';

import 'fakes.dart';

void main() {
  Future<ChatController> pump(
    WidgetTester tester, {
    ChatTheme? theme,
    ChatBuilders builders = const ChatBuilders(),
  }) async {
    late ChatController controller;
    await tester.pumpWidget(
      MaterialApp(
        home: GptChat(
          adapter: FakeAdapter(deltas: ['reply']),
          theme: theme,
          builders: builders,
          onControllerReady: (value) => controller = value,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  ListView transcriptList(WidgetTester tester) => tester.widget<ListView>(
    find
        .descendant(
          of: find.byType(ChatTranscript),
          matching: find.byType(ListView),
        )
        .first,
  );

  testWidgets('scrollPhysics reaches the transcript', (tester) async {
    final controller = await pump(
      tester,
      theme: const ChatTheme(scrollPhysics: NeverScrollableScrollPhysics()),
    );
    await controller.onSend('q');
    await tester.pumpAndSettle();

    expect(transcriptList(tester).physics, isA<NeverScrollableScrollPhysics>());
  });

  testWidgets('no scrollPhysics leaves the platform default', (tester) async {
    final controller = await pump(tester);
    await controller.onSend('q');
    await tester.pumpAndSettle();

    expect(transcriptList(tester).physics, isNull);
  });

  testWidgets('transcriptPadding insets the scrollable, not its content', (
    tester,
  ) async {
    const inset = EdgeInsets.only(bottom: 40);
    final controller = await pump(
      tester,
      theme: const ChatTheme(transcriptPadding: inset),
    );
    await controller.onSend('q');
    await tester.pumpAndSettle();

    // Outside the ListView: it must shrink the viewport rather than scroll away.
    final padding = tester.widget<Padding>(
      find
          .ancestor(
            of: find.byType(ListView).first,
            matching: find.byType(Padding),
          )
          .first,
    );
    expect(padding.padding, inset);
  });

  testWidgets('the anchor is measured after the transcript inset', (
    tester,
  ) async {
    // Measuring before padding would make the last exchange taller than the
    // space it actually gets, by exactly the inset.
    late double padded;
    late double unpadded;

    Future<double> anchorWith(EdgeInsets inset) async {
      late double seen;
      final controller = await pump(
        tester,
        theme: ChatTheme(transcriptPadding: inset),
        builders: ChatBuilders(
          messageList: (s) {
            seen = s.anchorHeight;
            return s.child;
          },
        ),
      );
      await controller.onSend('q');
      await tester.pumpAndSettle();
      return seen;
    }

    unpadded = await anchorWith(EdgeInsets.zero);
    padded = await anchorWith(const EdgeInsets.only(bottom: 40));

    expect(padded, unpadded - 40);
  });

  testWidgets('the list header is constrained to the reading column', (
    tester,
  ) async {
    final controller = await pump(
      tester,
      theme: const ChatTheme(contentMaxWidth: 400),
      builders: ChatBuilders(
        listHeader:
            (s) => const SizedBox(
              key: Key('header'),
              width: double.infinity,
              height: 10,
            ),
      ),
    );
    await controller.onSend('q');
    await tester.pumpAndSettle();

    // A header that had to re-wrap itself would be wider than the column.
    expect(tester.getSize(find.byKey(const Key('header'))).width, 400);
  });
}
