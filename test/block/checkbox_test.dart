import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import '../utils/test_helpers.dart';

void main() {
  group('Checkboxes', () {
    testWidgets('unchecked checkbox', (tester) async {
      await pumpMarkdown(tester, '[ ] Unchecked item');
      final output = getSerializedOutput(tester);
      expect(output, contains('CHECKBOX'));
      expect(output, contains('checked=false'));
    });

    testWidgets('checked checkbox', (tester) async {
      await pumpMarkdown(tester, '[x] Checked item');
      final output = getSerializedOutput(tester);
      expect(output, contains('CHECKBOX'));
      expect(output, contains('checked=true'));
    });

    testWidgets('multiple checkboxes', (tester) async {
      await pumpMarkdown(tester, '[ ] First\n[x] Second\n[ ] Third');
      final output = getSerializedOutput(tester);
      // Should have 3 checkboxes
      expect('CHECKBOX'.allMatches(output).length, equals(3));
    });

    testWidgets('checkbox with styled text', (tester) async {
      await pumpMarkdown(tester, '[x] **Bold** task');
      final output = getSerializedOutput(tester);
      expect(output, contains('CHECKBOX'));
      expect(output, contains('checked=true'));
    });

    testWidgets('checkbox with inline code', (tester) async {
      await pumpMarkdown(tester, '[ ] Run `npm install`');
      final output = getSerializedOutput(tester);
      expect(output, contains('CHECKBOX'));
      expect(output, contains('checked=false'));
    });
  });

  // A GFM task list is a block-level checkbox inside a list item, which is the
  // one place a list item has no inline content of its own. The separator
  // before an item's nested blocks used to be unconditional, so the checkbox
  // was pushed onto the line below its own bullet — a blank line per item.
  group('Task lists lay out like the regex pipeline', () {
    const cases = <String, String>{
      'task list': '- [x] Alpha\n- [ ] Beta',
      'radio list': '- (x) Yes\n- ( ) No',
      'ordered task list': '1. [x] One\n2. [ ] Two',
      'task and plain items': '- [x] task\n- plain item\n- [ ] another',
      'nested list': '- outer one\n  - inner a\n- outer two',
      'item with a nested child': '- has text\n  - and a child',
      'plain list': '- one\n- two\n- three',
    };

    Future<double> height(
      WidgetTester tester,
      String source, {
      required bool incremental,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 500,
                child: GptMarkdown(source, incremental: incremental),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      while (tester.takeException() != null) {}
      return (find.byType(SizedBox).evaluate().first.renderObject as RenderBox)
          .size
          .height;
    }

    for (final entry in cases.entries) {
      testWidgets(entry.key, (tester) async {
        tester.view.physicalSize = const Size(800, 2000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        expect(
          await height(tester, entry.value, incremental: true),
          moreOrLessEquals(
            await height(tester, entry.value, incremental: false),
            epsilon: 0.5,
          ),
        );
      });
    }

    testWidgets('the checkbox sits on its own line, not below it', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await height(tester, '- [x] Alpha', incremental: true);
      final box =
          find.byType(Checkbox).evaluate().single.renderObject! as RenderBox;
      final label =
          find
                  .byWidgetPredicate(
                    (w) =>
                        w is RichText && w.text.toPlainText().trim() == 'Alpha',
                  )
                  .evaluate()
                  .single
                  .renderObject!
              as RenderBox;
      // Same row: their vertical centres are within a line of each other.
      final boxCentre = box.localToGlobal(Offset.zero).dy + box.size.height / 2;
      final labelCentre =
          label.localToGlobal(Offset.zero).dy + label.size.height / 2;
      expect((boxCentre - labelCentre).abs(), lessThan(12));
    });
  });
}
