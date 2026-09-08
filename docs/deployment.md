# Building and deploying

## Production package

`make build` (or `bash bin/build.sh`) creates `build/lions-theme.zip`:

- copies `theme/` without dev-only files (`phpcs.xml.dist`, `phpstan.neon.dist`, caches),
- runs `composer install --no-dev --optimize-autoloader --classmap-authoritative` inside
  the package so `vendor/` (Timber, Twig) is included,
- validates the result (`bin/validate-theme.sh ... --require-vendor`),
- zips it as `lions-theme/` at the ZIP root, which is what WordPress expects on upload.

**Why vendor/ is included:** a WordPress theme must be installable from a single ZIP through
*Appearance > Themes > Add New > Upload* or by unzipping into `wp-content/themes/`. Typical
WordPress hosts have no Composer step, and Timber 2 is only distributed through Composer.
Shipping `vendor/` is therefore the most reliable option. Dev dependencies are never included.

## First deployment to a server (blank WordPress)

The concrete commands for the production server (including installing WP-CLI on Debian) are
in the [README](../README.md#server-installation); this section covers the same flow with
the reasoning behind it.

The server needs a running WordPress (any state: fresh install or blank), SSH access,
[WP-CLI](https://wp-cli.org/), PHP 8.2+ with the GD extension (for the demo featured image)
and `bash`. `WP_PATH` below is the WordPress root on the server (the directory holding
`wp-config.php`).

```bash
# 1. Build the package locally
make build                                   # -> build/lions-theme.zip

# 2. Copy the theme and the seeding scripts to the server
scp build/lions-theme.zip user@server:/tmp/
scp bin/wp-install.sh bin/placeholder-image.php user@server:/tmp/

# 3. On the server: install and activate the theme
ssh user@server
cd "$WP_PATH"
wp theme install /tmp/lions-theme.zip --force --activate

# 4. Seed the initial content (idempotent, existing content is left untouched)
WP_PATH="$PWD" WORDPRESS_SITE_TITLE="Lions Club Musterstadt" WORDPRESS_LOCALE=de_DE \
  bash /tmp/wp-install.sh
```

`wp-install.sh` skips the `wp core install` step when WordPress is already installed and
takes the site URL from the existing `home` option, so it only creates pages, categories,
demo stories, menus and the Customizer defaults. Run it again after a theme update; it
never overwrites content that already exists.

Afterwards, in *wp-admin*:

- *Settings > Permalinks*: the script sets `/%postname%/`; re-save once if the host needs
  to write `.htaccess`/nginx rules.
- *Appearance > Customize > Lions International*: replace the placeholder phone number and
  the Join/Donate URLs with the real ones.
- Replace the demo featured image and the SVG placeholders in
  `assets/images/placeholders/` with licensed photography.

### Alternative: seed locally, then migrate

If the content should be reviewed before it goes live, seed the local Docker environment,
then move database and uploads:

```bash
make wp ARGS="db export /tmp/lions.sql"
docker compose cp wordpress:/tmp/lions.sql ./lions.sql
# on the server, after importing:
wp search-replace 'http://localhost:8080' 'https://example.com' --all-tables-with-prefix --precise
wp cache flush
```

Never do this against a site that already has real content - it replaces the database.

## Releases

Releasing is a single step in the GitHub UI: **Releases > Draft a new release**, enter a
new tag (`1.0.4`), target `main`, write the notes, **Publish release**. No version bump,
commit or tag push is needed beforehand.

Publishing creates the tag, and the tag push starts `.github/workflows/release.yml`, which

1. stamps the tag into `theme/style.css` and `Theme::VERSION` (`bin/set-version.sh`),
2. runs the full validation (PHP lint, PHPCS, PHPStan, Twig lint, theme structure),
3. builds `lions-theme.zip`,
4. attaches the ZIP to the release - or creates the release, when the tag was pushed from
   the terminal (`git tag 1.0.4 && git push origin 1.0.4`) instead.

Notes written in the UI are left untouched; only the asset is added, so re-running the job
is safe.

Translations are *not* compiled during the release - `bin/build.sh` copies the theme as
committed, and WordPress reads `languages/*.mo`. Run `make i18n` after editing a `.po` and
commit both files, or the release ships the previous translation. Tags are plain versions (`1.0.4`), without a `v` prefix; the workflow rejects
`v`-prefixed tags so the release name and the theme version always agree. The tag is the
single source of truth for the version.

Locally, `make set-version VERSION=1.0.0` applies the same rewrite (useful before
`make build`, which otherwise packages whatever version is committed).

## Future deployment options

The release artifact is the contract: `lions-theme.zip` containing a self-contained theme.
Any of the following can be added as a job after the build step.

1. **Upload via SSH/rsync** (most common for managed WordPress hosts)
   - Secrets: `DEPLOY_HOST`, `DEPLOY_USER`, `DEPLOY_KEY`, `DEPLOY_PATH`.
   - Steps: unzip artifact, `rsync -az --delete build/lions-theme/ user@host:$DEPLOY_PATH/wp-content/themes/lions-theme/`,
     then `wp cache flush` over SSH.
   - Use a GitHub *environment* (`production`) with required reviewers for a manual gate.
2. **WP-CLI theme install**
   - `wp theme install https://github.com/<org>/<repo>/releases/download/1.0.0/lions-theme.zip --force`
     run on the server (via SSH step or a host-side webhook).
3. **Git-based hosts** (WP Engine, Kinsta, Pantheon)
   - Push the built `build/lions-theme/` directory to the host's deploy branch/remote
     from the workflow, or point the host at this repo and run `composer install --no-dev`
     in its build hook.
4. **Container image**
   - Extend `docker/wordpress/Dockerfile` with a production stage that `COPY`s the built
     theme into the image and deploy the image (Kubernetes, ECS, ...).

Recommendations for all options:

- Deploy only from tags; keep `main` deployable.
- Never deploy the database or uploads from CI.
- Keep `WP_DEBUG` off in production; `WP_ENVIRONMENT_TYPE=production` makes
  `Theme::asset_version()` use the theme version for cache-busting.
- Put TLS, security headers and rate limiting at the web server / CDN layer.
