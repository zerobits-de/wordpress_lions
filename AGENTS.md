# Instructions for AI coding agents

This file is read by Claude Code and other AI agents working in this repository.
Follow it in addition to any task-specific instructions.

## What this is

- A **custom WordPress theme** for a Lions International website, located in `theme/`.
- **Timber is mandatory.** Rendering goes through Timber (`Timber::render()`) and Twig.
- **Twig renders presentation** (`theme/templates/`, `theme/views/`). **PHP prepares data**
  (`theme/src/`). Do not put HTML blocks in PHP and do not put business logic in Twig.
- Local development runs in Docker (`make up`), the theme directory is bind-mounted, so
  edits are live on refresh. Composer runs inside the container (`make composer`).

## Architecture in one picture

```
WordPress template (page.php) -> Controller (src/Controllers) -> Timber context -> Twig
                                                                   |
                                     templates/*.twig (extends base.twig)
                                       -> views/sections/*  views/components/*  views/partials/*
```

- `theme/functions.php` only loads Composer and calls `Lions\Theme\Theme::boot()`.
- `src/Theme.php` boots Timber and registers feature classes from `src/Functions/`
  (each implements `Registrable::register()` and attaches hooks).
- `src/Site.php` extends `Timber\Site`; it is the `site` variable in Twig.
- `src/Controllers/*` map template-hierarchy entry points to Twig templates and context.
- `src/Components/*` prepare data for Twig components (e.g. breadcrumbs, inline icons).
- `src/Content/FrontPageContent.php` holds the homepage placeholder copy.
- Design tokens live in `theme/assets/css/tokens.css`. Everything else references them.

## Rules

1. **Do not introduce page builders** (Elementor, Divi, WPBakery, ...) or commercial themes.
2. **Do not introduce frontend frameworks** (React, Vue, Tailwind, jQuery plugins) unless a task
   explicitly requires it. The frontend is plain CSS and a single small `main.js`.
3. **Preserve the Lions visual system.** New colours, spacing or type sizes go into
   `tokens.css` as custom properties first; components use the variables. No one-off hex codes.
4. **Prefer reusable components.** Add a component when something is used twice or when it
   makes a template clearer. Do not over-abstract single-use markup.
5. **Keep responsive behaviour.** Test at 320, 375, 768, 1024, 1280, 1440 and 1920 px. No
   horizontal overflow. Breakpoints: 40em, 48em, 64em, 80em.
6. **Keep accessibility.** Semantic HTML, keyboard operability, visible focus, alt text,
   correct heading order (one `h1` per page), `prefers-reduced-motion` respected, colour is
   never the only signal.
7. **Escape output in Twig.** Timber's Twig environment does not autoescape. Values coming
   from theme data or options use `|e` / `|e('html_attr')` / `|esc_url`; WordPress-rendered
   HTML (`post.content`, titles from Timber) is output as Timber returns it.
8. **Sanitise input in PHP.** Customizer settings declare a sanitize callback; never trust
   request data; use capability checks and nonces for anything that writes.
9. **Do not copy source code from lionsclubs.org** and do not copy substantial text from it.
   The reference is for visual analysis only (see `docs/design.md`).
10. **Keep dependencies minimal.** Adding a Composer package needs a reason in the PR.
11. **Do not commit secrets.** `.env` is ignored; `.env.example` holds placeholders only.
12. **Prefer native WordPress features** (pages, posts, menus, Customizer, blocks) over custom
    post types or plugins. Document any new content model in `docs/architecture.md`.
13. **Verify Timber APIs against the installed version** (`theme/vendor/timber/timber`) rather
    than old tutorials. Timber 2.x is used.
14. **Run validation after significant changes**:

    ```
    make lint    # php -l, composer validate, PHPCS (WordPress standards), Twig syntax
    make test    # PHPStan, theme structure, docker compose config
    ```

    Both must pass before a PR. CI runs the same checks plus a Docker smoke test.

## Handy commands

| Task                              | Command                                    |
|-----------------------------------|--------------------------------------------|
| Start environment                 | `make up`                                  |
| Finish WP setup + demo content    | `make install`                             |
| Composer in the theme             | `make composer ARGS="require vendor/pkg"`  |
| WP-CLI                            | `make wp ARGS="option get siteurl"`        |
| Shell in container                | `make shell`                               |
| Build release ZIP                 | `make build`                               |

## Where things go

| Change                                  | Location                                             |
|-----------------------------------------|------------------------------------------------------|
| New page-level template                 | `templates/*.twig` + controller in `src/Controllers` |
| Reusable UI element                     | `views/components/*.twig` (+ CSS in `components.css`)|
| Homepage/landing section                | `views/sections/*.twig` (+ CSS in `sections.css`)    |
| Header/footer/etc.                      | `views/partials/*.twig`                              |
| WordPress hook / feature                | `src/Functions/*.php` (register in `Theme::FEATURES`)|
| Editor-managed option                   | `src/Functions/Customizer.php`                       |
| Colour/spacing/type value               | `assets/css/tokens.css`                              |
| Block/editor content styling            | `assets/css/content.css` (+ `theme.json`)            |
