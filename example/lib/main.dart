import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

import 'autolink_demo.dart';
import 'demo_theme.dart';
import 'inline_code_demo.dart';
import 'inline_patterns_demo.dart';
import 'selection_demo.dart';
import 'text_scale_demo.dart';

/// Minimal example for gpt_markdown — Markdown & LaTeX renderer for Flutter.
///
/// For the full interactive playground visit https://gptmarkdown.com/playground
void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoApp(
      title: 'gpt_markdown example',
      pageBuilder: (toggleTheme) => ExamplePage(onToggleTheme: toggleTheme),
    );
  }
}

/// Sample content demonstrating the key features of gpt_markdown.
const _markdown = r'''
# GPT Markdown

**Bold**, *italic*, ~~strikethrough~~, `inline code`, and <u>underline</u>.

---

## LaTeX Math

Inline: \( E = mc^2 \) and the quadratic formula \( x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a} \)

Block:

\[
\int_{-\infty}^{\infty} e^{-x^2}\,dx = \sqrt{\pi}
\]

## Code Block

```dart
GptMarkdown(
  r'**Hello** from _gpt_markdown_! Inline LaTeX: \( E = mc^2 \)',
)
```

## Table

| Feature         | Supported |
|:----------------|:---------:|
| Markdown        | ✅        |
| LaTeX math      | ✅        |
| Code blocks     | ✅        |
| Tables          | ✅        |
| RTL support     | ✅        |
| Custom builders | ✅        |
| WASM            | ✅        |

## Lists

1. Install: `flutter pub add gpt_markdown`
2. Import: `package:gpt_markdown/gpt_markdown.dart`
3. Use: `GptMarkdown(yourText)`

- [x] Render Markdown
- [x] Render LaTeX math
- [ ] Ship your AI app

## AI Output (Markdown + LaTeX + Code mixed)

The **gradient descent** update rule is:

\[ \theta := \theta - \alpha \nabla J(\theta) \]

where \( \alpha \) is the learning rate.

```python
for epoch in range(100):
    grad = compute_gradient(X, y, theta)
    theta -= alpha * grad
```

> Visit [gptmarkdown.com](https://gptmarkdown.com) for the interactive playground.
''';

class ExamplePage extends StatelessWidget {
  const ExamplePage({super.key, this.onToggleTheme});

  /// Flips the app between light and dark.
  final VoidCallback? onToggleTheme;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('gpt_markdown'),
        actions: [
          DemoThemeButton(onToggle: onToggleTheme),
          IconButton(
            tooltip: 'Text scaling demo',
            icon: const Icon(Icons.format_size_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const TextScalePage()),
            ),
          ),
          IconButton(
            tooltip: 'Selection demo',
            icon: const Icon(Icons.text_fields_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SelectionPage()),
            ),
          ),
          IconButton(
            tooltip: 'Autolinks demo',
            icon: const Icon(Icons.link_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AutolinkPage()),
            ),
          ),
          IconButton(
            tooltip: 'Inline code demo',
            icon: const Icon(Icons.code_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const InlineCodePage()),
            ),
          ),
          IconButton(
            tooltip: 'Inline patterns demo',
            icon: const Icon(Icons.alternate_email_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const InlinePatternsPage(),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: GptMarkdown(
          _markdown,
          onLinkTap: (url, title) => debugPrint('Link tapped: $url'),
        ),
      ),
    );
  }
}
