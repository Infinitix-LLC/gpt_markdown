part of 'gpt_markdown.dart';

/// Builds the span for one [InlineDirective] occurrence.
///
/// [payload] is the text between the delimiters, verbatim — the parser never
/// looked at it, so whatever the host put there is what arrives here.
typedef InlineDirectiveBuilder =
    InlineSpan Function(BuildContext context, String payload, TextStyle style);

/// A host-defined inline region the Markdown parser must not look inside.
///
/// [InlinePattern] is the tool for host syntax that is still *text* —
/// `@mention`, `#channel`, `:emoji:`. It runs over the plain-text runs a parse
/// produced, which means the parse has already happened: a payload holding
/// `**`, a backtick, `~~` or `[…](…)` is consumed as Markdown before the
/// pattern ever sees it, and the match silently fails. That is fine for a
/// mention and useless for a JSON payload.
///
/// A directive is the other case: a delimited region whose contents are not
/// Markdown and must survive intact. It is lifted out of the source *before*
/// parsing and put back at render time, so nothing inside it can be
/// interpreted, truncated, or split across nodes.
///
/// ```dart
/// GptMarkdown(
///   reply,
///   inlineDirectives: [
///     InlineDirective(
///       open: '\u{E200}widget\u{E202}',
///       close: '\u{E201}',
///       builder: (context, payload, style) =>
///           WidgetSpan(child: MyWidget.fromJson(payload)),
///     ),
///   ],
/// )
/// ```
///
/// Delimiters should be characters a model does not emit by accident —
/// Private Use Area code points are the usual choice, substituted by the
/// server on the way out so the model itself never types them.
///
/// An unterminated directive stays literal text until its closer arrives,
/// which is what a streaming reply needs: a payload that is still arriving
/// must not render half-built.
class InlineDirective {
  /// Creates a directive.
  const InlineDirective({
    required this.open,
    required this.close,
    required this.builder,
  }) : assert(open.length > 0, 'open must not be empty'),
       assert(close.length > 0, 'close must not be empty');

  /// The opening delimiter.
  final String open;

  /// The closing delimiter.
  final String close;

  /// Builds the span for each complete occurrence.
  final InlineDirectiveBuilder builder;
}

/// Private Use Area sentinels wrapping a masked directive.
///
/// Chosen so the masked form is inert to every stage that follows: the code
/// points are outside ASCII, so the inline parser's trigger table rejects them
/// without a second thought, and the payload rides between them Base64-encoded,
/// whose alphabet holds no Markdown punctuation at all. The masked text can
/// therefore be split into segments, parsed, and carried through the AST as
/// ordinary text with nothing to interpret.
const String _maskOpen = '\u{E010}';
const String _maskClose = '\u{E011}';

/// Replaces every complete [directives] occurrence in [source] with an inert
/// sentinel carrying its payload.
///
/// Returns [source] unchanged when there is nothing to do, so a document
/// without directives — which is every document unless the host configured
/// one — costs one `indexOf` per directive and no allocation.
String maskInlineDirectives(String source, List<InlineDirective> directives) {
  if (directives.isEmpty) {
    return source;
  }
  var out = source;
  for (var index = 0; index < directives.length; index++) {
    final directive = directives[index];
    if (!out.contains(directive.open)) {
      continue;
    }
    final buffer = StringBuffer();
    var cursor = 0;
    while (cursor < out.length) {
      final start = out.indexOf(directive.open, cursor);
      if (start == -1) {
        break;
      }
      final from = start + directive.open.length;
      final end = out.indexOf(directive.close, from);
      if (end == -1) {
        // Still arriving. Left as written so it reads as the literal text it
        // currently is, and masked on a later build once the closer lands.
        break;
      }
      buffer
        ..write(out.substring(cursor, start))
        ..write(_maskOpen)
        ..write(index)
        ..write(':')
        ..write(base64Encode(utf8.encode(out.substring(from, end))))
        ..write(_maskClose);
      cursor = end + directive.close.length;
    }
    if (buffer.isNotEmpty) {
      buffer.write(out.substring(cursor));
      out = buffer.toString();
    }
  }
  return out;
}

/// Matches one masked directive, for the regex pipeline's component.
const String inlineDirectiveMaskPattern =
    '$_maskOpen[0-9]+:[A-Za-z0-9+/=]*$_maskClose';

/// Reads a masked directive back into its index and payload.
///
/// Returns null when [masked] is not a directive this document declared, so a
/// stray sentinel in model output renders as the text it is rather than being
/// mistaken for a widget.
({int index, String payload})? decodeInlineDirectiveMask(
  String masked,
  int directiveCount,
) {
  if (!masked.startsWith(_maskOpen) || !masked.endsWith(_maskClose)) {
    return null;
  }
  final body = masked.substring(1, masked.length - 1);
  final colon = body.indexOf(':');
  if (colon == -1) {
    return null;
  }
  final index = int.tryParse(body.substring(0, colon));
  if (index == null || index < 0 || index >= directiveCount) {
    return null;
  }
  try {
    return (
      index: index,
      payload: utf8.decode(base64Decode(body.substring(colon + 1))),
    );
  } on FormatException {
    return null;
  }
}

/// Expands the sentinels in [text] back into directive spans.
///
/// [rest] renders the stretches between them, so ordinary text still goes
/// through whatever the caller does with it — inline patterns, autolinking.
List<InlineSpan> expandInlineDirectives(
  BuildContext context,
  String text,
  List<InlineDirective> directives,
  TextStyle style,
  List<InlineSpan> Function(String text) rest,
) {
  final out = <InlineSpan>[];
  var cursor = 0;
  while (cursor < text.length) {
    final start = text.indexOf(_maskOpen, cursor);
    if (start == -1) {
      break;
    }
    final end = text.indexOf(_maskClose, start + 1);
    if (end == -1) {
      break;
    }
    final body = text.substring(start + 1, end);
    final colon = body.indexOf(':');
    final index = colon == -1 ? -1 : int.tryParse(body.substring(0, colon));
    if (index == null || index < 0 || index >= directives.length) {
      // Not one of ours after all; leave it as written.
      cursor = start + 1;
      continue;
    }
    if (start > cursor) {
      out.addAll(rest(text.substring(cursor, start)));
    }
    out.add(
      directives[index].builder(
        context,
        utf8.decode(base64Decode(body.substring(colon + 1))),
        style,
      ),
    );
    cursor = end + 1;
  }
  if (cursor < text.length) {
    out.addAll(rest(text.substring(cursor)));
  }
  return out;
}
