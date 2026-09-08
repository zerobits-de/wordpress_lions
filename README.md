# Lions International WordPress Theme

A custom, production-oriented WordPress theme built with **Timber** and **Twig**, with a
complete Docker-based local environment, Composer dependency management, GitHub Actions
validation and a release pipeline that produces an installable `lions-theme.zip`.

The visual language is inspired by [lionsclubs.org](https://www.lionsclubs.org/) (blue /
yellow / navy palette, bold Helvetica-style typography, white content panels, angled photo
edges, statistic tiles, substantial navy footer) and implemented independently. See
[`docs/design.md`](docs/design.md).

## Repository layout

```
.
├── .github/workflows/     ci.yml (validation + Docker smoke test + package), release.yml (tag -> GitHub Release)
├── bin/                   build.sh, twig-lint.php, validate-theme.sh, wp-install.sh (WP-CLI setup + demo content),
│                          placeholder-image.php (generates the demo featured images)
├── docker/wordpress/      Dockerfile: WordPress 7.1 / PHP 8.3 / Apache + Composer + WP-CLI;
│                          entrypoint.sh keeps wp-content/uploads writable by www-data
├── docs/                  design.md, architecture.md, deployment.md
├── theme/                 the WordPress theme (mounted into the container as lions-theme)
│   ├── functions.php      loads Composer + boots Lions\Theme\Theme
│   ├── src/               PHP: Theme, Site, Controllers/, Components/, Functions/, Content/
│   ├── templates/         page-level Twig templates (base.twig, front-page.twig, page.twig, ...)
│   ├── views/             components/, partials/, sections/
│   ├── assets/            css/ (design tokens + modules), js/main.js, images/ (icons, placeholders, logo)
│   ├── languages/         lions-theme.pot
│   ├── theme.json         editor palette / font sizes (settings only)
│   └── composer.json      timber/timber ^2.5 + dev tools (PHPCS/WPCS, PHPStan)
├── docker-compose.yml     wordpress + db (MySQL 8.4), named volumes, theme bind mount
├── Makefile               make up / install / lint / test / build / ...
├── AGENTS.md              rules for AI coding agents (and humans)
└── .env.example           environment template (copy to .env)
```

## Technology

| Layer | Choice |
|---|---|
| CMS | WordPress 7.1 (image `wordpress:7.1-php8.3-apache`) |
| PHP | **8.3** (Docker, CI and Composer platform config all pin 8.3; the theme requires >= 8.2) |
| Templating | Timber 2.5 + Twig 3 |
| Dependencies | Composer (PSR-4 autoloading, `Lions\Theme\` -> `theme/src/`) |
| Frontend | Plain CSS with custom properties, one small vanilla JS file; no build step, no framework |
| Local env | Docker Compose (WordPress + MySQL 8.4), WP-CLI inside the container |
| Quality | PHP_CodeSniffer + WordPress Coding Standards, PHPStan (level 6, WordPress stubs), Twig linter, structure check |
| CI/CD | GitHub Actions: CI on push/PR, release on `v*` tags |

## Requirements

- Docker Desktop (or Docker Engine) with Compose v2
- GNU Make
- Git

PHP and Composer are **not** required on the host; they run inside the container.
(If you have them locally, `bin/build.sh` and `bin/twig-lint.php` also work natively.)

## Installation

```bash
git clone <this repository> lions-theme
cd lions-theme
cp .env.example .env      # adjust ports/credentials if needed
make up                   # builds the image, starts WordPress + MySQL, runs composer install
make install              # completes the WordPress installation and seeds demo content
```

`make install` uses WP-CLI to create the admin user from `.env` (default `admin` / `admin`),
activate the theme, create pages, menus, categories, sample stories and Customizer defaults.
It is idempotent. If you prefer the browser installer, skip `make install`, open the site and
activate **Lions International** under *Appearance > Themes*.

## Local website

- Site: <http://localhost:8080>
- Admin: <http://localhost:8080/wp-admin/> (credentials from `.env`)
- MySQL is **not** exposed on the host; use `make db-shell`.

Change the port with `WORDPRESS_PORT` in `.env`.

## Theme development

```
theme/  ──bind mount──▶  /var/www/html/wp-content/themes/lions-theme   (inside the container)
```

Edit files in `theme/`, refresh the browser. Nothing is copied or compiled.

- **PHP prepares data.** `theme/src/Controllers/*` build the Timber context for each
  WordPress template (`front-page.php`, `page.php`, ...). Feature classes in
  `theme/src/Functions/*` register hooks (assets, menus, Customizer, SEO, ...).
- **Twig renders.** `theme/templates/*.twig` extend `base.twig` and compose
  `views/sections`, `views/components` and `views/partials`.
- **Design tokens** live in `theme/assets/css/tokens.css`; components reference them.
- **Editors** manage pages/posts with the block editor, navigation under *Appearance > Menus*,
  and organisation data (Join/Donate URLs, social profiles, contact, legal text, logo) under
  *Appearance > Customize > Lions International*.

`WP_DEBUG` is on in development; PHP errors go to `wp-content/debug.log` inside the
container (`make logs` or `make shell`).

Architecture details: [`docs/architecture.md`](docs/architecture.md).

## Composer

Dependencies are declared in `theme/composer.json`; `composer.lock` is committed, `vendor/` is not.

```bash
make composer                          # composer install (inside the container)
make composer ARGS="update timber/timber"
make composer ARGS="require vendor/package"
```

## Validation

```bash
make lint   # composer validate, php -l, PHPCS (WordPress Coding Standards), Twig syntax
make test   # PHPStan (level 6), theme structure validation, docker compose config
make cs-fix # phpcbf auto-fixes
```

CI (`.github/workflows/ci.yml`) runs the same checks on every push to `main` and every pull
request, plus a Docker Compose smoke test that boots WordPress, seeds content and requests
the homepage, a page, the stories index, search and a 404, and a job that builds the package.

## Build

```bash
make build            # -> build/lions-theme.zip
```

The package contains only what WordPress needs, including production Composer dependencies
(`vendor/` with Timber and Twig, no dev tools). Upload it via *Appearance > Themes > Add New >
Upload Theme* or unzip into `wp-content/themes/`. Rationale and deployment strategies:
[`docs/deployment.md`](docs/deployment.md).

## Server installation

Deploying to a real server (production is `https://lions-vallendar.org`, WordPress root
`/srv/www/wp_lions`). The server needs an installed WordPress, PHP 8.2+ **with the GD
extension** (the seeder generates the demo featured image) and WP-CLI.

### WP-CLI on Debian

Debian's packaged `wp-cli` lags upstream; install the phar, the same way
`docker/wordpress/Dockerfile` does:

```bash
sudo apt update
sudo apt install -y php-cli php-mysql php-xml php-mbstring php-curl php-zip php-gd curl

curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
php wp-cli.phar --info                  # sanity check before installing
chmod +x wp-cli.phar
sudo mv wp-cli.phar /usr/local/bin/wp
wp --info
```

Optionally verify the download first:

```bash
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar.sha512
sha512sum -c wp-cli.phar.sha512
```

### Theme and initial content

The repository is not needed on the server - the ZIP is self-contained (it carries
`vendor/`), and the two seeding scripts are copied alongside it. Build locally:

```bash
make build
scp build/lions-theme.zip bin/wp-install.sh bin/placeholder-image.php user@server:/tmp/
```

Then on the server, as the user owning the WordPress directory (typically `www-data`,
hence `sudo -u www-data`; as root, WP-CLI additionally needs `--allow-root`):

```bash
cd /srv/www/wp_lions

# must print https://lions-vallendar.org - every seeded permalink inherits it
sudo -u www-data wp option get home

sudo -u www-data wp theme install /tmp/lions-theme.zip --force --activate

sudo -u www-data env \
  WP_PATH=/srv/www/wp_lions \
  WORDPRESS_SITE_TITLE="Lions Vallendar" \
  WORDPRESS_LOCALE=de_DE \
  bash /tmp/wp-install.sh
```

`wp-install.sh` reads the site URL from the existing `home` option and skips
`wp core install` when WordPress is already set up, so it only creates pages, categories,
demo stories, both menus and the Customizer defaults. It is idempotent - existing content
is never overwritten - so it can be re-run after a theme update. Useful variables:

| Variable                | Default                      | Purpose                                  |
|-------------------------|------------------------------|------------------------------------------|
| `WP_PATH`               | `/var/www/html`              | WordPress root (the `wp-config.php` dir) |
| `WORDPRESS_URL`         | `http://localhost:8080`      | Only used when WordPress is *not* yet installed |
| `WORDPRESS_SITE_TITLE`  | `Lions Vallendar`            | Site title, re-applied on every run      |
| `WORDPRESS_LOCALE`      | `de_DE`                      | Installs and activates core translations |
| `CONTACT_EMAIL`         | `info@lion-example.com`      | Address used in Impressum, Datenschutz and the Customizer |

Afterwards, in wp-admin: re-save *Settings > Permalinks* if the host has to write rewrite
rules, and replace the placeholder phone number under
*Appearance > Customize > Lions International*.

Migration alternatives (seed locally, then move the database) and CI-based deployment:
[`docs/deployment.md`](docs/deployment.md).

## Release

```bash
# 1. bump "Version:" in theme/style.css and Theme::VERSION in theme/src/Theme.php, commit
# 2. tag and push
git tag 1.0.0
git push origin 1.0.0
```

Tags are plain versions (`1.0.0`), without a `v` prefix.

`.github/workflows/release.yml` checks that the tag matches the theme version, runs all
validation, builds `lions-theme.zip` and publishes a GitHub Release with the ZIP attached.

## Working with AI agents

Read [`AGENTS.md`](AGENTS.md). It states the non-negotiables (Timber/Twig split, no page
builders, centralised tokens, accessibility, validation) and where each kind of change goes.

## Brand assets

`theme/assets/images/logo.svg` is the Lions Clubs International emblem, a registered trademark.
Use it only in accordance with the organisation's brand guidelines. Photography is
represented by SVG placeholders in `theme/assets/images/placeholders/`; replace them with
licensed images (same aspect ratios) before launch.
