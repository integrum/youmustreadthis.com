# You Must Read This

[youmustreadthis.com](https://youmustreadthis.com) is Derek Neighbors' curated list of books you must read. It is a small static site: Jekyll renders the pages from a `books` collection, Tailwind CSS styles them, and Netlify builds and hosts it.

## Prerequisites

- **Node 22** (pinned in `.nvmrc` and `package.json` `engines`)
- **Ruby** at the exact version in `.ruby-version` (3.4.x), plus Bundler (ships with Ruby)

The easiest way to get both is [mise](https://mise.jdx.dev/):

```sh
mise install node@22 ruby@3.4.11
mise exec node@22 ruby@3.4.11 -- npm run build   # run any command with the pinned runtimes
```

Keep the Ruby version in that command in step with `.ruby-version`. (mise only reads `.nvmrc`/`.ruby-version` on its own if idiomatic version files are enabled in your mise settings.)

nvm + rbenv (or similar) work too: `nvm use` reads `.nvmrc`, `rbenv install` reads `.ruby-version`. Do not rely on whatever system Node/Ruby happens to be installed.

## Install

```sh
bundle install
npm ci
```

## Build

```sh
npm run build
```

This runs `bundle exec jekyll build` (HTML into `_site/`) and then the Tailwind CLI, which scans `_site/**/*.html` and writes a purged, autoprefixed, minified `_site/assets/css/style.css`. (The "caniuse-lite is outdated" warning comes from the browserslist data bundled inside the Tailwind CLI and is harmless.) The order matters: CSS must be compiled after Jekyll, so new Tailwind classes only show up after a full build. A plain `jekyll build` gives unstyled HTML.

Netlify runs `JEKYLL_ENV=production npm run build`. Google Analytics only renders in production, so use that command when you need to check the production output.

## Local development

```sh
npm run dev   # or: npm start
```

Builds once, then runs `jekyll serve` with `--watch --livereload` on <http://localhost:4000/> alongside `tailwindcss --watch`. Editing templates or books regenerates the HTML, Tailwind rebuilds the CSS from the new HTML, and the browser reloads. Stop it with Ctrl-C. If port 4000 is already in use, Jekyll exits but the Tailwind watcher keeps running; Ctrl-C, free the port and retry. Dev CSS is not minified; run `npm run build` before inspecting production output.

## Deployment

Netlify builds and deploys the `master` branch (`netlify.toml`: build command, `_site/` publish dir, `NODE_VERSION`, `RUBY_VERSION`). Merging to `master` is deploying, so never push to `master` directly: open a branch and a pull request. Pull requests should get Netlify deploy previews (confirmed in Story 0.4).

## Adding or editing a book

Each book is a file in `_books/<slug>.md`:

```markdown
---
title: "The Book Title"
author: Author Name
amazon: "https://www.amazon.com/..."
image: cover-file.jpg
---
Why you must read it (the blurb shown on the homepage).
```

Put the cover image in `img/`; `image` is just the file name.

## Project layout

- `index.html` - homepage listing (all markup, Tailwind classes inline)
- `_layouts/default.html` - page layout
- `_includes/header.html` - opens `<html>`/`<head>`, loads `/assets/css/style.css` and analytics (production only)
- `_includes/footer.html` - closes `</body></html>`
- `_books/` - book entries; `img/` - cover images
- `src/style.css` - Tailwind 4 entry (`@import "tailwindcss"`, `@source` scans `_site/**/*.html` after Jekyll build)
- `_config.yml` - Jekyll config; `netlify.toml` - Netlify build settings

## License

[MIT](LICENSE.md)
