import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

/// Renders `example/gen_ui_mock.md` — the fixture that exercises every
/// built-in gen-UI widget — and checks the whole document survives a pump.
void main() {
  late String mockDocument;

  setUpAll(() {
    mockDocument = File('example/gen_ui_mock.md').readAsStringSync();
  });

  Future<void> pumpMock(WidgetTester tester, {bool incremental = false}) async {
    final registry = GenUiRegistry.defaults(onAction: (_, _) {});

    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: GptMarkdown(
              mockDocument,
              incremental: incremental,
              genUiBuilder: registry.build,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('the mock document renders without throwing', (tester) async {
    await pumpMock(tester);

    expect(tester.takeException(), isNull);
  });

  testWidgets('every built-in widget type appears', (tester) async {
    await pumpMock(tester);

    for (final type in <Type>[
      GenText,
      GenImage,
      GenButton,
      GenLineChart,
      GenBarChart,
      GenPieChart,
      GenComparisonChart,
      GenProgressList,
      GenMetricGrid,
      GenUnitConverter,
      GenTimelineFlow,
      GenPlotLatex,
      GenVideo,
      GenSurface3DGraph,
      GenPolarSurface3DGraph,
      GenSphericalSurface3DGraph,
      GenCylindricalSurface3DGraph,
    ]) {
      expect(find.byType(type), findsWidgets, reason: '$type missing');
    }
  });

  testWidgets('the incremental pipeline renders it too', (tester) async {
    await pumpMock(tester, incremental: true);

    expect(tester.takeException(), isNull);
    expect(find.byType(GenLineChart), findsWidgets);
    expect(find.byType(GenTimelineFlow), findsWidgets);
  });

  test('every directive is well formed', () {
    // Payloads are delimited by private-use markers, so no markdown
    // punctuation inside the JSON can truncate them.
    final directives = RegExp(
      '${RegExp.escape(genUiOpenMarker)}(.*?)${RegExp.escape(genUiCloseMarker)}',
      dotAll: true,
    ).allMatches(mockDocument);

    expect(directives, isNotEmpty);
    for (final directive in directives) {
      final payload = directive[1]!;
      expect(payload, isNot(contains('\n')), reason: 'payload spans lines');
      expect(
        payload.trimRight().endsWith('}'),
        isTrue,
        reason: 'truncated payload: $payload',
      );
    }
  });

  testWidgets('degenerate payloads render nothing, not an error',
      (tester) async {
    final registry = GenUiRegistry.defaults();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                registry.build(
                  context,
                  '{"bar_chart": {"title": "No data", "values": []}}',
                ),
                registry.build(
                  context,
                  '{"line_chart": {"points": "not-a-list"}}',
                ),
                registry.build(
                  context,
                  '{"unit_converter": {"fromUnit": "kg", "toUnit": "m"}}',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('No data'), findsNothing);
  });
}
