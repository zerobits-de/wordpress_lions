#!/usr/bin/env bash
# Build the production theme package: build/lions-theme.zip
#
# The ZIP contains the theme with production Composer dependencies (vendor/)
# because a WordPress theme must be installable by uploading a single ZIP -
# there is no Composer step on a typical WordPress host.
#
# Usage: bash bin/build.sh            (uses local composer, or Docker if absent)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/theme"
OUT="$ROOT/build"
PKG="$OUT/lions-theme"
ZIP="$OUT/lions-theme.zip"

echo "==> Cleaning $OUT"
rm -rf "$PKG" "$ZIP"
mkdir -p "$PKG"

echo "==> Copying theme files"
rsync -a "$SRC/" "$PKG/" \
  --exclude 'vendor/' \
  --exclude 'node_modules/' \
  --exclude '.phpcs-cache' \
  --exclude '.phpstan-cache/' \
  --exclude 'phpcs.xml.dist' \
  --exclude 'phpstan.neon.dist' \
  --exclude '.DS_Store' \
  --exclude '*.map'

echo "==> Installing production dependencies"
if command -v composer >/dev/null 2>&1; then
  composer install --working-dir="$PKG" --no-dev --prefer-dist --optimize-autoloader --classmap-authoritative --no-interaction --no-progress
else
  echo "    (composer not found locally, using Docker image composer:2)"
  docker run --rm -v "$PKG":/app -w /app composer:2 \
    composer install --no-dev --prefer-dist --optimize-autoloader --classmap-authoritative --no-interaction --no-progress
fi

# Composer's own metadata is not needed at runtime but is harmless; keep
# composer.json/lock for provenance. Strip package docs/tests to keep the ZIP small.
find "$PKG/vendor" -type d \( -name tests -o -name test -o -name docs -o -name .github \) -prune -exec rm -rf {} + 2>/dev/null || true

echo "==> Validating package"
sh "$ROOT/bin/validate-theme.sh" "$PKG" --require-vendor

echo "==> Creating $ZIP"
( cd "$OUT" && zip -qr "lions-theme.zip" "lions-theme" -x '*.DS_Store' )

SIZE=$(du -h "$ZIP" | cut -f1)
echo "==> Done: $ZIP ($SIZE)"
unzip -l "$ZIP" | tail -1
