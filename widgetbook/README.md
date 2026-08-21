# gpt_markdown widgetbook

A catalogue for inspecting every component across devices, themes and text
scales — no emulator required.

```bash
cd widgetbook
flutter pub get
flutter run -d macos     # or: flutter run -d chrome
```

## What the toolbar gives you

| Addon | Use |
|---|---|
| **Text scale** | 0.85x – 3.0x, the range a user can pick in their OS settings |
| **Theme** | Light / Dark, both wired to `GptMarkdownThemeData` |
| **Viewport** | iPhone SE / 13 / 13 Pro Max, iPad Air, Galaxy S20, OnePlus 8 Pro |
| **Alignment** | Where the use case sits in the frame |
| **Inspector** | Widget bounds overlay |
| **Grid** | Alignment grid |

Some use cases add their own **knobs** — the inline code page has sliders for
font size factor, border width, radius and padding.

## Regenerating after adding a use case

Use cases are annotated with `@UseCase` and collected by code generation:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Scope

This is an inspection tool. The behavioural guarantees live in the package's
own tests — `test/regression/text_scaling_test.dart` in particular, which fixes
the width so nothing rewraps and asserts the scaling ratio directly. A frame
sized like a phone cannot make that promise, because raising the scale makes
text rewrap and grow legitimately.
