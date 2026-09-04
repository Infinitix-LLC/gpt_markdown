/// Inline parser: turns a run of text into inline [MdNode]s (bold, italic,
/// code, links, images, LaTeX, source tags, …). Single forward pass over the
/// characters; emphasis content is parsed recursively. Ported 1:1 from the
/// Rust plusparse inline parser, using code-unit scanning and `indexOf`
/// instead of a char vector (all delimiters are ASCII, so this is safe and
/// fast on Dart's UTF-16 strings).
library;

import 'dart:typed_data';

import 'ast.dart';

const int _bang = 0x21; // '!'
const int _openBracket = 0x5B; // '['
const int _star = 0x2A; // '*'
const int _tilde = 0x7E; // '~'
const int _backtick = 0x60; // '`'
const int _lt = 0x3C; // '<'
const int _backslash = 0x5C; // '\'
const int _dollar = 0x24; // '$'
const int _openParen = 0x28; // '('
const int _closeBracket = 0x5D; // ']'
const int _closeParen = 0x29; // ')'
const int _pipe = 0x7C; // '|'

/// Code units that can begin an inline construct.
///
/// Everything else is ordinary text, and the parser's only job for it is to
/// copy it through. Testing that with a table lets a run of plain prose be
/// found with one comparison per character and copied with a single
/// `substring`, instead of running the whole construct dispatch on every
/// character and appending them one at a time — which is most of the work in
/// the common case, because most of a reply is prose.
///
/// A table rather than a bitmask: Dart's web targets have no 64-bit integers,
/// and a mask over the ASCII range would need them.
final Uint8List _inlineTriggers = () {
  final table = Uint8List(128);
  for (final unit in <int>[
    _bang,
    _dollar,
    _star,
    _lt,
    _openBracket,
    _backslash,
    _backtick,
    _tilde,
  ]) {
    table[unit] = 1;
  }
  return table;
}();

/// Whether [unit] can begin an inline construct.
///
/// Non-ASCII never can — every delimiter in the dialect is ASCII — so the
/// bounds check doubles as the answer for the whole of Unicode above 127.
bool _canStartConstruct(int unit) => unit < 128 && _inlineTriggers[unit] == 1;

List<MdNode> parseInline(String text, bool useDollar) {
  final n = text.length;

  // Most runs of an assistant's prose contain no markup at all. Finding that
  // out costs one scan, and skips the buffer, the delimiter tables and the
  // dispatch loop entirely.
  var plainUntil = 0;
  while (plainUntil < n && !_canStartConstruct(text.codeUnitAt(plainUntil))) {
    plainUntil += 1;
  }
  if (plainUntil == n) {
    return n == 0 ? <MdNode>[] : <MdNode>[MdText(text: text)];
  }

  final delims = _Delims(text);
  final nodes = <MdNode>[];
  final buf = StringBuffer();
  var i = 0;

  void flush() {
    if (buf.isNotEmpty) {
      nodes.add(MdText(text: buf.toString()));
      buf.clear();
    }
  }

  while (i < n) {
    final c = text.codeUnitAt(i);

    // Fast path: a run of characters that cannot begin a construct is copied
    // through in one piece. This is the bulk of ordinary prose, and skipping
    // the dispatch chain for it is what keeps the parser's cost close to a
    // scan.
    if (!_canStartConstruct(c)) {
      var j = i + 1;
      while (j < n && !_canStartConstruct(text.codeUnitAt(j))) {
        j += 1;
      }
      buf.write(text.substring(i, j));
      i = j;
      continue;
    }

    var matched = false;

    // ![alt](url)
    if (c == _bang &&
        i + 1 < n &&
        text.codeUnitAt(i + 1) == _openBracket &&
        delims.bracket.containsKey(i + 1)) {
      final r = _tryImage(text, i, delims);
      if (r != null) {
        flush();
        nodes.add(r.node);
        i = r.next;
        matched = true;
      }
    }

    // [text](url)  or  [123] source tag
    if (!matched && c == _openBracket) {
      final link = _tryLink(text, i, useDollar, delims);
      if (link != null) {
        flush();
        nodes.add(link.node);
        i = link.next;
        matched = true;
      } else {
        final tag = _trySourceTag(text, i);
        if (tag != null) {
          flush();
          nodes.add(tag.node);
          i = tag.next;
          matched = true;
        }
      }
    }

    // **bold**  /  *italic*
    if (!matched && c == _star) {
      // Emphasis is decided by the length of the *run* of asterisks, not by
      // the first one. Reading `***both***` as `**` starting at the second
      // asterisk left a stray `*` inside the bold, and closing a single `*`
      // with `indexOf('*')` landed on the opening half of a nested `**`, which
      // dropped the bold and cut the italic into pieces.
      var run = 1;
      while (i + run < n && text.codeUnitAt(i + run) == _star) {
        run += 1;
      }

      // `***x***` is both.
      if (run >= 3) {
        final close = _nextStarRun(text, i + run, 3);
        if (close != -1) {
          final inner = text.substring(i + 3, close);
          if (inner.trim().isNotEmpty) {
            flush();
            nodes.add(
              MdBold(
                children: [MdItalic(children: parseInline(inner, useDollar))],
              ),
            );
            i = close + 3;
            matched = true;
          }
        }
      }
      if (!matched && run == 2) {
        final close = _nextStarRun(text, i + 2, 2);
        if (close != -1) {
          final inner = text.substring(i + 2, close);
          if (inner.trim().isNotEmpty) {
            flush();
            nodes.add(MdBold(children: parseInline(inner, useDollar)));
            i = close + 2;
            matched = true;
          }
        }
      }
      if (!matched && run == 1) {
        // Only a lone asterisk closes an italic; a `**` inside it opens a
        // bold, which the recursive parse below then claims.
        final close = _nextStarRun(text, i + 1, 1, exact: true);
        if (close != -1) {
          final inner = text.substring(i + 1, close);
          if (inner.trim().isNotEmpty) {
            flush();
            nodes.add(MdItalic(children: parseInline(inner, useDollar)));
            i = close + 1;
            matched = true;
          }
        }
      }
    }

    // ~~strike~~
    if (!matched &&
        c == _tilde &&
        i + 1 < n &&
        text.codeUnitAt(i + 1) == _tilde) {
      final end = text.indexOf('~~', i + 2);
      if (end != -1) {
        flush();
        nodes.add(
          MdStrike(
            children: parseInline(text.substring(i + 2, end), useDollar),
          ),
        );
        i = end + 2;
        matched = true;
      }
    }

    // `code`
    if (!matched && c == _backtick) {
      final end = text.indexOf('`', i + 1);
      if (end != -1) {
        flush();
        nodes.add(MdInlineCode(text: text.substring(i + 1, end)));
        i = end + 1;
        matched = true;
      }
    }

    // <u>underline</u>
    if (!matched && c == _lt && text.startsWith('<u>', i)) {
      final end = text.indexOf('</u>', i + 3);
      if (end != -1) {
        flush();
        nodes.add(
          MdUnderline(
            children: parseInline(text.substring(i + 3, end), useDollar),
          ),
        );
        i = end + 4;
        matched = true;
      }
    }

    // \[ block latex \] in an inline position.
    //
    // The block parser claims `\[` only when it opens a line, so block maths
    // written mid-sentence — or after a list marker, `1. Result: \[ x^2 \]` —
    // used to survive as literal text. The syntax is recognised wherever it
    // appears; it still renders as a block, because that is what it is.
    if (!matched &&
        c == _backslash &&
        i + 1 < n &&
        text.codeUnitAt(i + 1) == _openBracket) {
      final end = text.indexOf('\\]', i + 2);
      if (end != -1) {
        flush();
        nodes.add(MdBlockLatex(tex: text.substring(i + 2, end).trim()));
        i = end + 2;
        matched = true;
      }
    }

    // \( inline latex \)
    if (!matched &&
        c == _backslash &&
        i + 1 < n &&
        text.codeUnitAt(i + 1) == _openParen) {
      final end = text.indexOf('\\)', i + 2);
      if (end != -1) {
        flush();
        nodes.add(MdInlineLatex(tex: text.substring(i + 2, end).trim()));
        i = end + 2;
        matched = true;
      }
    }

    // $$ … $$  /  $ … $  (only when enabled)
    if (!matched && useDollar && c == _dollar) {
      if (i + 1 < n && text.codeUnitAt(i + 1) == _dollar) {
        final end = text.indexOf(r'$$', i + 2);
        if (end != -1) {
          flush();
          nodes.add(MdInlineLatex(tex: text.substring(i + 2, end).trim()));
          i = end + 2;
          matched = true;
        }
      }
      if (!matched) {
        final end = text.indexOf(r'$', i + 1);
        if (end != -1) {
          final inner = text.substring(i + 1, end);
          if (inner.trim().isNotEmpty) {
            flush();
            nodes.add(MdInlineLatex(tex: inner.trim()));
            i = end + 1;
            matched = true;
          }
        }
      }
    }

    // \| — the GFM escape for a literal pipe. Table cells are split before
    // this runs (see _splitPipes in block_parser.dart), which is what lets a
    // pipe reach a cell at all; here the backslash is dropped so the reader
    // sees `|`. Only `|` is unescaped: a general \X rule would change how
    // \*, \_ and friends render across every document.
    if (!matched &&
        c == _backslash &&
        i + 1 < n &&
        text.codeUnitAt(i + 1) == _pipe) {
      buf.writeCharCode(_pipe);
      i += 2;
      matched = true;
    }

    if (!matched) {
      buf.writeCharCode(c);
      i += 1;
    }
  }

  flush();
  return nodes;
}

typedef _InlineMatch = ({MdNode node, int next});

/// Delimiter positions, resolved once per parse.
///
/// A `_try*` that scans forward for its closer is O(n) per opener, so text
/// made of unmatched or nested openers — `[[[[[[`, `[a](` repeated — costs
/// O(n²). Both tables below are built in one pass with a stack, which makes
/// every lookup O(1) and the whole parse linear.
class _Delims {
  _Delims(this.text);

  final String text;

  Map<int, int>? _bracket;
  Map<int, int>? _paren;

  /// Index of `[` to index of its matching `]`.
  ///
  /// Built on first use: most runs of text contain no brackets at all, and
  /// paying for the table there costs more than it saves.
  Map<int, int> get bracket {
    _ensurePairs();
    return _bracket!;
  }

  /// Index of `(` to index of its matching `)`.
  Map<int, int> get paren {
    _ensurePairs();
    return _paren!;
  }

  /// Fills both tables in one pass.
  ///
  /// Separately they are two scans of the same string, and the constructs
  /// that consult one — links, images — almost always go on to consult the
  /// other, so the second scan was rarely avoided anyway.
  void _ensurePairs() {
    if (_bracket != null) {
      return;
    }
    final brackets = <int, int>{};
    final parens = <int, int>{};
    final bracketStack = <int>[];
    final parenStack = <int>[];
    for (var i = 0; i < text.length; i++) {
      final c = text.codeUnitAt(i);
      if (c == _backslash) {
        i += 1;
        continue;
      }
      switch (c) {
        case _openBracket:
          bracketStack.add(i);
        case _closeBracket:
          if (bracketStack.isNotEmpty) {
            brackets[bracketStack.removeLast()] = i;
          }
        case _openParen:
          parenStack.add(i);
        case _closeParen:
          if (parenStack.isNotEmpty) {
            parens[parenStack.removeLast()] = i;
          }
      }
    }
    _bracket = brackets;
    _paren = parens;
  }
}

/// Start of the next run of asterisks at or after [from].
///
/// With [exact] the run must be exactly [length] long — how an italic finds
/// its closer, since a `**` in the middle opens a bold rather than closing the
/// italic. Otherwise the run must be at least [length].
int _nextStarRun(String text, int from, int length, {bool exact = false}) {
  var i = from;
  while (i < text.length) {
    if (text.codeUnitAt(i) != _star) {
      i += 1;
      continue;
    }
    var run = 1;
    while (i + run < text.length && text.codeUnitAt(i + run) == _star) {
      run += 1;
    }
    if (exact ? run == length : run >= length) {
      return i;
    }
    i += run;
  }
  return -1;
}

_InlineMatch? _tryImage(String text, int i, _Delims delims) {
  final n = text.length;
  final j0 = delims.bracket[i + 1]; // past '!'
  if (j0 == null) {
    return null;
  }
  var j = j0 + 1; // past ']'
  if (j >= n || text.codeUnitAt(j) != _openParen) {
    return null;
  }
  final close = delims.paren[j];
  if (close == null) {
    return null;
  }
  // Sliced only now that the whole shape has matched. Slicing before the
  // check copies the label of every unmatched `[` in the document.
  final alt = text.substring(i + 2, j0);
  final url = text.substring(j + 1, close);
  final size = _parseImageSize(alt);
  return (
    node: MdImage(
      url: url.trim(),
      alt: alt,
      width: size.width,
      height: size.height,
    ),
    next: close + 1,
  );
}

/// Parse an alt text of the form `WxH` (e.g. `100x200`, `100x`, `x200`).
({double? width, double? height}) _parseImageSize(String alt) {
  final t = alt.trim();
  final x = t.indexOf('x');
  if (x != -1) {
    final a = t.substring(0, x);
    final b = t.substring(x + 1);
    final aOk = a.isNotEmpty && _allAsciiDigits(a);
    final bOk = b.isNotEmpty && _allAsciiDigits(b);
    if ((aOk || a.isEmpty) && (bOk || b.isEmpty) && (aOk || bOk)) {
      return (
        width: aOk ? double.tryParse(a) : null,
        height: bOk ? double.tryParse(b) : null,
      );
    }
  }
  return (width: null, height: null);
}

bool _allAsciiDigits(String s) {
  for (var i = 0; i < s.length; i++) {
    final c = s.codeUnitAt(i);
    if (c < 0x30 || c > 0x39) {
      return false;
    }
  }
  return true;
}

_InlineMatch? _tryLink(String text, int i, bool useDollar, _Delims delims) {
  final n = text.length;
  final j0 = delims.bracket[i];
  if (j0 == null) {
    return null;
  }
  var j = j0 + 1; // past ']'
  if (j >= n || text.codeUnitAt(j) != _openParen) {
    return null;
  }
  final close = delims.paren[j];
  if (close == null) {
    return null;
  }
  // Sliced only now that the whole shape has matched. Slicing before the
  // check copies the label of every unmatched `[` in the document.
  final linkText = text.substring(i + 1, j0);
  final url = text.substring(j + 1, close);
  return (
    node: MdLink(children: parseInline(linkText, useDollar), url: url.trim()),
    next: close + 1,
  );
}

_InlineMatch? _trySourceTag(String text, int i) {
  final n = text.length;
  var j = i + 1; // past '['
  final start = j;
  while (j < n) {
    final c = text.codeUnitAt(j);
    if (c < 0x30 || c > 0x39) {
      break;
    }
    j += 1;
  }
  if (j == start || j >= n || text[j] != ']') {
    return null;
  }
  return (node: MdSourceTag(id: text.substring(start, j)), next: j + 1);
}
