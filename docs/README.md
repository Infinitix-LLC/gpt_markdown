# gpt_markdown documentation

Markdown and LaTeX rendering for Flutter, built for AI chat output.

| Guide | Read it when |
|---|---|
| [Getting started](getting-started.md) | You are adding the package to an app |
| [Customization](customization.md) | You want it to look like your app |
| [Streaming](streaming.md) | You are rendering a reply as it generates |
| [Inline syntax](inline-syntax.md) | You need `@mention`, `#channel`, `:emoji:` or autolinks |
| [Custom components](custom-components.md) | Styles and builders are not enough |
| [Testing](testing.md) | Your widget tests do not find what you expect |
| [Migration](../MIGRATION.md) | You are upgrading from 1.1.x |

> [!NOTE]
> Every code snippet in these guides is compiled by the test suite
> (`test/docs/snippets_test.dart`). If a parameter is renamed, the guides stop
> compiling — so they cannot quietly go stale.
>
> Numbers quoted as measurements come from tests in `test/`, not estimates.

## The one rule

Two ways to change what you see, and they never overlap:

| | Use it for | Example |
|---|---|---|
| **Style object** | Appearance — colours, sizes, padding, fonts | `BlockQuoteStyle(barWidth: 4)` |
| **Builder** | Structure — replace the widget entirely | `blockQuoteBuilder: …` |

Every component supports both.

> [!TIP]
> If you are reaching for a builder to change a colour, stop — there is a style
> field for it. Builders lose the default structure, and with it every future
> improvement to that component.

## Three things that catch people out

* A `WidgetSpan` inside a link label **does not paint on iOS** — declare
  `scopes` on custom components. See [inline syntax](inline-syntax.md#scopes).
* **Changing a builder at runtime does nothing** — builders are not compared
  when deciding to re-render. See [testing](testing.md).
* **`find.text` does not find Markdown text** — it renders as spans, not
  `Text` widgets. See [testing](testing.md).
