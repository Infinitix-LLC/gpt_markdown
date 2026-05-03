import 'package:flutter/material.dart';
import 'package:gpt_markdown/custom_widgets/selectable_adapter.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';

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
    text: r'''This is a sample markdown document.
* **bold**
* *italic*
* **_bold and italic_**
* ~~strikethrough~~
* `code`
* [link](https://www.google.com)

[![alt text](https://www.google.com/images/branding/googlelogo/1x/googlelogo_color_272x92dp.png)](link_url)
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

---

## Conclusion

This document was created to test the robustness of Markdown parsers and to ensure that all components, including advanced LaTeX expressions and nested structures, are rendered correctly. Enjoy testing and feel free to extend it further!
```
''',
  );

  bool writingMod = true;
  bool selectable = false;
  bool useDollarSignsForLatex = false;

  @override
  Widget build(BuildContext context) {
    return GptMarkdownTheme(
      gptThemeData: GptMarkdownTheme.of(context).copyWith(
        highlightColor: Colors.purple,
        hrLinePadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        hrLineColor: Colors.red,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          actions: [
            IconButton(
              onPressed: () {
                setState(() {
                  useDollarSignsForLatex = !useDollarSignsForLatex;
                });
              },
              icon: Icon(
                Icons.monetization_on_outlined,
                color: useDollarSignsForLatex
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
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      ListenableBuilder(
                        listenable: _controller,
                        builder: (context, _) {
                          var data = _controller.text;
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
                              child: Builder(
                                builder: (context) {
                                  Widget child = GptMarkdown(
                                    data,
                                    textDirection: _direction,
                                    onLinkTap: (url, title) {
                                      debugPrint(url);
                                      debugPrint(title);
                                    },
                                    useDollarSignsForLatex:
                                        useDollarSignsForLatex,
                                    textAlign: TextAlign.justify,
                                    textScaler: const TextScaler.linear(1),
                                    style: const TextStyle(),
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
                                    latexBuilder:
                                        (context, tex, textStyle, inline) {
                                      if (tex.contains(r"\begin{tabular}")) {
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
                                      return Text.rich(
                                        label,
                                        style: style.copyWith(
                                          color: Colors.blue,
                                        ),
                                      );
                                    },
                                  );
                                  if (selectable) {
                                    child = SelectionArea(
                                      child: child,
                                    );
                                  }
                                  return child;
                                },
                              ),
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
    );
  }
}
