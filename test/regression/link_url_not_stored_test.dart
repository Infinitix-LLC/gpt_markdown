/// Regression test: LinkButton.url property now populated
///
/// Fixed: The LinkButton widget's `url` property is now set when creating
/// LinkButton instances in markdown_component.dart.
///
/// Location: lib/markdown_component.dart, ATagMd.build() method
/// Fix: Added `url: url` parameter to LinkButton constructor call
library;

import 'package:flutter_test/flutter_test.dart';
import '../utils/test_helpers.dart';

void main() {
  group('Regression: Link URL stored in LinkButton widget', () {
    testWidgets(
      'link URL should be accessible in serialized output',
      (tester) async {
      await pumpMarkdown(tester, '[click here](https://example.com)');
      final output = getSerializedOutput(tester);

      // Verify URL is included in serialized output
      expect(
        output,
        contains('LINK("click here", url="https://example.com")'),
      );
    });

    testWidgets(
      'link with path should include full URL',
      (tester) async {
      await pumpMarkdown(tester, '[docs](https://example.com/docs/page)');
      final output = getSerializedOutput(tester);

      // Verify full URL path is included
      expect(
        output,
        contains('LINK("docs", url="https://example.com/docs/page")'),
      );
    });
  });
}
