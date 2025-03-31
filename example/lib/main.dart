import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:gpt_markdown/custom_widgets/selectable_adapter.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:watcher/watcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.dark;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.blue,
        extensions: [
          GptMarkdownThemeData(
            brightness: Brightness.light,
            highlightColor: Colors.red,
          ),
        ],
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.blue,
        extensions: [
          GptMarkdownThemeData(
            brightness: Brightness.dark,
            highlightColor: Colors.red,
          ),
        ],
      ),
      home: MyHomePage(
        title: 'GptMarkdown',
        onPressed: () {
          setState(() {
            _themeMode = (_themeMode == ThemeMode.dark)
                ? ThemeMode.light
                : ThemeMode.dark;
          });
        },
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.onPressed});
  final VoidCallback? onPressed;

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextDirection _direction = TextDirection.ltr;
  final TextEditingController _controller = TextEditingController(
    text: r'''
```markdown
# Complex Markdown Document for Testing

This document is designed to **challenge** your `gpt_markdown` package by incorporating a wide variety of Markdown components including headers, lists, tables, code blocks, blockquotes, footnotes, and LaTeX math expressions.

---

## Table of Contents
1. [Headers and Emphasis](#headers-and-emphasis)
2. [Lists](#lists)
3. [Code Blocks and Inline Code](#code-blocks-and-inline-code)
4. [Tables](#tables)
5. [Blockquotes and Nested Elements](#blockquotes-and-nested-elements)
6. [Mathematical Expressions](#mathematical-expressions)
7. [Links and Images](#links-and-images)
8. [Footnotes](#footnotes)
9. [Horizontal Rules and Miscellaneous](#horizontal-rules-and-miscellaneous)

---

## Headers and Emphasis

### Header Levels
Markdown supports multiple header levels:
- `# Header 1`
- `## Header 2`
- `### Header 3`
- `#### Header 4`
- `##### Header 5`
- `###### Header 6`

### Emphasis Examples
- *Italicized text* using single asterisks or underscores.
- **Bold text** using double asterisks or underscores.
- ***Bold and italic*** by combining them.
- ~~Strikethrough~~ text using two tildes.

---

## Lists

### Unordered List
- Item 1
  - Nested Item 1.1
  - Nested Item 1.2
    - Deeply Nested Item 1.2.1
- Item 2
  - [ ] Task not completed
  - [x] Task completed

### Ordered List
1. First item
2. Second item with nested list:
   1. Subitem 2.1
   2. Subitem 2.2
3. Third item

### Mixed List Example
- **Fruits**
  1. Apple
  2. Banana
  3. Cherry
- **Vegetables**
  - Carrot
  - Lettuce
  - Spinach

---

## Code Blocks and Inline Code

### Inline Code
Here is an example of inline code: `print("Hello, world!")`.

### Fenced Code Block (Python)
```python
def greet(name):
    """
    Greets a person with the provided name.
    """
    print(f"Hello, {name}!")

greet("Alice")
```

### Fenced Code Block (JavaScript)
```javascript
function greet(name) {
    console.log(`Hello, ${name}!`);
}
greet("Bob");
```

---

## Tables

Here is a table demonstrating various elements:

| Syntax      | Description                              | Example                           |
| ----------- | ---------------------------------------- | --------------------------------- |
| Header      | Title                                    | **Bold Header**                   |
| Paragraph   | Text with *italic* and **bold** elements | This is a sample paragraph.       |
| Inline Code | `code snippet`                           | `let x = 10;`                     |

Additional table with alignment:

| Left Align | Center Align | Right Align |
| :--------- |:------------:| ----------:|
| Row 1      | Row 1        | Row 1      |
| Row 2      | Row 2        | Row 2      |

---

## Blockquotes and Nested Elements

> **Blockquote Header**
> 
> This is a blockquote. You can include **bold** and *italic* text, as well as `inline code` within blockquotes.
> 
> > ### Nested Blockquote
> > - Nested list item 1
> > - Nested list item 2
> >   1. Numbered subitem 1
> >   2. Numbered subitem 2
> > 
> > ```python
> > # Code snippet inside nested blockquote
> > for i in range(3):
> >     print(i)
> > ```
> 
> Back to the outer blockquote.

---

## Mathematical Expressions

### Inline Math
You can write inline math using the `\( ... \)` syntax. For example, the quadratic formula is given by:
\( x = \frac{-b \pm \sqrt{b^2-4ac}}{2a} \).

### Display Math
Display math can be rendered using the `\[ ... \]` syntax. For example, consider the integral:
\[
\int_{-\infty}^{\infty} e^{-x^2} \, dx = \sqrt{\pi}
\]

More complex display equations:
\[
E = mc^2 \quad \text{and} \quad F = ma
\]

---

## Links and Images

### Links
Here are examples of links:
- [OpenAI](https://www.openai.com)
- [GitHub](https://github.com)

### Images
Inline images can be embedded as follows:
![Alt Text for Image](https://via.placeholder.com/150 "Image Title")

Images can also be referenced with links:
[![Linked Image](https://via.placeholder.com/100 "Thumbnail")](https://via.placeholder.com/500 "Full Image")

---

## Footnotes

Here is a statement with a footnote.[^1] Another reference can be added here.[^long]

[^1]: This is a simple footnote.
[^long]: This footnote contains a longer explanation to showcase how multiple lines can be formatted in a footnote. It supports Markdown formatting such as **bold** and *italic* text.

---

## Horizontal Rules and Miscellaneous

Horizontal rules can be used to separate sections:

---

### Task List Example
- [x] Write complex Markdown document
- [x] Include LaTeX math expressions
- [ ] Add more Markdown components if needed

### Nested Quotes with Code and Math
> **Example of Nested Components**
> 
> - Inline code: `sum = a + b`
> - Math expression: \( \sum_{i=1}^n i = \frac{n(n+1)}{2} \)
> - More text with **bold** formatting.
> 
> ```javascript
> // JavaScript code example inside a nested blockquote
> const sum = (n) => (n * (n + 1)) / 2;
> console.log(sum(10));
> ```

---

## Conclusion

This document was created to test the robustness of Markdown parsers and to ensure that all components, including advanced LaTeX expressions and nested structures, are rendered correctly. Enjoy testing and feel free to extend it further!
```
''',
  );
  File? file;

  loadContent() async {
    File? file = this.file;
    if (file == null) {
      return;
    }
    String content = await file.readAsString();
    _controller.text = content;
  }

  updateContent(String contents) async {
    //
    await file?.writeAsString(contents);
  }

  load() async {
    await loadContent();
    String? path = file?.path;
    if (path == null) {
      return;
    }
    FileWatcher(path).events.listen((details) {
      loadContent();
    });
  }

  bool writingMod = true;
  bool selectable = false;

  @override
  Widget build(BuildContext context) {
    return GptMarkdownTheme(
      gptThemeData: GptMarkdownTheme.of(context).copyWith(
        highlightColor: Colors.purple,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          actions: [
            IconButton(
              onPressed: () {
                setState(() {
                  selectable = !selectable;
                });
              },
              icon: Icon(
                Icons.select_all_outlined,
                color: selectable
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                    : Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.38),
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _direction = TextDirection.values[(_direction.index + 1) % 2];
                });
              },
              icon: const [Text("LTR"), Text("RTL")][_direction.index],
            ),
            IconButton(
              onPressed: widget.onPressed,
              icon: const Icon(Icons.sunny),
            ),
            IconButton(
              onPressed: () => setState(() {
                writingMod = !writingMod;
              }),
              icon: Icon(
                  writingMod ? Icons.arrow_drop_down : Icons.arrow_drop_up),
            ),
          ],
        ),
        body: DropTarget(
          onDragDone: (details) {
            var files = details.files;
            if (files.length != 1) {
              return;
            }
            var file = files[0];
            String path = file.path;
            this.file = File(path);
            load();
          },
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: ListView(
                      children: [
                        AnimatedBuilder(
                          animation: _controller,
                          builder: (context, _) {
                            return Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    width: 1,
                                    color:
                                        Theme.of(context).colorScheme.outline),
                              ),
                              child: Theme(
                                data: Theme.of(context),
                                // .copyWith(
                                //   textTheme: const TextTheme(
                                //     // For H1.
                                //     headlineLarge: TextStyle(fontSize: 55),
                                //     // For H2.
                                //     headlineMedium: TextStyle(fontSize: 45),
                                //     // For H3.
                                //     headlineSmall: TextStyle(fontSize: 35),
                                //     // For H4.
                                //     titleLarge: TextStyle(fontSize: 25),
                                //     // For H5.
                                //     titleMedium: TextStyle(fontSize: 15),
                                //     // For H6.
                                //     titleSmall: TextStyle(fontSize: 10),
                                //   ),
                                // ),
                                child: Builder(
                                  builder: (context) {
                                    Widget child = GptMarkdown(
                                      _controller.text,
                                      textDirection: _direction,
                                      onLinkTab: (url, title) {
                                        debugPrint(url);
                                        debugPrint(title);
                                      },
                                      textAlign: TextAlign.justify,
                                      textScaler: const TextScaler.linear(1),
                                      style: const TextStyle(
                                        fontSize: 15,
                                      ),
                                      highlightBuilder: (context, text, style) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .secondaryContainer,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            border: Border.all(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .secondary
                                                  .withValues(alpha: 0.5),
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            text,
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSecondaryContainer,
                                              fontFamily: 'monospace',
                                              fontWeight: FontWeight.bold,
                                              fontSize: style.fontSize != null
                                                  ? style.fontSize! * 0.9
                                                  : 13.5,
                                              height: style.height,
                                            ),
                                          ),
                                        );
                                      },
                                      latexWorkaround: (tex) {
                                        List<String> stack = [];
                                        tex = tex.splitMapJoin(
                                          RegExp(r"\\text\{|\{|\}|\_"),
                                          onMatch: (p) {
                                            String input = p[0] ?? "";
                                            if (input == r"\text{") {
                                              stack.add(input);
                                            }
                                            if (stack.isNotEmpty) {
                                              if (input == r"{") {
                                                stack.add(input);
                                              }
                                              if (input == r"}") {
                                                stack.removeLast();
                                              }
                                              if (input == r"_") {
                                                return r"\_";
                                              }
                                            }
                                            return input;
                                          },
                                        );
                                        return tex.replaceAllMapped(
                                            RegExp(r"align\*"),
                                            (match) => "aligned");
                                      },
                                      imageBuilder:
                                          (context, url, semanticLabel) {
                                        return Image.network(
                                          url,
                                          width: 100,
                                          height: 100,
                                          semanticLabel: semanticLabel,
                                        );
                                      },
                                      latexBuilder:
                                          (context, tex, textStyle, inline) {
                                        if (tex.contains(r"\begin{tabular}")) {
                                          // return table.
                                          String tableString = "|${(RegExp(
                                                r"^\\begin\{tabular\}\{.*?\}(.*?)\\end\{tabular\}$",
                                                multiLine: true,
                                                dotAll: true,
                                              ).firstMatch(tex)?[1] ?? "").trim()}|";
                                          tableString = tableString
                                              .replaceAll(r"\\", "|\n|")
                                              .replaceAll(r"\hline", "")
                                              .replaceAll(
                                                  RegExp(r"(?<!\\)&"), "|");
                                          var tableStringList = tableString
                                              .split("\n")
                                            ..insert(1, "|---|");
                                          tableString =
                                              tableStringList.join("\n");
                                          return GptMarkdown(tableString);
                                        }
                                        var controller = ScrollController();
                                        Widget child = Math.tex(
                                          tex,
                                          textStyle: textStyle,
                                        );
                                        if (!inline) {
                                          child = Padding(
                                            padding: const EdgeInsets.all(0.0),
                                            child: Material(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onInverseSurface,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Scrollbar(
                                                  controller: controller,
                                                  child: SingleChildScrollView(
                                                    controller: controller,
                                                    scrollDirection:
                                                        Axis.horizontal,
                                                    child: Math.tex(
                                                      tex,
                                                      textStyle: textStyle,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        }
                                        child = SelectableAdapter(
                                          selectedText: tex,
                                          child: Math.tex(tex),
                                        );
                                        child = InkWell(
                                          onTap: () {
                                            debugPrint("Hello world");
                                          },
                                          child: child,
                                        );
                                        return child;
                                      },
                                      sourceTagBuilder:
                                          (buildContext, string, textStyle) {
                                        var value = int.tryParse(string);
                                        value ??= -1;
                                        value += 1;
                                        return SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child:
                                                Center(child: Text("$value")),
                                          ),
                                        );
                                      },
                                      linkBuilder:
                                          (context, label, path, style) {
                                        return Text(
                                          label,
                                          style: style.copyWith(
                                            color: Colors.blue,
                                          ),
                                        );
                                      },
                                      components: [
                                        CodeBlockMd(),
                                        NewLines(),
                                        BlockQuote(),
                                        ImageMd(),
                                        ATagMd(),
                                        TableMd(),
                                        HTag(),
                                        UnOrderedList(),
                                        OrderedList(),
                                        RadioButtonMd(),
                                        CheckBoxMd(),
                                        HrLine(),
                                        StrikeMd(),
                                        BoldMd(),
                                        ItalicMd(),
                                        LatexMath(),
                                        LatexMathMultiLine(),
                                        HighlightedText(),
                                        SourceTag(),
                                        IndentMd(),
                                      ],
                                      inlineComponents: [
                                        ImageMd(),
                                        ATagMd(),
                                        TableMd(),
                                        StrikeMd(),
                                        BoldMd(),
                                        ItalicMd(),
                                        LatexMath(),
                                        LatexMathMultiLine(),
                                        HighlightedText(),
                                        SourceTag(),
                                      ],
                                      // codeBuilder: (context, name, code, closed) {
                                      //   return Padding(
                                      //     padding: const EdgeInsets.symmetric(
                                      //         horizontal: 16),
                                      //     child: Text(
                                      //       code.trim(),
                                      //       style: TextStyle(
                                      //         fontFamily: 'JetBrains Mono',
                                      //         fontSize: 14,
                                      //         height: 1.5,
                                      //         color: Theme.of(context)
                                      //             .colorScheme
                                      //             .onSurface,
                                      //       ),
                                      //     ),
                                      //   );
                                      // }
                                    );
                                    if (selectable) {
                                      child = SelectionArea(
                                        child: child,
                                      );
                                    }
                                    return child;
                                  },
                                ),
                                // child: const Text("Hello"),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  if (writingMod)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 400),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              label: Text("Type here:")),
                          maxLines: null,
                          controller: _controller,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
