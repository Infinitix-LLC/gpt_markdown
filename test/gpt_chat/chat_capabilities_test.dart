import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_markdown/gpt_chat_gateway.dart';

import 'fakes.dart';

/// Turns on the capabilities the defaults gate on.
class _FullAdapter extends FakeAdapter {
  @override
  ChatCapabilities get capabilities => const ChatCapabilities(
    attachments: true,
    suggestions: true,
    renameSessions: true,
    sessionPaging: true,
  );

  @override
  List<String> get suggestions => const ['Explain recursion', 'Draft an email'];
}

void main() {
  Future<ChatController> pump(
    WidgetTester tester, {
    ChatAdapter? adapter,
    ChatTheme? theme,
  }) async {
    late ChatController controller;
    await tester.pumpWidget(
      MaterialApp(
        home: GptChat(
          adapter: adapter ?? _FullAdapter(),
          theme: theme,
          onControllerReady: (value) => controller = value,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  group('suggestions', () {
    testWidgets('the empty state offers them and tapping one prefills', (
      tester,
    ) async {
      final controller = await pump(tester);

      expect(find.text('Explain recursion'), findsOneWidget);

      await tester.tap(find.text('Explain recursion'));
      await tester.pump();

      expect(controller.input.text, 'Explain recursion');
      expect(
        controller.isResponding,
        isFalse,
        reason: 'a suggestion prefills, it does not send',
      );
    });

    testWidgets('without the capability none are shown', (tester) async {
      await pump(tester, adapter: FakeAdapter());

      expect(find.byType(ActionChip), findsNothing);
    });
  });

  group('attachments', () {
    testWidgets('the staged strip appears only with the capability', (
      tester,
    ) async {
      final controller = await pump(tester);
      controller.addAttachment(
        const ChatAttachment(
          id: 'a1',
          kind: ChatAttachmentKind.file,
          name: 'notes.pdf',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ChatAttachmentTile), findsOneWidget);
    });

    testWidgets('without the capability the strip stays hidden', (
      tester,
    ) async {
      final controller = await pump(tester, adapter: FakeAdapter());
      controller.addAttachment(
        const ChatAttachment(id: 'a1', kind: ChatAttachmentKind.file),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ChatAttachmentTile), findsNothing);
    });

    testWidgets('a staged attachment can be removed from the strip', (
      tester,
    ) async {
      final controller = await pump(tester);
      controller.addAttachment(
        const ChatAttachment(id: 'a1', kind: ChatAttachmentKind.image),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(controller.attachments, isEmpty);
      expect(find.byType(ChatAttachmentTile), findsNothing);
    });
  });

  group('send and stop', () {
    testWidgets('stop takes the send button place while a reply streams', (
      tester,
    ) async {
      final adapter = ManualAdapter();
      final controller = await pump(tester, adapter: adapter);

      expect(find.byType(ChatSendButton), findsOneWidget);
      expect(find.byType(ChatStopButton), findsNothing);

      await controller.onSend('q');
      await tester.pump();

      expect(find.byType(ChatSendButton), findsNothing);
      expect(find.byTooltip('Stop'), findsOneWidget);

      adapter.finish();
      await tester.pumpAndSettle();
      expect(find.byType(ChatSendButton), findsOneWidget);
    });

    testWidgets('an adapter without stop never swaps the button', (
      tester,
    ) async {
      final adapter = _NoStopAdapter();
      final controller = await pump(tester, adapter: adapter);

      await controller.onSend('q');
      await tester.pump();

      expect(find.byType(ChatStopButton), findsNothing);

      adapter.finish();
      await tester.pumpAndSettle();
    });
  });

  group('answer actions', () {
    testWidgets('the newest answer offers regenerate', (tester) async {
      final controller = await pump(tester);

      await controller.onSend('q');
      await tester.pumpAndSettle();

      expect(find.byTooltip('Regenerate'), findsOneWidget);
      expect(find.byTooltip('Copy'), findsOneWidget);
    });

    testWidgets('only the newest one does', (tester) async {
      final controller = await pump(tester);

      await controller.onSend('first');
      await tester.pumpAndSettle();
      await controller.onSend('second');
      await tester.pumpAndSettle();

      expect(find.byTooltip('Regenerate'), findsOneWidget);
    });

    testWidgets('actions hide until hover when the theme asks for it', (
      tester,
    ) async {
      final controller = await pump(
        tester,
        theme: const ChatTheme(answerActionsAlwaysVisible: false),
      );

      await controller.onSend('q');
      await tester.pumpAndSettle();

      final opacity = tester.widget<AnimatedOpacity>(
        find
            .descendant(
              of: find.byType(ChatAnswerActions),
              matching: find.byType(AnimatedOpacity),
            )
            .first,
      );
      expect(opacity.opacity, 0);
    });
  });

  group('drawer', () {
    Future<void> openDrawer(WidgetTester tester) async {
      await tester.tap(find.byTooltip('Conversations'));
      await tester.pumpAndSettle();
    }

    testWidgets('rename retitles the conversation', (tester) async {
      final controller = await pump(tester);
      await controller.onSend('a question');
      await tester.pumpAndSettle();

      await openDrawer(tester);
      await tester.tap(find.byTooltip('More'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, 'Renamed thread');
      await tester.tap(find.widgetWithText(FilledButton, 'Rename'));
      await tester.pumpAndSettle();

      expect(controller.activeSession!.title, 'Renamed thread');
    });

    testWidgets('without renameSessions the row keeps a plain delete', (
      tester,
    ) async {
      final controller = await pump(tester, adapter: FakeAdapter());
      await controller.onSend('a question');
      await tester.pumpAndSettle();

      await openDrawer(tester);

      expect(find.byTooltip('More'), findsNothing);
      expect(find.byTooltip('Delete'), findsOneWidget);
    });

    testWidgets('the search field appears past the threshold and filters', (
      tester,
    ) async {
      final controller = await pump(tester);

      for (var i = 0; i < ChatDrawer.searchThreshold + 1; i++) {
        await controller.onNewSession();
        await controller.onSend('topic $i');
        await tester.pumpAndSettle();
      }

      await openDrawer(tester);
      expect(find.widgetWithText(TextField, ''), findsWidgets);

      await tester.enterText(find.byType(TextField).last, 'topic 3');
      await tester.pumpAndSettle();

      final rows = find.descendant(
        of: find.byType(ChatDrawer),
        matching: find.byType(ChatSessionTile),
      );
      expect(rows, findsOneWidget);
      expect(
        find.descendant(of: rows, matching: find.text('topic 3')),
        findsOneWidget,
      );
    });

    testWidgets('load more shows only with paging and more to fetch', (
      tester,
    ) async {
      await pump(tester);
      await openDrawer(tester);

      expect(
        find.text('Load more'),
        findsNothing,
        reason: 'hasMoreSessions is false',
      );
    });
  });
}

class _NoStopAdapter extends ManualAdapter {
  @override
  ChatCapabilities get capabilities => const ChatCapabilities(stop: false);
}
