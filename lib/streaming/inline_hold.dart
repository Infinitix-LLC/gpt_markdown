/// Holding the reveal behind markup that has not finished arriving.
///
/// A streaming reply is parsed from what has been received so far, so an inline
/// construct is literal text until its closing delimiter lands. `` `npm `` is
/// prose; `` `npm install` `` is a code chip. Reveal the characters as they
/// arrive and the reader watches eight settled words turn monospace a moment
/// later — a different font, a background, different metrics, and a line that
/// reflows around them. The same happens when `**bold` closes, or `\(x^2`.
///
/// Nothing is wrong with the parse; the reveal is simply ahead of it. So the
/// head waits: characters that could still change meaning are not shown until
/// the construct that governs them is complete, and every character a reader
/// sees is already in its final form.
library;

/// Longest run of text the reveal will wait on for a delimiter that also
/// occurs in ordinary prose.
///
/// A lone backtick, or an asterisk used as a footnote mark, has no closer
/// coming. Waiting on one stalls the reveal and then dumps the backlog, which
/// reads worse than the restyle this avoids. These delimiters are given a
/// short leash: real emphasis and code spans close well inside it.
const int proseDelimiterHold = 48;

/// Longest run of text the reveal will wait on for a delimiter that is
/// unambiguously markup.
///
/// `\(`, `\[`, `<u>` and `[label](href)` do not appear by accident, so it is
/// worth waiting longer — a link with a long URL, or a displayed equation,
/// routinely runs past the prose limit.
const int markupDelimiterHold = 160;

/// How much of [source] can be shown without its styling changing later.
///
/// Returns [source]'s length when nothing is pending, so the common case costs
/// one scan and no allocation.
///
/// Deliberately a scan for unbalanced delimiters rather than a second parse:
/// it runs on the tail segment for every chunk that arrives, and it only has to
/// be *conservative*. Holding a character that would not have changed costs a
/// few milliseconds of latency; showing one that does change is the artefact
/// this exists to remove.
int inlineSafeLength(String source, {bool holdMathDollars = false}) {
  var limit = source.length;

  // Each delimiter carries its own patience. Holding is only ever worth it
  // while the closer is plausibly still coming.
  void holdAt(int index, int cap) {
    if (index < 0 || index >= limit) {
      return;
    }
    if (source.length - index > cap) {
      return;
    }
    limit = index;
  }

  // A code span runs to its closing backtick and swallows any other delimiter
  // on the way, so it is resolved first and the rest is checked outside it.
  var i = 0;
  var lastOpenTick = -1;
  final outside = StringBuffer();
  while (i < source.length) {
    if (source.codeUnitAt(i) == 0x60 /* ` */ ) {
      final close = source.indexOf('`', i + 1);
      if (close == -1) {
        lastOpenTick = i;
        break;
      }
      // Keep the offsets aligned without copying the span's contents.
      outside.write(' ' * (close + 1 - i));
      i = close + 1;
      continue;
    }
    outside.writeCharCode(source.codeUnitAt(i));
    i += 1;
  }
  holdAt(lastOpenTick, proseDelimiterHold);

  // A `*` that begins a line and is followed by whitespace is a list bullet,
  // and a line made only of `*`/`-`/`_` is a thematic break — neither is an
  // emphasis delimiter, and counting them as one made every streamed `*`
  // bullet invisible for the length of the leash. They are blanked out
  // before the emphasis scans, offsets preserved.
  final rest = _maskLineMarkers(outside.toString());
  // Paired delimiters: an odd count means the last one is still open.
  for (final token in const ['**', '~~', r'$$']) {
    holdAt(_lastUnpaired(rest, token), proseDelimiterHold);
  }
  // Single `*` for italic, but only the ones that are not part of `**`.
  holdAt(_lastUnpairedStar(rest), proseDelimiterHold);

  // Delimiters with distinct open and close forms.
  for (final pair in const [(r'\(', r'\)'), (r'\[', r'\]'), ('<u>', '</u>')]) {
    final open = rest.lastIndexOf(pair.$1);
    if (open != -1 && rest.indexOf(pair.$2, open + pair.$1.length) == -1) {
      holdAt(open, markupDelimiterHold);
    }
  }

  // A link or image: `[label](href)` is prose until its closing paren.
  final bracket = rest.lastIndexOf('[');
  if (bracket != -1) {
    final closeBracket = rest.indexOf(']', bracket + 1);
    if (closeBracket == -1) {
      holdAt(bracket, markupDelimiterHold);
    } else if (closeBracket + 1 < rest.length &&
        rest.codeUnitAt(closeBracket + 1) == 0x28 /* ( */ &&
        rest.indexOf(')', closeBracket + 1) == -1) {
      holdAt(bracket, markupDelimiterHold);
    }
  }

  // A table row is atomic: a line beginning with `|` is held until its
  // newline arrives, so the parser only ever sees complete rows. And while
  // the delimiter row is still arriving, the header is held with it — a
  // partial delimiter is invalid, so without this the table formed on one
  // cut (`|-`), fell apart on the next (`|:`), and re-formed, several times
  // per row.
  final lastNewline = source.lastIndexOf('\n');
  final lastLine = source.substring(lastNewline + 1);
  if (lastLine.trimLeft().startsWith('|')) {
    var holdIndex = lastNewline + 1;
    if (lastNewline >= 0 && _partialTableSeparator.hasMatch(lastLine.trim())) {
      final prevNewline = source.lastIndexOf('\n', lastNewline - 1);
      final prevLine = source.substring(prevNewline + 1, lastNewline);
      if (prevLine.trimLeft().startsWith('|')) {
        holdIndex = prevNewline + 1;
      }
    }
    holdAt(holdIndex, markupDelimiterHold);
  }

  // Single-`$` maths, only when the caller treats `$…$` as maths at all —
  // to everyone else a dollar is a dollar.
  if (holdMathDollars) {
    holdAt(_lastUnpairedDollar(rest), markupDelimiterHold);
  }

  // A trailing character that is only the first half of an opener: `\` may
  // become `\(` and `<` may become `<u>`. Un-held it is shown, revealed, and
  // then vanishes when the second half lands — the one leak the rules above
  // cannot see. The very next character decides, so this holds a couple of
  // characters at most and cannot stall.
  final partial = _partialTrailingOpener.firstMatch(source);
  if (partial != null) {
    holdAt(partial.start, proseDelimiterHold);
  }

  return limit;
}

/// A trailing `\`, `<`, `<u`, `</` or `</u` — an opener the next character
/// may complete.
final RegExp _partialTrailingOpener = RegExp(r'(\\|</?u?)$');

/// A table delimiter row still arriving: only pipes, colons, dashes, spaces.
final RegExp _partialTableSeparator = RegExp(r'^\|[\s|:\-]*$');

/// Blanks list-bullet stars and thematic-break lines out of the emphasis
/// scanner's view, offsets preserved.
String _maskLineMarkers(String text) {
  if (!text.contains('*')) {
    return text;
  }
  final units = text.codeUnits.toList();
  var lineStart = 0;
  void maskLine(int end) {
    var i = lineStart;
    while (i < end && (units[i] == 0x20 || units[i] == 0x09)) {
      i += 1;
    }
    if (i >= end || units[i] != 0x2A /* * */ ) {
      lineStart = end + 1;
      return;
    }
    // `* item` — a bullet: blank the star alone.
    if (i + 1 < end && (units[i + 1] == 0x20 || units[i + 1] == 0x09)) {
      units[i] = 0x20;
      lineStart = end + 1;
      return;
    }
    // `***` (or `* * *`) — a thematic break: blank the whole line.
    var markers = 0;
    var j = i;
    while (j < end) {
      final c = units[j];
      if (c == 0x2A || c == 0x2D /* - */ || c == 0x5F /* _ */ ) {
        markers += 1;
      } else if (c != 0x20 && c != 0x09) {
        lineStart = end + 1;
        return;
      }
      j += 1;
    }
    if (markers >= 3) {
      for (var k = i; k < end; k++) {
        units[k] = 0x20;
      }
    }
    lineStart = end + 1;
  }

  for (var i = 0; i < units.length; i++) {
    if (units[i] == 0x0A) {
      maskLine(i);
    }
  }
  maskLine(units.length);
  return String.fromCharCodes(units);
}

/// Index of the last unpaired single `$`, ignoring every `$$` and every
/// escaped `\$`.
int _lastUnpairedDollar(String text) {
  var count = 0;
  var last = -1;
  var i = 0;
  while (i < text.length) {
    if (text.codeUnitAt(i) != 0x24 /* $ */ ) {
      i += 1;
      continue;
    }
    if (i > 0 && text.codeUnitAt(i - 1) == 0x5C /* \ */ ) {
      i += 1;
      continue;
    }
    if (i + 1 < text.length && text.codeUnitAt(i + 1) == 0x24) {
      i += 2;
      continue;
    }
    // `$5` is a price. Model-emitted maths opens with a letter or a command
    // (`$x$`, `$\frac…`); holding a digit-led dollar mostly withholds money.
    final next = i + 1 < text.length ? text.codeUnitAt(i + 1) : -1;
    if (next >= 0x30 && next <= 0x39) {
      i += 1;
      continue;
    }
    count += 1;
    last = i;
    i += 1;
  }
  return count.isOdd ? last : -1;
}

/// Index of the last unpaired [token], or -1.
int _lastUnpaired(String text, String token) {
  var count = 0;
  var last = -1;
  var i = text.indexOf(token);
  while (i != -1) {
    count += 1;
    last = i;
    i = text.indexOf(token, i + token.length);
  }
  return count.isOdd ? last : -1;
}

/// Index of the last unpaired single `*`, ignoring every `**`.
int _lastUnpairedStar(String text) {
  var count = 0;
  var last = -1;
  var i = 0;
  while (i < text.length) {
    if (text.codeUnitAt(i) != 0x2A /* * */ ) {
      i += 1;
      continue;
    }
    if (i + 1 < text.length && text.codeUnitAt(i + 1) == 0x2A) {
      i += 2;
      continue;
    }
    count += 1;
    last = i;
    i += 1;
  }
  return count.isOdd ? last : -1;
}
