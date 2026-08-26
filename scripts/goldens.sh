#!/usr/bin/env bash
#
# Regenerates the golden files that lock the package's default appearance.
#
# Goldens are compared on Linux only, because text rasterisation is not
# identical across platforms — a golden captured on macOS fails on CI for
# reasons that are not a change. A tolerance was tried and rejected: any
# threshold loose enough to absorb that noise also hides real changes.
#
# So they have to be generated on Linux too. On Linux this regenerates them
# directly; anywhere else it points you at the workflow that does.
set -euo pipefail

cd "$(dirname "$0")/.."

if [[ "$(uname -s)" != "Linux" ]]; then
  cat <<'ELSEWHERE'
Goldens are generated on Linux, and this is not Linux.

Run the workflow instead — it regenerates them and commits them back to the
branch you dispatch it from:

  gh workflow run goldens.yml --ref "$(git rev-parse --abbrev-ref HEAD)"
  gh run watch
  git pull

Pass -f commit=false to get the images as an artifact without a commit.

Locally the golden tests are skipped, so the rest of the suite still runs.
ELSEWHERE
  exit 1
fi

echo "▸ regenerating"
flutter test test/golden --update-goldens

echo "▸ verifying"
flutter test test/golden

echo
echo "✓ goldens updated — review the diff before committing"
git status --short test/golden
