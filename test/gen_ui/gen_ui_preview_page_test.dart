import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

void main() {
  Future<void> pumpPage(WidgetTester tester, {Widget? page}) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(home: page ?? const GenUiPreviewPage()),
    );
    await tester.pump();
  }

  test('the embedded const matches example/gen_ui_mock.md', () {
    // Line endings are a checkout artifact, not content: git hands Windows a
    // CRLF file while the Dart const is always LF, so comparing them raw fails
    // for every Windows developer regardless of whether the content matches.
    final onDisk = File(
      'example/gen_ui_mock.md',
    ).readAsStringSync().replaceAll('\r\n', '\n');

    expect(
      kGenUiMockDocument.replaceAll('\r\n', '\n'),
      onDisk,
      reason:
          'Regenerate lib/gen_ui/gen_ui_mock_document.dart from '
          'example/gen_ui_mock.md',
    );
  });

  testWidgets('renders the mock document without throwing', (tester) async {
    await pumpPage(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Gen UI preview'), findsOneWidget);
    expect(find.byType(GenTimelineFlow), findsWidgets);
    expect(find.byType(GenPieChart), findsWidgets);
  });

  testWidgets('lists the registered types', (tester) async {
    await pumpPage(tester);

    // Derived, not hardcoded: adding a builder should not fail a test that is
    // about the label being wired up at all.
    final count = GenUiPreviewPage.demoRegistry().types.length;
    expect(find.text('$count registered widget types'), findsOneWidget);
  });

  testWidgets('unregistered types show a host-owned marker', (tester) async {
    // The mock no longer contains an unregistered type — the preview now
    // stands in for `val_scene` — so this drives the mechanism directly rather
    // than depending on the mock leaving a gap.
    await pumpPage(
      tester,
      page: GenUiPreviewPage(
        document: 'Before\n\n${wrapGenUi('{"host_only": {"a": 1}}')}\n\nAfter',
      ),
    );

    expect(find.textContaining('`host_only` is host-owned'), findsOneWidget);
  });

  testWidgets('the preview stands in for val_scene', (tester) async {
    await pumpPage(tester);

    // `defaults()` deliberately omits it; the preview registers a demo builder
    // so the page shows the whole surface instead of a blank line.
    expect(GenUiRegistry.defaults().types, isNot(contains('val_scene')));
    expect(GenUiPreviewPage.demoRegistry().types, contains('val_scene'));
    expect(find.text('VAL scene'), findsWidgets);
  });

  testWidgets('the source toggle swaps rendered output for raw markdown', (
    tester,
  ) async {
    await pumpPage(tester);
    expect(find.byType(GenPieChart), findsWidgets);

    await tester.tap(find.byTooltip('Show source'));
    await tester.pump();

    expect(find.byType(GenPieChart), findsNothing);
    expect(find.byType(SelectableText), findsOneWidget);
  });

  testWidgets('the incremental toggle keeps the document rendering', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.tap(find.byTooltip('Incremental parsing: off'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Incremental parsing: on'), findsOneWidget);
    expect(find.byType(GenTimelineFlow), findsWidgets);
  });

  testWidgets('the brightness toggle rebuilds in the other theme', (
    tester,
  ) async {
    await pumpPage(tester);
    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);

    await tester.tap(find.byTooltip('Toggle brightness'));
    await tester.pump();

    expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a custom document and registry are honoured', (tester) async {
    await pumpPage(
      tester,
      page: GenUiPreviewPage(
        title: 'Custom',
        document: 'Header\n\n${wrapGenUi('{"val_scene": {"id": "x"}}')}',
        registry:
            GenUiRegistry.defaults()..register(
              'val_scene',
              (context, model) => const Text('fake scene'),
            ),
      ),
    );

    final count = GenUiRegistry.defaults().types.length + 1; // + val_scene
    expect(find.text('Custom'), findsOneWidget);
    expect(find.text('fake scene'), findsOneWidget);
    expect(find.text('$count registered widget types'), findsOneWidget);
  });
}
