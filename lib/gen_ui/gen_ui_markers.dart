/// Delimiters for gen-UI directives in markdown text.
///
/// The markers are Unicode Private Use Area code points, so — unlike the older
/// `*genui#...%` form — a payload can contain `%`, `*`, braces, or any other
/// markdown punctuation without truncating the directive or leaking emphasis
/// syntax into the surrounding text.
///
/// A directive is `U+E200` `genui` `U+E202` `<json>` `U+E201`. Build one with
/// [wrapGenUi] rather than typing the invisible characters:
///
/// ```dart
/// final directive = wrapGenUi('{"bar_chart": {"values": [1, 2, 3]}}');
/// ```
library;

import 'package:flutter/widgets.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

/// Opens a gen-UI directive: `U+E200` + `genui` + `U+E202`.
const String genUiOpenMarker = '\u{E200}genui\u{E202}';

/// Closes a gen-UI directive: `U+E201`.
const String genUiCloseMarker = '\u{E201}';

/// First code unit of [genUiOpenMarker], used by the scanner as a cheap guard.
const int genUiOpenMarkerRune = 0xE200;

/// Wraps a raw JSON [payload] in the gen-UI delimiters.
String wrapGenUi(String payload) => '$genUiOpenMarker$payload$genUiCloseMarker';

/// Wraps a payload builder as the [InlineDirective] `GptMarkdown` expects.
///
/// gen-UI is a host feature, not Markdown syntax. The parser knows nothing
/// about it: it keeps the region between the markers out of the parse and
/// hands the payload over verbatim, so braces, backticks and emphasis markers
/// inside a payload reach the builder intact.
///
/// ```dart
/// GptMarkdown(reply, inlineDirectives: [genUiDirective(registry.build)]);
/// ```
InlineDirective genUiDirective(
  Widget Function(BuildContext context, String payload) build,
) => InlineDirective(
  open: genUiOpenMarker,
  close: genUiCloseMarker,
  builder:
      (context, payload, style) => WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: build(context, payload),
      ),
);
