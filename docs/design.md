# Design analysis and design system

This document records what was extracted from the visual analysis of
[lionsclubs.org](https://www.lionsclubs.org/) and how it maps to the theme's
design tokens. No source code, markup or copy was taken from the reference;
values below come from observing the rendered site in a browser.

## What makes the reference recognisable

| Aspect | Observation | Theme decision |
|---|---|---|
| Colour | A strong royal blue (`rgb(10 61 171)`) for primary actions and links, a warm yellow (`rgb(249 201 16)`) for the main call to action and accent rules, deep navy (`rgb(13 34 64)`) for the footer and dark bands, purple (`rgb(139 41 148)`) as a secondary accent. Page background is a very light gray (`#f6f6f6`), content sits in white panels. | `--color-primary`, `--color-accent`, `--color-navy`, `--color-purple`, `--color-background`, `--color-surface` in `tokens.css`. |
| Typography | Helvetica Neue throughout: light weight body at 16/24, bold headings (~62px hero, 42px section titles, 36px feature titles), slightly tracked. | System Helvetica Neue / Arial stack, no webfont. Fluid sizes via `clamp()`: `--text-3xl` (36-62px), `--text-2xl` (28-42px). |
| Section headings | Left-aligned bold heading with a short yellow rule underneath. | `.section-title::after` (4.5rem x 4px, `--color-accent`). |
| Buttons | 5px radius, bold label, generous padding (~14px 30px). Blue "Join", yellow "Donate", purple secondary, white outline on dark. | `.btn` with variants `primary`, `accent`, `purple`, `outline`, `outline-light`, `link`. |
| Header | Two tiers: logo row with Join/Donate, then the bold primary navigation. Collapses to one compact sticky row on scroll. | `partials/header.twig` + `header.css`; `is-compact` class toggled by `main.js`. |
| Hero | Full-bleed photograph with a dark overlay, very large white headline, yellow sub-line, centred. | `sections/hero.twig`, `.hero` with gradient overlay. Up to three backgrounds are set in the Customizer and cross-fade every 6s (`--transition-slow`); reduced motion keeps the first one. |
| Photo lockups | Two-column panels where the photograph has a slanted edge and the text column has heading, rule, copy and one button. Alternates image left/right. | `sections/feature.twig` with `clip-path` diagonal (`--angle-cut`) on >= 64em. |
| Statistics | Four full-height tiles in navy / purple / blue / gradient, big yellow number, white label. | `sections/statistics.twig` + `.stat--{tone}`. |
| Cards | White card, image on top, a coloured label band with a slanted right edge overlapping the image bottom, navy title. | `components/card.twig`, `.card__band` with `clip-path`. |
| Footer | Compact navy band: brand on the left, then social icons, the contact email and the legal links on the right. Wraps to a stack on narrow screens. | `partials/footer.twig` + `footer.css`. |
| Whitespace | Large vertical rhythm (~64-96px) inside white panels; panels inset from the page edge. | `--panel-padding-y`, `--panel-padding-x`, `--section-gap`. |
| Imagery | Photography of real people serving is central. | Placeholder SVG illustrations in brand colours are used until licensed photography is available (`assets/images/placeholders/`). Replace them, keep the crops (16:9 hero, 3:2 feature, 8:5 card). |

## Token overview

```
Colours   --color-primary/-dark/-light, --color-navy/-700, --color-accent/-dark,
          --color-purple/-dark, --color-green/-dark, --color-background,
          --color-surface/-muted, --color-text/-inverse, --color-muted,
          --color-border/-strong, --color-overlay, --color-focus/-inverse
Type      --font-sans, --text-xs ... --text-3xl, --text-stat, --leading-*, --tracking-*
Spacing   --space-1 (4px) ... --space-9 (96px), --section-gap, --panel-padding-x/y
Layout    --container-width (1320px), --container-narrow (768px), --container-padding, --header-height
Shape     --radius-sm/md/lg/full, --shadow-sm/md/lg, --transition-fast/base, --angle-cut
```

Breakpoints (used literally in media queries): 40em, 48em, 64em, 80em.

## Design iteration workflow

1. Look at the reference for the pattern you need.
2. Decide the value (colour, spacing, size).
3. Add or reuse a token in `tokens.css`.
4. Build or extend a component in `views/components` with its CSS in `components.css`
   (or a section in `views/sections` + `sections.css`).
5. Use it from a template.
6. Check in the browser at the breakpoints listed in AGENTS.md.
7. Iterate. If a value is reused, it belongs in `tokens.css`.

## Accessibility notes

- Yellow (`#f9c910`) on white does not meet AA for text; it is used only for accent rules,
  large numbers on navy and button backgrounds with dark text.
- Blue `#0a3dab` on white: 8.6:1. White on navy `#0d2240`: 15:1. White on purple `#8b2994`: 7.2:1.
- Focus rings are blue on light backgrounds and yellow on dark ones (`--color-focus-inverse`).
