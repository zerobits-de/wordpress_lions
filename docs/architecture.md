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
                  logo, social-links, search-form, post-meta, pagination
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
| `Menus` | two menu locations: primary, legal |
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
| `menus.primary` / `menus.legal` | `Timber\Menu` or null | |
| `assets` | string | URL of `theme/assets` |
| `theme_version` | string | `Theme::VERSION` |
| `post`, `posts`, `user`, `theme`, `body_class`, ... | Timber defaults | |

## Content model

Native WordPress only:

- **Pages** (hierarchical) for the site structure.
- **Posts** = "Stories", with categories and tags. The posts page ("Stories") is set as
  `page_for_posts`.
- **Merged pages**: "Mitmachen" (`get-involved`) holds no content of its own. It stays
  published because `volunteer` and `donate` build their permalinks from it, and
  `src/Functions/Redirects.php` 301s it to `/get-involved/volunteer/`, which is the single
  join page. `Breadcrumbs` drops the parent for that child only, so "Spenden" keeps its
  full trail. Add another pair to `Redirects::MERGED` to merge more pages.
- **Menus** for all navigation. **Customizer** for organisation data and for the homepage
  hero background: `lions_hero_image_1..3` store attachment IDs picked with the media
  library. `Customizer::hero_image_ids()` skips empty slots, `FrontPageContent::hero()`
  turns them into Timber images, and `sections/hero.twig` stacks one `.hero__slide` per
  image. With none set the theme placeholder is used; with more than one, `main.js`
  cross-fades them.
- **Featured images** (`post-thumbnails`) on posts and pages. `single.twig` renders the
  thumbnail as a full-bleed hero at `lions-hero` under the header band, and shows no image
  block at all when a post has none. `components/story-card.twig` uses `lions-card` and
  does fall back to `assets/images/placeholders/story.svg`, so the archive grid stays even.
  Image sizes are declared in `src/Functions/ThemeSupport.php`.
- **Front page**: the intro block is edited under Customizer > Lions International >
  Homepage intro (`lions_intro_title`, `lions_intro_text`, `lions_intro_image` — the image
  as an attachment ID like the hero ones). `FrontPageContent::intro()` falls back to the
  "Home" page's block content when the text field is empty, then to the placeholder copy,
  and to `assets/images/placeholders/feature-1.svg` when no image is picked. Other homepage
  sections come from `src/Content/FrontPageContent.php`.
- **Homepage feature blocks**: posts in the category chosen under Customizer > Lions
  International > Homepage feature blocks (`lions_feature_category`) render as photo
  lockups between the statistics and "latest stories" sections. `FrontPageContent::feature_posts()`
  builds one block per post, alternating sides; an unset or deleted category renders
  nothing. Posts also stay in the "latest stories" grid, so a post can appear twice by
  design.

Uploads live in the `wp_data` volume. Docker creates that directory as `root`, which
makes every media upload in wp-admin fail, so `docker/wordpress/entrypoint.sh` hands
`wp-content/uploads` to the Apache user on each container start, and `bin/wp-install.sh`
does the same after WP-CLI (running as root) has imported the demo media.

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
