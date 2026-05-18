# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

Static website (Chinese, zh-CN) — a 20-page AI tools tutorial series served via nginx at `4si.cc`. Vanilla HTML/CSS/JS, no build step, no framework.

## Serving and deployment

- Document root: `/tmp/ai-tutorial`
- Nginx config at `/etc/nginx/sites-enabled/4si.cc` (HTTPS via Let's Encrypt, HTTP→HTTPS redirect)
- Reload nginx after changes: `sudo nginx -t && sudo systemctl reload nginx`
- SSL cert managed by certbot; auto-renews via systemd timer

## Asset cache busting

CSS and JS are versioned with query strings in HTML `<link>`/`<script>` tags. Bump the version when making changes:

- `style.css?v=5` — increment when CSS changes
- `app.js?v=1` — increment when JS changes

Find all references and update them together (grep for `style.css?v=` and `app.js?v=`).

## Page architecture

Two page templates, both loading `style.css` and `app.js`:

**Homepage** (`index.html`):
- `<div id="particles">` for the particle background effect
- `<header class="hero">` with `<div class="slideshow">` and `<div class="hero-stats">`
- `<main>` with `<section class="cards-section">` grids and `<section class="paths">`
- `<nav class="mobile-nav">` (hidden on desktop, fixed bottom bar on mobile ≤640px)
- `<footer>`

**Content/article pages** (e.g., `01-overview.html`):
- `<nav class="top-nav">` — sticky top bar with `← 首页` link and page title
- `<div class="content">` — article body; uses `.content h1–h4`, `.content pre`, `.content table` (wrapped in `.table-wrap`), `.content blockquote`, `.content code`
- Same `<nav class="mobile-nav">` and `<footer>` as homepage

**Index page** (`index-nav.html`) — follows the content page template with a full table-of-contents table.

## CSS architecture (`style.css`)

Single-file, ~230 lines. Dark theme via CSS custom properties in `:root`:
- `--bg: #0a0e14`, `--bg-card: #131820`, `--bg-hover: #1a2030`
- `--text: #c9d1d9`, `--text-dim: #8b949e`
- `--accent: #58a6ff` (blue), `--accent2: #f0883e` (orange), `--accent3: #d2a8ff` (purple)
- `--radius: 12px`, `--max-w: 860px`

Key patterns:
- Scroll reveal: `.reveal` elements animate in via IntersectionObserver (opacity + translateY)
- Cards: `.cards-grid` uses `grid-template-columns: repeat(auto-fill, minmax(260px, 1fr))`
- Responsive breakpoint: `max-width: 640px` — switches to single-column, shows mobile nav, adds padding to footer for bottom bar
- 3D tilt on cards: only on `(hover: hover)` (desktop), 8° max rotation
- Click ripple effect on `.card` and `.path` elements

## JavaScript (`app.js`)

IIFE, no dependencies. Modules:
1. **Particles** — creates 40 floating dots in `#particles`, random size/position/duration
2. **Slideshow** — auto-rotates every 4s, dot navigation, touch swipe support
3. **Scroll reveal** — IntersectionObserver at 15% threshold, adds `.visible` class
4. **Card 3D tilt** — mouse-follow perspective transform, desktop only
5. **Click ripple** — span-based ripple animation on card/path click
6. **Counter animation** — animates `.stat strong` numbers from 0 to target over 1.5s
7. **Parallax** — hero section translates on scroll with opacity fade

## Adding a new tutorial page

1. Copy any content page (e.g., `01-overview.html`) as a template
2. Follow the `NN-slug.html` naming convention
3. Update `<title>`, `<meta>` tags (description, og:title, og:description, og:url, canonical)
4. Update `.nav-title` text in the top nav bar
5. Add the card link in `index.html` under the appropriate `<section class="cards-section">`
6. Add the entry in `index-nav.html` table
7. Add a `<url>` entry in `sitemap.xml`
