/// Shared Markdown sample documents for the plusparse tests and benchmarks.
library;

/// The ChatGPT-style sample document from the original Rust plusparse test
/// suite (`rust/tests/sample_chatgpt.md`).
const String sampleChatGpt = r'''
## ChatGPT Response

Welcome to ChatGPT! Below is an example of a response with Markdown and LaTeX code:

### Markdown Example

You can use Markdown to format text easily. Here are some examples:

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
''';

/// A small single-paragraph document with heavy inline formatting.
const String sampleInlineHeavy =
    r'Mixing **bold**, *italic*, ~~strike~~, `code`, <u>under</u>, '
    r'a [link](https://example.com/a?b=c), an image ![100x200](img.png), '
    r'a citation [12] and math \( e^{i\pi} + 1 = 0 \) in one line.';

/// A table + code + list document (block-construct heavy).
const String sampleBlockHeavy = r'''
# Report

| Name | Score | Notes |
|:-----|------:|:-----:|
| Alice | 93 | **top** |
| Bob | 78 | *ok* |
| Carol | 61 | needs `review` |

```python
def hello(name):
    print(f"hello {name}")
```

> Quoted summary with **bold** text
> spanning two lines.

1. First step
2. Second step
   - nested detail
   - more detail
3. Third step

[x] shipped
[ ] pending
---
''';

/// A large document assembled from the samples above; roughly [repeat] times
/// the ChatGPT sample plus block-heavy sections. Around 60 KB with the
/// default repeat of 25.
String buildLargeDocument({int repeat = 25}) {
  final buffer = StringBuffer();
  for (var i = 0; i < repeat; i++) {
    buffer.writeln('# Section $i');
    buffer.writeln();
    buffer.writeln(sampleChatGpt);
    buffer.writeln(sampleInlineHeavy);
    buffer.writeln();
    buffer.writeln(sampleBlockHeavy);
    buffer.writeln();
  }
  return buffer.toString();
}
