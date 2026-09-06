#!/usr/bin/env sh
# Structural validation of the theme directory (or a built package directory).
# Usage: sh bin/validate-theme.sh <theme-dir> [--require-vendor]
set -eu

THEME="${1:?theme directory required}"
REQUIRE_VENDOR="${2:-}"
STATUS=0

fail() { echo "FAIL  $1"; STATUS=1; }
ok()   { echo "ok    $1"; }

for f in style.css functions.php index.php screenshot.png composer.json composer.lock theme.json \
         templates/base.twig templates/index.twig templates/front-page.twig templates/page.twig \
         templates/single.twig templates/archive.twig templates/search.twig templates/404.twig \
         views/partials/header.twig views/partials/footer.twig assets/css/tokens.css assets/js/main.js; do
  if [ -f "$THEME/$f" ]; then ok "$f exists"; else fail "$f is missing"; fi
done

for header in "Theme Name" "Version" "Text Domain" "Requires PHP" "Requires at least"; do
  if grep -q "^$header:" "$THEME/style.css"; then ok "style.css has '$header'"; else fail "style.css lacks '$header'"; fi
done

if [ "$(grep '^Text Domain:' "$THEME/style.css" | awk '{print $3}')" = "lions-theme" ]; then
  ok "text domain is lions-theme"
else
  fail "text domain must be lions-theme"
fi

# screenshot: WordPress recommends 1200x900.
if command -v file >/dev/null 2>&1 && [ -f "$THEME/screenshot.png" ]; then
  if file "$THEME/screenshot.png" | grep -q "PNG image data"; then ok "screenshot.png is a PNG"; else fail "screenshot.png is not a PNG"; fi
fi

# Nothing that must never ship.
for bad in .env node_modules .git; do
  if [ -e "$THEME/$bad" ]; then fail "$bad must not be inside the theme"; fi
done

if [ "$REQUIRE_VENDOR" = "--require-vendor" ]; then
  if [ -f "$THEME/vendor/autoload.php" ]; then ok "vendor/autoload.php present"; else fail "vendor/autoload.php missing (production package must include Composer dependencies)"; fi
  if [ -d "$THEME/vendor/squizlabs" ] || [ -d "$THEME/vendor/phpstan" ]; then fail "dev dependencies found in production package"; else ok "no dev dependencies in package"; fi
fi

# PHP files must not contain large HTML blocks (presentation belongs in Twig).
HTML_PHP=$(grep -lE '^\s*<(div|section|header|footer|ul|nav)\b' "$THEME"/*.php "$THEME"/src/*.php "$THEME"/src/*/*.php 2>/dev/null || true)
if [ -n "$HTML_PHP" ]; then fail "HTML markup found in PHP: $HTML_PHP"; else ok "no HTML blocks in PHP files"; fi

[ "$STATUS" -eq 0 ] && echo "Theme structure OK" || echo "Theme structure validation FAILED"
exit $STATUS
