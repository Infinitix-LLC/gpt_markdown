# gpt_markdown

A Flutter package for rendering Markdown and LaTeX content, optimized for AI-generated text from models like ChatGPT and Gemini.

## Project Overview

This is a Flutter/Dart package (`gpt_markdown`) with a web example app that demonstrates the package's capabilities including:
- Rich Markdown rendering (bold, italic, strikethrough, code, tables, blockquotes, lists)
- LaTeX math expression rendering via `flutter_math_fork`
- Interactive elements (checkboxes, radio buttons)
- Text selection support
- Dark/light theme switching
- LTR/RTL text direction support

## Architecture

- **Root package** (`/`): The `gpt_markdown` Flutter package itself
  - `lib/gpt_markdown.dart` — Main entry point
  - `lib/md_widget.dart` — Core markdown widget
  - `lib/markdown_component.dart` — Markdown component definitions
  - `lib/custom_widgets/` — Specialized widgets (code blocks, tables, links, radio/checkbox, etc.)
  - `lib/theme.dart` — Theming support

- **Example app** (`/example`): Flutter web demo app
  - `example/lib/main.dart` — Main app file (web-compatible, no dart:io or desktop dependencies)
  - `example/build/web/` — Built Flutter web output (served on port 5000)

## Tech Stack

- **Language**: Dart
- **Framework**: Flutter 3.32.0 (installed via Nix)
- **Key Dependencies**:
  - `flutter_math_fork` — LaTeX rendering
  - `cupertino_icons` — Icons
- **Web Server**: `npx serve` (Node.js 20)

## Running the App

The `start.sh` script builds the Flutter web app and serves it:
```bash
bash start.sh
```

This runs `flutter pub get`, `flutter build web`, and serves `example/build/web` on port 5000.

## Important Notes

- Flutter SDK constraint in `pubspec.yaml` was relaxed from `>=3.35.0` to `>=3.0.0` to work with the installed Flutter 3.32.0
- `custom_rb_cb.dart` was fixed to use `Radio<bool>` with `groupValue` instead of the newer `RadioGroup` API (added in Flutter 3.35+)
- `example/lib/main.dart` was made web-compatible by removing `dart:io`, `desktop_drop`, and `watcher` imports (file-system features not available in browsers)

## Deployment

Configured as a **static** deployment:
- **Build**: `cd example && flutter pub get && flutter build web --no-tree-shake-icons`
- **Public dir**: `example/build/web`
