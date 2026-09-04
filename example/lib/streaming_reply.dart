/// The reply the streaming demo replays.
///
/// Deliberately exhaustive: every construct the package renders appears here,
/// and the awkward combinations appear too — a table cell holding maths with a
/// `|` in it, an equation opened on a list marker, emphasis nested three deep,
/// a fence inside a list item, a quote inside a quote.
///
/// A reveal only looks smooth on the easy half of a document. The point of
/// this one is to make the hard half visible: constructs that restyle when
/// their closing delimiter lands, blocks with no half-state to reveal, and
/// anything whose width changes as it arrives.
library;

/// A reply exercising every supported construct.
const String streamingReply = r'''# Reversing a linked list

Here is the **iterative** approach. It runs in \( O(n) \) time and uses
\( O(1) \) extra space, which is why it is *usually* preferred over
recursion — and it is ***far*** easier to reason about under a debugger.

## The idea

Walk the list once and, as you go, point each node back at the one before
it. You need three references at any moment:

1. `prev` — the part already reversed
2. `curr` — the node being moved
3. `next` — saved before you overwrite `curr.next`

### Emphasis, every way round

Plain, **bold**, *italic*, ***bold italic***, ~~struck through~~,
<u>underlined</u>, `inline code`, and *italic wrapping **bold** and back to
italic*. Escapes hold too: \*not italic\* and a literal \| pipe.

## The code

```dart
ListNode? reverse(ListNode? head) {
  ListNode? prev;
  var curr = head;
  while (curr != null) {
    final next = curr.next;   // save it before overwriting
    curr.next = prev;
    prev = curr;
    curr = next;
  }
  return prev;
}
```

A fence with no language, holding characters that look like markup:

```
**not bold**  `not code`  | not | a | table |
```

## Complexity

| Approach  | Time | Space | Modulus \(|z|\) | Notes                    |
|-----------|:----:|:-----:|:---------------:|--------------------------|
| Iterative | O(n) | O(1)  | \(\sqrt{5}\)    | preferred                |
| Recursive | O(n) | O(n)  | `a|b`           | stack depth is the list  |
| Hybrid    | O(n) | O(1)  | 1               | ***rarely*** worth it    |

## The maths

The cost of the recursive form is the sum of the frames it opens:

\[
T(n) = \sum_{k=1}^{n} 1 = n \quad\Rightarrow\quad O(n)
\]

1. \[
\frac{7x^3}{x^2} = 7x \to +\infty
\]
2. Which is why the iterative form wins on space.

## Things to watch

- [x] the empty list returns null
- [x] a single node returns itself
- [ ] a cycle never terminates — detect it first
- [ ] `prev` must start as **null**, not as `head`

Pick one:

- (x) iterative
- ( ) recursive

## Nested structure

- Outer item with **bold** and a [link](https://example.com)
  - Inner item with `code`
    - Third level, still holding *emphasis*
  - Back to the second level
- Another outer item, with a fence of its own:

  ```dart
  assert(reverse(null) == null);
  ```

1. Ordered, outer
   1. Ordered, inner
   2. Sibling
2. Back out again

> If the list might contain a cycle, run Floyd's algorithm before reversing.
>
> > A quote inside a quote, with **bold** and `code` in it.
>
> See [the docs](https://example.com) or https://pub.dev for more.

---

![A 120x60 placeholder](https://placehold.co/120x60/png)

Citations render as chips: the original result [1], and the follow-up [2].

That is everything. Ask if you want the recursive version too.
''';
