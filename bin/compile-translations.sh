#!/usr/bin/env sh
# Compile theme/languages/*.po into the *.mo files WordPress actually reads.
#
# Nothing in the release pipeline does this: bin/build.sh copies the theme as
# committed, so an outdated *.mo ships an outdated translation. Run this after
# editing a *.po and commit both files together.
#
# Usage: sh bin/compile-translations.sh [theme-dir]
set -eu

THEME="${1:-theme}"
LANGS="$THEME/languages"
[ -d "$LANGS" ] || { echo "No $LANGS directory" >&2; exit 1; }

if command -v msgfmt >/dev/null 2>&1; then
  run_msgfmt() { msgfmt "$@"; }
elif docker compose ps --status running --format '{{.Service}}' 2>/dev/null | grep -qx wordpress \
     && docker compose exec -T wordpress sh -c 'command -v msgfmt' >/dev/null 2>&1; then
  echo "==> Using msgfmt inside the wordpress container"
  run_msgfmt() { docker compose exec -T -w /var/www/html/wp-content/themes/lions-theme wordpress msgfmt "$@"; }
else
  echo "msgfmt not found. Install GNU gettext (macOS: brew install gettext)," >&2
  echo "or rebuild the dev container with 'make up', which now includes it." >&2
  exit 1
fi

FOUND=0
STATUS=0
for po in "$LANGS"/*.po; do
  [ -e "$po" ] || continue
  FOUND=1
  mo="${po%.po}.mo"
  # --check rejects malformed headers and printf placeholders that differ
  # between msgid and msgstr - those would be silent runtime breakage.
  if run_msgfmt --check --statistics -o "$mo" "$po"; then
    echo "ok    $mo"
  else
    echo "FAIL  $po did not compile"
    STATUS=1
  fi
done

[ "$FOUND" -eq 1 ] || { echo "No *.po files in $LANGS"; exit 0; }
[ "$STATUS" -eq 0 ] || exit 1
echo "Translations compiled - commit the *.po and *.mo together."
