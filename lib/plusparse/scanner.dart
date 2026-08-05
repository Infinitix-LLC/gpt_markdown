/// Low-level, single-pass line helpers shared by the block parser. No regex —
/// everything is hand-written character scanning (ported 1:1 from the Rust
/// plusparse scanner).
library;

const int _space = 0x20; // ' '
const int _tab = 0x09; // '\t'
const int _hash = 0x23; // '#'
const int _zero = 0x30; // '0'
const int _nine = 0x39; // '9'

/// Number of leading-indent columns (space = 1, tab = 4).
int indentWidth(String line) {
  var w = 0;
  for (var i = 0; i < line.length; i++) {
    final c = line.codeUnitAt(i);
    if (c == _space) {
      w += 1;
    } else if (c == _tab) {
      w += 4;
    } else {
      break;
    }
  }
  return w;
}

/// Remove up to [max] columns of leading indentation, returning the remainder.
String stripIndent(String line, int max) {
  var removed = 0;
  var idx = 0;
  while (idx < line.length && removed < max) {
    final c = line.codeUnitAt(idx);
    if (c == _space) {
      removed += 1;
      idx += 1;
    } else if (c == _tab) {
      removed += 4;
      idx += 1;
    } else {
      break;
    }
  }
  return line.substring(idx);
}

bool isBlank(String line) => line.trim().isEmpty;

/// ATX heading: 1–6 `#` followed by a space. Returns (level, content).
({int level, String content})? isHeading(String trimmed) {
  var level = 0;
  while (level < trimmed.length && trimmed.codeUnitAt(level) == _hash) {
    level += 1;
  }
  if (level >= 1 &&
      level <= 6 &&
      level < trimmed.length &&
      trimmed.codeUnitAt(level) == _space) {
    return (level: level, content: trimmed.substring(level + 1).trimRight());
  }
  return null;
}

/// Thematic break: 3+ of `-`, `*`, or `_` (optionally space-separated), or `⸻`.
bool isHr(String trimmed) {
  final t = trimmed.trim();
  if (t == '⸻') {
    return true;
  }
  if (t.isEmpty) {
    return false;
  }
  final first = t[0];
  if (first != '-' && first != '*' && first != '_') {
    return false;
  }
  var count = 0;
  for (var i = 0; i < t.length; i++) {
    final c = t[i];
    if (c == first) {
      count += 1;
    } else if (c == ' ') {
      continue;
    } else {
      return false;
    }
  }
  return count >= 3;
}

/// `- `, `* `, or `+ ` bullet. Returns the content after the marker.
String? unorderedMarker(String trimmed) {
  if (trimmed.length >= 2 && trimmed.codeUnitAt(1) == _space) {
    final c = trimmed[0];
    if (c == '-' || c == '*' || c == '+') {
      return trimmed.substring(2);
    }
  }
  return null;
}

/// `N. ` or `N) ` ordered marker. Returns (number, content).
({int number, String content})? orderedMarker(String trimmed) {
  var idx = 0;
  while (idx < trimmed.length) {
    final c = trimmed.codeUnitAt(idx);
    if (c < _zero || c > _nine) {
      break;
    }
    idx += 1;
  }
  if (idx == 0) {
    return null;
  }
  if (idx < trimmed.length &&
      (trimmed[idx] == '.' || trimmed[idx] == ')') &&
      idx + 1 < trimmed.length &&
      trimmed.codeUnitAt(idx + 1) == _space) {
    final num = int.tryParse(trimmed.substring(0, idx)) ?? 1;
    return (number: num, content: trimmed.substring(idx + 2));
  }
  return null;
}

/// `[x] ` / `[ ] ` checkbox. Returns (checked, content).
({bool checked, String content})? checkboxMarker(String trimmed) {
  if (trimmed.startsWith('[x] ') || trimmed.startsWith('[X] ')) {
    return (checked: true, content: trimmed.substring(4));
  }
  if (trimmed.startsWith('[ ] ')) {
    return (checked: false, content: trimmed.substring(4));
  }
  return null;
}

/// `(x) ` / `( ) ` radio. Returns (selected, content).
({bool selected, String content})? radioMarker(String trimmed) {
  if (trimmed.startsWith('(x) ') || trimmed.startsWith('(X) ')) {
    return (selected: true, content: trimmed.substring(4));
  }
  if (trimmed.startsWith('( ) ')) {
    return (selected: false, content: trimmed.substring(4));
  }
  return null;
}
