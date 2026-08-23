import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads every font the showcase needs.
///
/// `flutter test` renders with a placeholder font in which every glyph is a
/// black box, so the real families have to be registered by hand. None of the
/// paths below are hardcoded — the SDK is found by walking up from the test
/// binary, and package fonts come out of `.dart_tool/package_config.json` — so
/// this works on any machine with the package's dependencies fetched.
Future<void> loadShowcaseFonts() async {
  final sdk = _flutterSdkRoot();
  if (sdk != null) {
    final materialFonts = Directory(
      '${sdk.path}/bin/cache/artifacts/material_fonts',
    );
    await _loadFamily('Roboto', [
      File('${materialFonts.path}/Roboto-Regular.ttf'),
      File('${materialFonts.path}/Roboto-Medium.ttf'),
      File('${materialFonts.path}/Roboto-Bold.ttf'),
      File('${materialFonts.path}/Roboto-Italic.ttf'),
      File('${materialFonts.path}/Roboto-BoldItalic.ttf'),
    ]);
    await _loadFamily('MaterialIcons', [
      File('${materialFonts.path}/MaterialIcons-Regular.otf'),
    ]);

    // Some text resolves to a null font family — a `DefaultTextStyle` that
    // only sets a colour, for instance, as the code block's copy button does.
    // In an app that lands on the platform's own font; here it lands on the
    // test font, whose every glyph is a filled box. Registering Roboto under
    // the test font's names makes those runs render the way a reader's device
    // would draw them.
    final roboto = [File('${materialFonts.path}/Roboto-Regular.ttf')];
    for (final fallback in const ['FlutterTest', 'Ahem']) {
      await _loadFamily(fallback, roboto);
    }
  }

  // The package declares its monospace font, so at runtime the family is
  // namespaced by the package that ships it — but the code-block header asks
  // for the bare name, so register both spellings.
  final mono = [File('lib/fonts/JetBrainsMono-Regular.ttf')];
  await _loadFamily('packages/gpt_markdown/JetBrainsMono', mono);
  await _loadFamily('JetBrainsMono', mono);

  await _loadKatexFonts();
}

/// Registers the KaTeX families that `flutter_math_fork` draws equations with.
///
/// Without these an equation lays out correctly — fraction bars and integral
/// signs are in the right places — but every glyph is a box.
Future<void> _loadKatexFonts() async {
  final root = _packageRoot('flutter_math_fork');
  if (root == null) {
    return;
  }
  final dir = Directory('${root.path}/lib/katex_fonts/fonts');
  if (!dir.existsSync()) {
    return;
  }

  // KaTeX_Main-Bold.ttf and KaTeX_Main-Regular.ttf are two faces of one
  // family, so group the files by the part before the dash.
  final families = <String, List<File>>{};
  for (final entity in dir.listSync()) {
    if (entity is! File || !entity.path.endsWith('.ttf')) {
      continue;
    }
    final name = entity.uri.pathSegments.last;
    final dash = name.indexOf('-');
    if (dash <= 0) {
      continue;
    }
    families.putIfAbsent(name.substring(0, dash), () => <File>[]).add(entity);
  }

  for (final entry in families.entries) {
    await _loadFamily('packages/flutter_math_fork/${entry.key}', entry.value);
  }
}

Future<void> _loadFamily(String family, List<File> files) async {
  final present = files.where((file) => file.existsSync()).toList();
  if (present.isEmpty) {
    return;
  }
  final loader = FontLoader(family);
  for (final file in present) {
    loader.addFont(file.readAsBytes().then(ByteData.sublistView));
  }
  await loader.load();
}

/// Walks up from the test binary until the SDK's font cache appears.
Directory? _flutterSdkRoot() {
  var dir = File(Platform.resolvedExecutable).parent;
  for (var i = 0; i < 8; i++) {
    if (Directory(
      '${dir.path}/bin/cache/artifacts/material_fonts',
    ).existsSync()) {
      return dir;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      return null;
    }
    dir = parent;
  }
  return null;
}

/// Resolves a dependency's location from the package config `flutter pub get`
/// writes, so no pub-cache path is assumed.
Directory? _packageRoot(String packageName) {
  final config = File('.dart_tool/package_config.json');
  if (!config.existsSync()) {
    return null;
  }
  final decoded = jsonDecode(config.readAsStringSync());
  if (decoded is! Map<String, dynamic>) {
    return null;
  }
  final packages = decoded['packages'];
  if (packages is! List) {
    return null;
  }
  for (final package in packages) {
    if (package is! Map<String, dynamic> || package['name'] != packageName) {
      continue;
    }
    final rootUri = package['rootUri'];
    if (rootUri is! String) {
      return null;
    }
    final resolved = config.parent.uri.resolve(rootUri);
    return Directory.fromUri(resolved);
  }
  return null;
}
