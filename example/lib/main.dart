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
## ChatGPT Response

Welcome to ChatGPT! Below is an example of a response with Markdown and LaTeX code:

### Markdown Example


```
class MarkdownHelper {


  Map<String, Widget> getTitleWidget(m.Node node) => title.getTitleWidget(node);

  Widget getPWidget(m.Element node) => p.getPWidget(node);

  Widget getPreWidget(m.Node node) => pre.getPreWidget(node);

}
```


You can use Markdown to format text easily. Here are some examples:

- `Highlighted Text`: `This text is highlighted`
- **Bold Text**: **This text is bold**
- *Italic Text*: *This text is italicized*
- [Link](https://www.example.com): [This is a link](https://www.example.com)
- Lists:
  1. Item 1
  2. Item 2
  3. Item 3

### LaTeX Example

You can also use LaTeX for mathematical expressions. Here's an example:

- **Equation**: \( f(x) = x^2 + 2x + 1 \)
- **Integral**: \( \int_{0}^{1} x^2 \, dx \)
- **Matrix**:

\[
\begin{bmatrix}
1 & 2 & 3 \\
4 & 5 & 6 \\
7 & 8 & 9
\end{bmatrix}
\]

### Conclusion

Markdown and LaTeX can be powerful tools for formatting text and mathematical expressions in your Flutter app. If you have any questions or need further assistance, feel free to ask!
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
                        .onSurface /* .withValues(alpha: 0.38) */,
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
                                                  .secondary /* .withValues(alpha: 0.5) */,
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
                                          (contex, tex, textStyle, inline) {
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
                                        //
                                        return Text(path);
                                      },
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
