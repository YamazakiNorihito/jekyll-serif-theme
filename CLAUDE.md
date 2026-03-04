# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A personal tech blog and learning platform ("だらけた日記") built with Jekyll 4.2+, customized from the Zerostatic Jekyll Serif Theme. The site is in Japanese and deployed to Azure Static Web Apps at blog.nybeyond.com.

## Development Commands

```bash
# Install dependencies
bundle install

# Local development server (localhost:4000)
bundle exec jekyll serve

# Docker development (localhost:4030)
docker-compose up

# Production build
bundle exec jekyll build --config _config.yml,_config.prod.yml
```

All Jekyll source files live under `src/` (configured as the Jekyll source directory).

## Architecture

### Content Collections

The site has two Jekyll collections defined in `src/_config.yml`:

- **`_learning/`** — 156+ markdown posts of personal learning notes (AWS, Go, Docker, Android, etc.). Uses `learning.html` layout. Sorted by weight. Supports tags for related posts and optional Mermaid diagrams.
- **`_tech/`** — Tech category index pages (e.g., `docker.md`, `go.md`). Pages with `is_category_index: true` use `category.html` layout to list related learning posts. Other pages use `service.html` layout.

### Layout Hierarchy

```
default.html          — Base layout (header, footer, Google Analytics)
├── home.html         — Homepage (index.md)
├── learnings.html    — Learning collection listing (learning.md)
├── tech.html         — Tech categories listing (tech.md)
├── learning.html     — Single learning post
├── service.html      — Single tech post
├── category.html     — Tech category page (filters learning posts)
└── page.html         — Generic page (about.md)
```

### Styling

- Bootstrap 4.6 grid system (only grid/utilities, not full Bootstrap)
- SCSS organized in `_sass/components/` (19 files) and `_sass/pages/`
- Entry point: `assets/css/style.scss`
- Primary color: #e5261f, Secondary: #f88379

### Data Files (`_data/`)

- `menus.yml` — Navigation structure
- `features.json` — Homepage feature blocks
- `seo.yml` — SEO metadata

## Deployment

GitHub Actions workflow (`.github/workflows/azure-static-web-apps-victorious-moss-085cf2e00.yml`) builds with Ruby 3.2.2 and deploys to Azure Static Web Apps on push to `master`.

## Content Conventions

Learning posts use this front matter pattern:
```yaml
---
title: "Post Title"
date: YYYY-MM-DD
weight: N
tags: [tag1, tag2]
description: "Short description"
mermaid: true  # optional, enables Mermaid diagrams
---
```

Tags drive the related posts widget (`_includes/similar_posts.html`).
