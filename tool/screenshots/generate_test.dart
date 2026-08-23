// Generates the README showcase images.
//
// Not a test: it renders the package into PNGs. It lives under `tool/` so
// `flutter test` does not pick it up with the real suite, and it runs through
// the test harness only because that is the supported way to rasterise a
// Flutter widget to a file without opening a window.
//
// Run it with `./scripts/screenshots.sh`.
@Timeout(Duration(minutes: 2))
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

import 'fonts.dart';

/// Where the images land, relative to this file.
const _out = '../../screenshots';

/// One card's worth of Markdown.
///
/// Kept deliberately small. A screenshot is read in about a second, so every
/// line has to earn its place — these show one capability each, in content a
/// reader understands without stopping to parse it.
const _scenes = <String, String>{
  'rich-text': """
# Weekly update

Shipping **v1.2** on Friday — a *small* release. The old `highlightBuilder` is ~~gone~~ deprecated, not removed.

- Faster streaming, with a cached settled prefix
- Friendlier tables with aligned columns
  - Nested items keep their indent
- See the [full changelog](https://pub.dev) for the rest

> One widget renders every line of this, including the quote.

---

Autolinks work too: https://pub.dev/packages/gpt_markdown
""",
  'math': r"""
### Physics homework

Einstein's relation is \(E = mc^2\), and the area under a parabola is

\[ \int_0^1 x^2\,dx = \frac{1}{3} \]

The quadratic formula, for **any** \(ax^2 + bx + c = 0\):

\[ x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a} \]

- Sums render inline: \(\sum_{i=1}^{n} i = \frac{n(n+1)}{2}\)
- So do fractions: \(\frac{22}{7} \approx \pi\)

Equations sit on the text baseline, so a line never jumps.
""",
  'tables': """
### Sales by region

| Region | Units | Change |
|:-------|------:|:------:|
| North  |   120 |   +8%  |
| South  |    94 |   −3%  |
| East   |   167 |  +12%  |
| West   |    58 |   +1%  |

Columns follow the alignment row — left, right, centre.

| Cell content | Works |
|:-------------|:------|
| **bold** and *italic* | yes |
| `inline code` | yes |
| [links](https://pub.dev) | yes |
""",
  'code': """
### Getting started

Add the package, then render a reply with `GptMarkdown`:

```bash
flutter pub add gpt_markdown
```

```dart
GptMarkdown(
  reply,
  onLinkTap: open,
  isStreaming: true,
  animation: GptMarkdownAnimation.fade,
);
```

Inline code like `TextSpan` and `PlaceholderAlignment.baseline` wraps across lines instead of overflowing.
""",
  'lists': """
### Today

- [x] Write the parser
- [x] Land the autolink fix
- [ ] Take the screenshots
- [ ] Ship 1.2.1

1. Ordered lists work
2. Numbers come from the text
3. Nested content is kept
   - including bullets
   - and **bold** items

Citations render as tags too [1]
""",
  'inline-patterns': """
### Standup

@ada shipped the parser fix :tada: — thread is in #design-review

- Fixed GH-6124, blank links on iOS
- @grace picks up tables next :rocket:
- Shortcodes become widgets, mentions become chips

> #2959 stays plain text, because only known names match.

Your app supplies the names and the builder; the package supplies the matching.
""",
};

/// Logical width of one card. About a phone's worth, so the wrapping in the
/// image matches what a reader will see in their own app.
const _cardWidth = 420.0;
const _gap = 24.0;
const _pagePadding = 32.0;

void main() {
  setUpAll(loadShowcaseFonts);

  for (final scene in _scenes.entries) {
    testWidgets(scene.key, (tester) async {
      const width = _pagePadding * 2 + _cardWidth * 2 + _gap;
      tester.view.physicalSize = const Size(width * 2, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_Showcase(markdown: scene.value));
      await tester.pumpAndSettle();
      // Overflow complaints from a deliberately narrow card are noise here.
      while (tester.takeException() != null) {}

      await expectLater(
        find.byKey(_Showcase.frameKey),
        matchesGoldenFile('$_out/${scene.key}.png'),
      );
    });
  }
}

/// Channels, people and shortcodes this showcase knows about.
///
/// Nothing generic is matched: `#2959` in the standup scene stays plain text
/// precisely because it is not in this list. That is the package's advice
/// rendered as a picture.
const _channels = ['design-review', 'general'];
const _people = ['ada', 'grace', 'linus'];
const _shortcodes = <String, IconData>{
  'tada': Icons.celebration_rounded,
  'rocket': Icons.rocket_launch_rounded,
};

/// The inline syntax an app layers on top of Markdown.
///
/// Applied to every scene. Only the names above match, so the other scenes are
/// untouched — which is the whole point of leaving `genericTokenPattern` null.
List<InlinePattern> _showcasePatterns(BuildContext context) {
  final colors = Theme.of(context).colorScheme;

  return [
    InlinePattern.prefixed(
      prefix: '#',
      knownNames: _channels,
      builder:
          (context, match, style) => _chipSpan(
            icon: Icons.tag_rounded,
            label: _withoutPrefix(match.group(0)),
            style: style,
            background: colors.primaryContainer,
            foreground: colors.onPrimaryContainer,
          ),
    ),
    InlinePattern.prefixed(
      prefix: '@',
      knownNames: _people,
      builder:
          (context, match, style) => _chipSpan(
            icon: Icons.alternate_email_rounded,
            label: _withoutPrefix(match.group(0)),
            style: style,
            background: colors.tertiaryContainer,
            foreground: colors.onTertiaryContainer,
          ),
    ),
    // Shortcodes resolve to icons rather than emoji: a test renderer has no
    // emoji font, so a glyph would come out as an empty box.
    InlinePattern.delimited(
      open: ':',
      knownNames: _shortcodes.keys,
      builder: (context, match, style) {
        final name = match.namedGroup('name');
        final icon = name == null ? null : _shortcodes[name];
        if (icon == null) {
          return TextSpan(text: match.group(0), style: style);
        }
        return WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Icon(
            icon,
            size: (style.fontSize ?? 14) * 1.1,
            color: colors.primary,
          ),
        );
      },
    ),
    // A TextSpan, so it stays selectable and wraps with the paragraph.
    InlinePattern(
      pattern: RegExp(r'(?<![\w-])GH-(\d+)\b'),
      builder:
          (context, match, style) => TextSpan(
            text: match.group(0),
            style: style.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
    ),
  ];
}

/// Drops the `#` or `@` a prefixed pattern matched along with the name.
String _withoutPrefix(String? token) {
  if (token == null || token.isEmpty) {
    return '';
  }
  return token.substring(1);
}

/// A rounded chip that sits on the surrounding text baseline.
InlineSpan _chipSpan({
  required IconData icon,
  required String label,
  required TextStyle style,
  required Color background,
  required Color foreground,
}) {
  final size = style.fontSize ?? 14;
  return WidgetSpan(
    alignment: PlaceholderAlignment.baseline,
    baseline: TextBaseline.alphabetic,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: size * 0.9, color: foreground),
          const SizedBox(width: 3),
          Text(
            label,
            style: style.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    ),
  );
}

/// The light and dark cards, side by side on a soft page.
class _Showcase extends StatelessWidget {
  const _Showcase({required this.markdown});

  static const frameKey = ValueKey('showcase-frame');

  final String markdown;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, fontFamily: 'Roboto'),
      home: Align(
        alignment: Alignment.topLeft,
        child: RepaintBoundary(
          key: frameKey,
          child: Container(
            padding: const EdgeInsets.all(_pagePadding),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF1F3F6), Color(0xFFDFE3E9)],
              ),
            ),
            // No IntrinsicHeight: it forces a dry layout, which RenderTable
            // and the equation renderer both refuse. Both cards hold the same
            // content, so their heights already agree.
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _Card(markdown: markdown, brightness: Brightness.light),
                const SizedBox(width: _gap),
                _Card(markdown: markdown, brightness: Brightness.dark),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A single themed card, drawn as a small window so the two themes read as the
/// same app rather than as two unrelated pictures.
class _Card extends StatelessWidget {
  const _Card({required this.markdown, required this.brightness});

  final String markdown;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final isDark = brightness == Brightness.dark;
    final theme = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'Roboto',
      extensions: [GptMarkdownThemeData(brightness: brightness)],
    );
    final surface = theme.colorScheme.surface;

    return SizedBox(
      width: _cardWidth,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Color(isDark ? 0x38000000 : 0x14101828),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Theme(
            data: theme,
            child: Material(
              color: surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _TitleBar(brightness: brightness),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
                    child: GptMarkdown(
                      markdown,
                      inlinePatterns: _showcasePatterns(context),
                      // The code block's copy button resolves to a null font
                      // family, so `flutter test` draws its label in the test
                      // font — a row of filled boxes. A reader's device draws
                      // it properly, but the screenshot cannot, so the header
                      // shows the language label alone.
                      styleSheet: const GptMarkdownStyleSheet(
                        codeBlock: CodeBlockStyle(showCopyButton: false),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Three dots and a hairline — enough for the eye to read "app window"
/// without adding anything to interpret.
class _TitleBar extends StatelessWidget {
  const _TitleBar({required this.brightness});

  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final isDark = brightness == Brightness.dark;
    final dot = Color(isDark ? 0x33FFFFFF : 0x22000000);
    final line = Color(isDark ? 0x1FFFFFFF : 0x14000000);

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: line)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < 3; i++) ...[
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            if (i < 2) const SizedBox(width: 7),
          ],
        ],
      ),
    );
  }
}
