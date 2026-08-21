import 'package:example/autolink_demo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_markdown/custom_widgets/link_button.dart';

void main() {
  testWidgets('autolink demo links URLs and honours both switches',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const AutolinkApp());
    await tester.pumpAndSettle();

    final linked = find.byType(LinkButton).evaluate().length;
    expect(linked, greaterThan(5));

    // Allowlisting `myapp` links one more URL — the bare `myapp://open?id=7`.
    await tester.tap(find.byType(Switch).at(1));
    await tester.pumpAndSettle();
    expect(find.byType(LinkButton).evaluate().length, linked + 1);

    // Turning autolinking off leaves only the explicit markdown links.
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(find.byType(LinkButton).evaluate().length, lessThan(linked));
  });
}
