import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

void main() {
  group('parseGenUiPayload', () {
    test('every top-level key becomes a model', () {
      final parsed = parseGenUiPayload(
        '{"text": {"text": "hi"}, "bar_chart": {"values": [1, 2]}}',
      );

      expect(parsed.hasError, isFalse);
      expect(parsed.models.map((model) => model.type), ['text', 'bar_chart']);
      expect(parsed.models.first.attributes['text'], 'hi');
    });

    test('a non-object value is wrapped under "value"', () {
      final parsed = parseGenUiPayload('{"text": "hello"}');

      expect(parsed.models.single.attributes, {'value': 'hello'});
    });

    test('invalid JSON reports an error', () {
      final parsed = parseGenUiPayload('{"bar_chart": [1, 2}');

      expect(parsed.hasError, isTrue);
      expect(parsed.models, isEmpty);
    });

    test('a JSON array is rejected', () {
      final parsed = parseGenUiPayload('[1, 2, 3]');

      expect(parsed.error, 'Gen UI payload must be a JSON object');
    });

    test('an empty payload reports an error', () {
      expect(parseGenUiPayload('   ').hasError, isTrue);
    });
  });

  group('GenUiRegistry', () {
    test('defaults register the built-in widget set', () {
      final registry = GenUiRegistry.defaults();

      expect(registry.types, containsAll(<String>[
        'text',
        'image',
        'button',
        'line_chart',
        'area_chart',
        'bar_chart',
        'pie_chart',
        'comparison_chart',
        'progress_list',
        'metric_grid',
        'unit_converter',
        'timeline_flow',
      ]));
    });

    test('host-owned types are left unregistered', () {
      final registry = GenUiRegistry.defaults();

      for (final type in [
        'plot_latex',
        'surface_3d',
        'polar_surface_3d',
        'spherical_surface_3d',
        'cylindrical_surface_3d',
        'video',
        'val_scene',
      ]) {
        expect(registry.contains(type), isFalse, reason: type);
      }
    });

    test('clone does not share registrations with its source', () {
      final base = GenUiRegistry.defaults();
      final extended = base.clone()
        ..register('video', (context, model) => const SizedBox.shrink());

      expect(extended.contains('video'), isTrue);
      expect(base.contains('video'), isFalse);
    });

    testWidgets('an unknown type renders nothing by default', (tester) async {
      final registry = GenUiRegistry.defaults();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) =>
                  registry.build(context, '{"surface_3d": {"equation": "x"}}'),
            ),
          ),
        ),
      );

      expect(find.byType(SizedBox), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('unknownBuilder catches unregistered types', (tester) async {
      final registry = GenUiRegistry.defaults(
        unknownBuilder: (context, model) => Text('unsupported: ${model.type}'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => registry.build(context, '{"video": {}}'),
            ),
          ),
        ),
      );

      expect(find.text('unsupported: video'), findsOneWidget);
    });

    testWidgets('register overrides a built-in', (tester) async {
      final registry = GenUiRegistry.defaults()
        ..register('bar_chart', (context, model) => const Text('custom bars'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) =>
                  registry.build(context, '{"bar_chart": {"values": [1]}}'),
            ),
          ),
        ),
      );

      expect(find.text('custom bars'), findsOneWidget);
      expect(find.byType(GenBarChart), findsNothing);
    });

    testWidgets('multiple keys stack in a column', (tester) async {
      final registry = GenUiRegistry.defaults();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => registry.build(
                context,
                '{"text": {"text": "top"}, "progress_list": '
                    '{"values": [{"label": "a", "value": 50}]}}',
              ),
            ),
          ),
        ),
      );

      expect(find.text('top'), findsOneWidget);
      expect(find.byType(GenProgressList), findsOneWidget);
    });

    testWidgets('errorBuilder handles a bad payload', (tester) async {
      final registry = GenUiRegistry.defaults(
        errorBuilder: (context, message) => const Text('bad payload'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => registry.build(context, '{oops'),
            ),
          ),
        ),
      );

      expect(find.text('bad payload'), findsOneWidget);
    });

    testWidgets('button presses reach onAction', (tester) async {
      String? received;
      final registry = GenUiRegistry.defaults(
        onAction: (action, attributes) => received = action,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => registry.build(
                context,
                '{"button": {"text": "Go", "action": "open_practice"}}',
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Go'));

      expect(received, 'open_practice');
    });

    testWidgets('a button without onAction renders disabled', (tester) async {
      final registry = GenUiRegistry.defaults();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) =>
                  registry.build(context, '{"button": {"text": "Go"}}'),
            ),
          ),
        ),
      );

      expect(tester.widget<TextButton>(find.byType(TextButton)).onPressed,
          isNull);
    });
  });

  group('value helpers', () {
    test('genUiDouble accepts numbers and numeric strings', () {
      expect(genUiDouble(3), 3.0);
      expect(genUiDouble('2.5'), 2.5);
      expect(genUiDouble('abc'), isNull);
      expect(genUiDouble(double.nan), isNull);
    });

    test('genUiColor parses hex forms', () {
      expect(genUiColor('#766CE3', fallback: Colors.black),
          const Color(0xFF766CE3));
      expect(genUiColor('0x80766CE3', fallback: Colors.black),
          const Color(0x80766CE3));
      expect(genUiColor('nope', fallback: Colors.black), Colors.black);
    });

    test('genUiNiceTicks covers the range with round steps', () {
      final ticks = genUiNiceTicks(0, 10);

      expect(ticks.first, lessThanOrEqualTo(0));
      expect(ticks.last, greaterThanOrEqualTo(10));
      expect(ticks.length, greaterThan(2));
    });

    test('GenUiPoint accepts bare numbers and objects', () {
      final points = GenUiPoint.fromList([
        4,
        {'x': 7, 'y': 9},
        {'value': 2},
        'skip-me',
      ]);

      expect(points.map((p) => p.x), [0, 7, 2]);
      expect(points.map((p) => p.y), [4, 9, 2]);
    });
  });
}
