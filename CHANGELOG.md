## 1.1.4

- 🔧 Fixed iOS build failure by updating `flutter_math_fork` dependency to ^0.7.4
- 📱 Improved Flutter 3.35.2 compatibility for iOS builds
- 🚀 Resolved dependency conflicts that prevented iOS compilation

o ## 1.1.3

- Added `RadioGroup` widget for managing radio buttons.
- Updated to align with Flutter 3.35 by resolving the deprecations of `Radio.groupValue` and `Radio.onChanged`.

## 1.1.2

- 📊 Fixed table column alignment support ([#65](https://github.com/Infinitix-LLC/gpt_markdown/issues/65))
- 🎨 Added `tableBuilder` parameter to customize table rendering
- 🔗 Fixed text decoration color of link markdown component

## 1.1.1

- 🖼️ Fixed issue where images wrapped in links (e.g. `[![](img)](url)`) were not rendering properly (#72)
- 🔗 Resolved parsing errors for consecutive inline links without spacing (e.g. `[a](url)[b](url)`) (#34)

## 1.1.0

- Changed `onLinkTab` to `onLinkTap` fixed issues of newLine issues.

## 1.0.20

- Fix: support balanced parentheses in image and link URLs. [#68](https://github.com/Infinitix-LLC/gpt_markdown/pull/68)

## 1.0.19

- Performance improvements.

## 1.0.18

- dollarSignForLatex is added and by default it is false.

## 1.0.17

- Bloc components rendering inside table.

## 1.0.16

- `IndentMd` and `BlockQuote` fixed.
- Baseline of bloc type component is fixed.
- block quote support improved.
- custom components support added.
- `Table` syntax improved.

## 1.0.15

- Performance improvements.

## 1.0.14

- Added `orderedListBuilder` and `unOrderedListBuilder` parameters to customize list rendering.

## 1.0.13

- Fixed issue [#49](https://github.com/Infinitix-LLC/gpt_markdown/issues/49).

## 1.0.12

- imageBuilder parameter added.

## 1.0.11

- dart format.

## 1.0.10

- pubspec flutter version updated.

## 1.0.9

- Fixed issues with flutter 3.29.0.
- Fixed > syntax render issue.

## 1.0.8

- Extra lines inside block latex removed and $$..$$ syntax works with \(..\) syntax.

## 1.0.7

- `closed` parameter added to `codeBuilder`.

## 1.0.6

- `_italic_` and `>Indentation` syntax added.
- `linkBuilder` and `highlightBuilder` added [f45132b](https://github.com/Infinitix-LLC/gpt_markdown/commit/f45132b2cd4b069d3e5703561deb5c7e51d3c560).

## 1.0.5

- Fixed the order of inline and block latex in markdown.

## 1.0.4

- Fixing latex issue for block syntax.

## 1.0.3

- Multiline latex syntax bug fix.

## 1.0.2

- Readme updated.

## 1.0.1

- Indentation fixed
- `ATag` syntax fixed
- Documentation improved in readme and example.

## 1.0.0

- `TexMarkdown` is renamed to `GptMarkdown`.
- `h1` to `h6` style added to `GptMarkdownThemeData` class.
- `hrLineThickness` value added to `GptMarkdownThemeData` class.
- `hrLineColor` Color added to `GptMarkdownThemeData` class.
- `linkColor` Color added to `GptMarkdownThemeData` class.
- `linkHoverColor` Color added to `GptMarkdownThemeData` class.
- Indentation improved.
- Math equations are now default selectable.
- `SelectableAdapter` Widget added to make any widget selectable.

## 0.1.15

- `CodeBlock` is moved out of `gpt_markdown.dart` library.

## 0.1.14

- Changed `withOpacity` to `withAlpha` in `theme.dart` for highlightColor.

## 0.1.13

- `GptMarkdownTheme` and `GptMarkdownThemeData` class moved to `gpt_markdown.dart` library.

## 0.1.12

- Fixed the indentation syntex of regex.

## 0.1.11

- `GptMarkdownTheme` and `GptMarkdownThemeData` classes added.

## 0.1.10

- components are now selectable.

## 0.1.9

- source config added.

## 0.1.8

- unordered list bullet color fixed.

## 0.1.7

- ordered list color fixed.

## 0.1.6

- `overflow` perameter added.

## 0.1.5

- Some color changes and highlighted text style changed.

## 0.1.4

- `[source]` format added.

## 0.1.3

- `maxLines` Parameter added.

## 0.1.2

- `textStyle` Parameter added to the latexBuilder function.

## 0.1.1

- Fixed hitTest essue.

## 0.1.0

- Inline Latex Builder added and Link are now Clickable and Latex Error Color changed to null for debug mode.

- `textScaleFector` is removed and `textScaler` added

## 0.0.12

- codeBuilder method added [[#6](https://github.com/saminsohag/flutter_packages/issues/6)], and maked the table scrollable.

## 0.0.11

- New syntex added for codes and highlight.

## 0.0.10

- `$$_$$` syntex fixes.

## 0.0.9

- `$_$` syntex added for latex with a gard condition for `\(_\)`.

## 0.0.8

- `$_$` syntex added for latex with a gard condition for `\(_\)`.

## 0.0.6

- Fixed textScaler problem by removeing that and added textScaleFector.

## 0.0.5

- Latex table workarround added.

## 0.0.4

- Customizable latex and workarround added.

## 0.0.3

- Some latex related fixes.

## 0.0.2

- TextScaler and TextAlign added.

## 0.0.1

- This package will render response of chatGPT in flutter app.
