/// Inline parser: turns a run of text into inline [MdNode]s (bold, italic,
/// code, links, images, LaTeX, source tags, …). Single forward pass over the
/// characters; emphasis content is parsed recursively. Ported 1:1 from the
/// Rust plusparse inline parser, using code-unit scanning and `indexOf`
/// instead of a char vector (all delimiters are ASCII, so this is safe and
/// fast on Dart's UTF-16 strings).
library;

import '../gen_ui/gen_ui_markers.dart';
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


List<MdNode> parseInline(String text, bool useDollar) {
  final n = text.length;
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
    var matched = false;

    // ![alt](url)
    if (c == _bang && i + 1 < n && text.codeUnitAt(i + 1) == _openBracket) {
      final r = _tryImage(text, i);
      if (r != null) {
        flush();
        nodes.add(r.node);
        i = r.next;
        matched = true;
      }
    }

    // [text](url)  or  [123] source tag
    if (!matched && c == _openBracket) {
      final link = _tryLink(text, i, useDollar);
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

    // U+E200 genui U+E202 {...json...} U+E201. The markers are private-use
    // code points, so a payload may contain any markdown punctuation. No
    // closing marker yet (still streaming) leaves the text literal.
    if (!matched &&
        c == genUiOpenMarkerRune &&
        text.startsWith(genUiOpenMarker, i)) {
      final start = i + genUiOpenMarker.length;
      final end = text.indexOf(genUiCloseMarker, start);
      if (end != -1) {
        flush();
        nodes.add(MdGenUi(payload: text.substring(start, end)));
        i = end + genUiCloseMarker.length;
        matched = true;
      }
    }

    // **bold**  /  *italic*
    if (!matched && c == _star) {
      if (i + 1 < n && text.codeUnitAt(i + 1) == _star) {
        final end = text.indexOf('**', i + 2);
        if (end != -1) {
          flush();
          nodes.add(
            MdBold(
              children: parseInline(text.substring(i + 2, end), useDollar),
            ),
          );
          i = end + 2;
          matched = true;
        }
      }
      if (!matched) {
        final end = text.indexOf('*', i + 1);
        if (end != -1) {
          final inner = text.substring(i + 1, end);
          if (inner.trim().isNotEmpty) {
            flush();
            nodes.add(MdItalic(children: parseInline(inner, useDollar)));
            i = end + 1;
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

    if (!matched) {
      buf.writeCharCode(c);
      i += 1;
    }
  }

  flush();
  return nodes;
}

typedef _InlineMatch = ({MdNode node, int next});

_InlineMatch? _tryImage(String text, int i) {
  final n = text.length;
  var j = text.indexOf(']', i + 2); // past "!["
  if (j == -1) {
    return null;
  }
  final alt = text.substring(i + 2, j);
  j += 1; // past ']'
  if (j >= n || text.codeUnitAt(j) != _openParen) {
    return null;
  }
  final close = text.indexOf(')', j + 1);
  if (close == -1) {
    return null;
  }
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

_InlineMatch? _tryLink(String text, int i, bool useDollar) {
  final n = text.length;
  var j = text.indexOf(']', i + 1); // past '['
  if (j == -1) {
    return null;
  }
  final linkText = text.substring(i + 1, j);
  j += 1; // past ']'
  if (j >= n || text.codeUnitAt(j) != _openParen) {
    return null;
  }
  final close = text.indexOf(')', j + 1);
  if (close == -1) {
    return null;
  }
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
