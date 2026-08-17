import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_markdown/gpt_chat_gateway.dart';

import 'fakes.dart';

void main() {
  Future<void> pumpChat(
    WidgetTester tester,
    ChatAdapter adapter, {
    ChatModelSource? models,
  }) async {
    await tester.pumpWidget(
      MaterialApp(home: GptChat(adapter: adapter, models: models)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the empty state before the first message', (tester) async {
    await pumpChat(tester, FakeAdapter());

    expect(find.byType(ChatEmptyState), findsOneWidget);
  });

  testWidgets('sending renders both the prompt and the reply', (tester) async {
    await pumpChat(tester, FakeAdapter(deltas: ['Hi there']));

    await tester.enterText(find.byType(TextField), 'hello');
    await tester.pump();
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(ChatQuestion),
        matching: find.text('hello'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Hi there', findRichText: true), findsOneWidget);
  });

  testWidgets('the composer clears after sending', (tester) async {
    await pumpChat(tester, FakeAdapter());

    await tester.enterText(find.byType(TextField), 'hello');
    await tester.pump();
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
  });

  testWidgets('a failure shows the error bar', (tester) async {
    await pumpChat(
      tester,
      FakeAdapter(error: const ChatException('no credit')),
    );

    await tester.enterText(find.byType(TextField), 'hello');
    await tester.pump();
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();

    expect(find.text('no credit'), findsWidgets);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('the drawer lists sessions', (tester) async {
    await pumpChat(tester, FakeAdapter());

    await tester.enterText(find.byType(TextField), 'hello');
    await tester.pump();
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Conversations'));
    await tester.pumpAndSettle();

    expect(find.text('New chat'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('hello'), findsWidgets);
  });

  testWidgets('no model source means no picker', (tester) async {
    await pumpChat(tester, FakeAdapter());

    expect(find.byType(ChatModelPicker), findsNothing);
  });

  testWidgets('the model picker sits in the app bar and opens a sheet', (
    tester,
  ) async {
    final models = FakeModelSource();
    await pumpChat(tester, _ModelAdapter(), models: models);

    expect(
      find.descendant(
        of: find.byType(ChatAppBar),
        matching: find.byType(ChatModelPicker),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byType(ChatModelPicker));
    await tester.pumpAndSettle();

    expect(find.byType(ChatModelSheet), findsOneWidget);
    expect(find.text('Model'), findsOneWidget);

    await tester.tap(find.text('gemini-3.6-flash').last);
    await tester.pumpAndSettle();

    expect(find.byType(ChatModelSheet), findsNothing);
    expect(models.chosen, 'gemini-3.6-flash');
  });
}

/// A fake that advertises model support.
class _ModelAdapter extends FakeAdapter {
  @override
  ChatCapabilities get capabilities => const ChatCapabilities(models: true);
}
