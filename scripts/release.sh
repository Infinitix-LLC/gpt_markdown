#!/usr/bin/env bash
#
# Pre-release gate: verifies the version, the changelog and the score line up,
# then tags. Publishing itself happens on CI from the tag.
#
#   ./scripts/release.sh
set -euo pipefail

cd "$(dirname "$0")/.."

VERSION="$(grep '^version:' pubspec.yaml | awk '{print $2}')"
echo "▸ version in pubspec.yaml: $VERSION"

# pub.dev awards 5 points for a changelog, and only counts it when the version
# being published has its own heading. Publishing while the changelog still
# says "Unreleased" loses those points and tells users nothing.
if ! grep -qE "^## +\[?${VERSION//./\\.}\]?" CHANGELOG.md; then
  echo
  echo "✗ CHANGELOG.md has no '## $VERSION' heading."
  echo "  Rename the 'Unreleased' section before releasing."
  exit 1
fi
echo "▸ changelog has a heading for $VERSION"

if [[ -n "$(git status --porcelain)" ]]; then
  echo "✗ working tree is dirty — commit before tagging"
  exit 1
fi

./scripts/check.sh
./scripts/score.sh 160

TAG="v$VERSION"
if git rev-parse "$TAG" >/dev/null 2>&1; then
  echo "✗ tag $TAG already exists"
  exit 1
fi

echo
read -r -p "Tag and push $TAG? [y/N] " reply
if [[ ! "$reply" =~ ^[Yy]$ ]]; then
  echo "aborted — nothing pushed"
  exit 1
fi

git tag -a "$TAG" -m "$VERSION"
git push origin "$TAG"
echo "✓ pushed $TAG — the publish workflow takes it from here"
