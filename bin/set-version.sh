#!/usr/bin/env sh
# Write a version into the theme's two version locations:
#   theme/style.css      "Version:" header (read by WordPress)
#   theme/src/Theme.php  Theme::VERSION   (used for asset cache busting)
#
# The release workflow calls this with the pushed tag, so the tag is the single
# source of truth and no manual bump commit is needed. Run it locally before
# `make build` if you want a correctly versioned ZIP from a working tree.
#
# Usage: sh bin/set-version.sh <version> [theme-dir]
set -eu

VERSION="${1:?version required (e.g. 1.0.4)}"
THEME="${2:-theme}"

case "$VERSION" in
  v*) echo "Version must be plain (1.0.4), not v-prefixed: $VERSION" >&2; exit 1 ;;
esac
if ! printf '%s' "$VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+([-.][0-9A-Za-z.-]+)?$'; then
  echo "Not a valid version: $VERSION" >&2
  exit 1
fi

STYLE="$THEME/style.css"
PHP="$THEME/src/Theme.php"
for f in "$STYLE" "$PHP"; do
  [ -f "$f" ] || { echo "Missing $f" >&2; exit 1; }
done

# In-place editing without GNU/BSD sed -i differences.
rewrite() {
  tmp="$(mktemp)"
  sed -E "$2" "$1" > "$tmp"
  mv "$tmp" "$1"
}

# Keep the header's column alignment by preserving the whitespace run.
rewrite "$STYLE" "s/^(Version:[[:space:]]*).*/\\1$VERSION/"
rewrite "$PHP"   "s/(const VERSION[[:space:]]*=[[:space:]]*')[^']*(')/\\1$VERSION\\2/"

# A silently unmatched pattern would ship the old version, so verify.
GOT_STYLE=$(grep -E '^Version:' "$STYLE" | awk '{print $2}')
GOT_PHP=$(grep -E 'const VERSION' "$PHP" | sed -E "s/.*'([^']+)'.*/\1/")
STATUS=0
[ "$GOT_STYLE" = "$VERSION" ] || { echo "FAIL  $STYLE still reads '$GOT_STYLE'" >&2; STATUS=1; }
[ "$GOT_PHP" = "$VERSION" ]   || { echo "FAIL  $PHP still reads '$GOT_PHP'" >&2; STATUS=1; }
[ "$STATUS" -eq 0 ] || exit 1

echo "ok    $STYLE  Version: $VERSION"
echo "ok    $PHP    Theme::VERSION = $VERSION"
