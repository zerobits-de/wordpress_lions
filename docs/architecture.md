# Architecture

## Request flow

```
Browser
  |
WordPress template hierarchy  (theme/front-page.php, page.php, single.php, ...)
  |   each file is three lines: instantiate a controller and call render()
Controller                    (theme/src/Controllers/*)
  |   templates(): ordered list of Twig candidates
  |   context():   Timber::context() + what the template needs
Timber::render(templates, context)
  |
Twig                          (theme/templates/*.twig extends base.twig)
  |-- partials/   header, footer, page-header, mobile-navigation, post-list
  |-- sections/   hero, feature, cards, statistics, stories, cta
  +-- components/ button, card, story-card, stat, image, navigation, breadcrumb,
                  logo, social-links, search-form, post-meta, pagination, subnav
```

## Bootstrap

```
functions.php
  -> require vendor/autoload.php   (Composer, PSR-4: Lions\Theme\ => src/)
  -> Lions\Theme\Theme::boot()
       -> Timber::init(); Timber::$dirname = ['templates', 'views']
       -> for each class in Theme::FEATURES: (new Feature())->register()
```

Feature classes (`src/Functions/`), each attaching hooks only:

| Class | Responsibility |
|---|---|
| `ThemeSupport` | theme supports, image sizes, editor styles, text domain |
| `Menus` | six menu locations: primary, utility, footer_1..3, legal |
| `Assets` | enqueues the ordered CSS files and the deferred `main.js` |
| `Customizer` | "Lions International" panel: CTA URLs, social profiles, contact, legal text |
| `Context` | `timber/context`: `site`, `menus`, `assets`, `theme_version` |
| `TwigExtensions` | `asset()`, `icon()` functions and the `tel` filter |
| `Seo` | Open Graph / Twitter meta, Organization + WebSite JSON-LD (disabled if an SEO plugin is active) |
| `Security` | removes generator tags, disables XML-RPC, generic login errors |

## Global Twig context

| Variable | Type | Notes |
|---|---|---|
| `site` | `Lions\Theme\Site` | `name`, `url`, `language_attributes`, `cta`, `social`, `contact`, `logo` |
| `menus.primary` / `menus.utility` / `menus.legal` | `Timber\Menu` or null | |
| `menus.footer` | list of `{title, menu}` | one per assigned footer location |
| `assets` | string | URL of `theme/assets` |
| `theme_version` | string | `Theme::VERSION` |
| `post`, `posts`, `user`, `theme`, `body_class`, ... | Timber defaults | |

## Content model

Native WordPress only:

- **Pages** (hierarchical) for the site structure. Pages with children get a sticky
  section navigation (`components/subnav.twig`).
- **Posts** = "Stories", with categories and tags. The posts page ("Stories") is set as
  `page_for_posts`.
- **Menus** for all navigation. **Customizer** for organisation data.
- **Front page**: the "Home" page's block content feeds the intro section; other homepage
  sections come from `src/Content/FrontPageContent.php`.

No custom post types are registered. Add one only when a content type has its own
fields, archive and permalink needs that pages/posts cannot express, and document it here.

## Deviations from the brief's suggested structure

- `src/Content/` was added (not in the brief) to hold homepage placeholder data separate
  from controllers, so it can later be replaced by an editor-facing solution.
- `src/Registrable.php` (interface) formalises how feature classes are registered.
- CSS is split by concern into several files and enqueued in order instead of a single
  `style.css`; `style.css` carries only the theme header. There is no build step for CSS/JS.
- The theme ships `theme.json` (settings only) so the block editor uses the brand palette
  and font sizes; the theme remains a classic (Timber) theme, not a block theme.
