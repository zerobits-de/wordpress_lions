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

## Releases

```
# bump Version: in theme/style.css and Theme::VERSION, commit, then
git tag v1.0.0
git push origin v1.0.0
```

`.github/workflows/release.yml` verifies that the tag matches the theme version, runs the
full validation, builds the ZIP and attaches it to a GitHub Release.

## Future deployment options

The release artifact is the contract: `lions-theme.zip` containing a self-contained theme.
Any of the following can be added as a job after the build step.

1. **Upload via SSH/rsync** (most common for managed WordPress hosts)
   - Secrets: `DEPLOY_HOST`, `DEPLOY_USER`, `DEPLOY_KEY`, `DEPLOY_PATH`.
   - Steps: unzip artifact, `rsync -az --delete build/lions-theme/ user@host:$DEPLOY_PATH/wp-content/themes/lions-theme/`,
     then `wp cache flush` over SSH.
   - Use a GitHub *environment* (`production`) with required reviewers for a manual gate.
2. **WP-CLI theme install**
   - `wp theme install https://github.com/<org>/<repo>/releases/download/v1.0.0/lions-theme.zip --force`
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
