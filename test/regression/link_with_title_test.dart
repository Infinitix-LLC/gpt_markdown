// Regression test: Link with title attribute support
//
// Fixed: Links with title attributes in the format [text](url "title")
// are now correctly parsed as links.
//
// Input: [Link Text](/path/to/page "Link Title")
// Result: Link renders correctly with text "Link Text" pointing to URL
//
// Fix: Updated ATagMd regex to support optional quoted title after URL,
// and URL extraction logic to strip the title portion.

import 'package:flutter_test/flutter_test.dart';
import '../utils/test_helpers.dart';

void main() {
  group('Link with title attribute', () {
    testWidgets(
      'link with quoted title is parsed correctly '
      '',
      (tester) async {
      await pumpMarkdown(
        tester,
        '[Link Text](/path/to/page "Link Title")',
      );
      final output = getSerializedOutput(tester);

      // The link should be recognized and rendered
      expect(output, contains('LINK'));
      expect(output, contains('Link Text'));
    });

    testWidgets(
      'link with title in sentence context '
      '',
      (tester) async {
      await pumpMarkdown(
        tester,
        'Check out [Projects](/page/projects "Project Overview") for more info.',
      );
      final output = getSerializedOutput(tester);

      // The link should be recognized
      expect(output, contains('LINK'));
      expect(output, contains('Projects'));
      // Surrounding text should be present
      expect(output, contains('Check out'));
      expect(output, contains('for more info'));
    });

    testWidgets(
      'link with title containing special characters '
      '',
      (tester) async {
      await pumpMarkdown(
        tester,
        '[Features](/features "App Features: Overview")',
      );
      final output = getSerializedOutput(tester);

      expect(output, contains('LINK'));
      expect(output, contains('Features'));
    });

    testWidgets(
      'multiple links with titles '
      '',
      (tester) async {
      await pumpMarkdown(
        tester,
        '[First](/a "Title A") and [Second](/b "Title B")',
      );
      final output = getSerializedOutput(tester);

      // Both links should be recognized
      expect(output, contains('LINK'));
      expect(output, contains('and'));
    });
  });
}
