#!/usr/bin/env bash
#
# Regenerates the golden files that lock the package's default appearance.
#
# The goldens exist so a change to a default cannot slip through unnoticed: a
# failure means something now looks different than it did. Regenerate only
# when the change is intended.
set -euo pipefail

cd "$(dirname "$0")/.."

cat <<'WARNING'
⚠  Goldens are platform-sensitive: font rasterisation differs between macOS,
   Linux and Windows. CI runs them on ubuntu-latest.

   Regenerating on another platform will make CI fail on every future run.
   Prefer letting CI regenerate them, or run this inside the same image.

WARNING

read -r -p "Regenerate anyway? [y/N] " reply
if [[ ! "$reply" =~ ^[Yy]$ ]]; then
  echo "aborted"
  exit 1
fi

flutter test test/golden --update-goldens
echo
echo "✓ goldens updated — review the diff before committing"
git status --short test/golden
