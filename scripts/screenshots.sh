#!/usr/bin/env bash
#
# Regenerates the README showcase images into `screenshots/`.
#
# The generator lives in `tool/screenshots/` and runs through the Flutter test
# harness, which is the supported way to rasterise a widget to a file without
# opening a window. It is not part of the test suite: `flutter test` only looks
# in `test/`, so this never runs on CI and never gates a build.
#
# Unlike the golden files, these images are not compared against anything. They
# are documentation, so they can be regenerated on any machine.
set -euo pipefail

cd "$(dirname "$0")/.."

echo "▸ rendering"
flutter test tool/screenshots/generate_test.dart --update-goldens

echo
echo "✓ screenshots updated — review them before committing"
git status --short screenshots
