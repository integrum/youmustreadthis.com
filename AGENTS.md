<!-- bmad:context -->
<!-- Verified 2026-10-18 against 0ad4cdd. Managed by bmad-project-context; edits inside this block are replaced on refresh. Keep anything you want preserved outside the markers. -->

## youmustreadthis.com

Derek Neighbors' curated "you must read these books" list. Jekyll 4.4 + Tailwind 4.x static site built by npm scripts, deployed by Netlify from `master`. Planning lives in `_bmad-output/planning-artifacts/epics.md`, tracking in `_bmad-output/implementation-artifacts/sprint-status.yaml`, and each story mirrors a Benji todo on the "You Must Read This" list (`1451c017-e249-464d-902a-fe2450508acc`).

## Policy

- Never push to `master`; branch + PR only. Netlify deploys `master` on merge, so merging is deploying.
- Code work needs a Benji story todo plus matching entries in `epics.md` and `sprint-status.yaml` (story key + `BenjiID`, epic `BenjiProjectID`); never ship orphan work.
- Implement stories with the `bmad-swarm` skill (`.agents/skills/bmad-swarm`), passing the story's BenjiID; do not hand-roll an agent run.
- Never hand-edit installer-managed BMAD files (`_bmad/config.toml`, `_bmad/config.user.toml`, `_bmad/*/config.yaml`, `bmad-*` skills); re-run `npx bmad-method@latest install --action quick-update`, and put overrides in `_bmad/custom/config.toml`.

## Where things are

- Book entries: `_books/<slug>.md` (front matter `title`, `author`, `amazon`, `image`; body is the blurb); covers in `img/`.
- Page shell: `_includes/header.html` (opens `<html>`/`<head>`) + `_layouts/default.html` + `_includes/footer.html` (closes `</body></html>`).
- Homepage listing: `index.html`; styles source `src/style.css` (`@import "tailwindcss"`, `@source` for `_site/**/*.html`); build pipeline is the `scripts` block in `package.json` (`@tailwindcss/cli`).

## Running and verifying

- Build with `npm run build` (`bundle exec jekyll build`, then the Tailwind CLI with `--minify` writes `_site/assets/css/style.css`; autoprefixer + minify are built into the CLI); plain `jekyll build` produces unstyled HTML.
- Local dev: `npm run dev` (`jekyll serve --watch --livereload` on port 4000 plus `tailwindcss --watch=always`); `_config.yml` `keep_files: [assets/css]` stops Jekyll regeneration from deleting the CSS.
- Netlify runs `JEKYLL_ENV=production npm run build`; analytics only renders when `jekyll.environment == "production"`.
- Pinned runtimes: Node 22 (`.nvmrc`, `package.json` engines, `netlify.toml` `NODE_VERSION`) and Ruby 3.4.x (`.ruby-version`, kept identical to `netlify.toml` `RUBY_VERSION`); Jekyll 4.4, Tailwind 4.x (`tailwindcss` + `@tailwindcss/cli`). Use these locally (e.g. `mise exec node@22 ruby@3.4.11 -- ...`), not the system defaults.
- There is no test suite; verify by building and checking `_site/` (and the Netlify deploy preview). Story 0.7 added Playwright pixel-diff scripts under `scripts/visual-regression/` and baselines under `docs/visual-baseline/`.

## Conventions that differ from defaults

- Tailwind `@source` scans `_site/**/*.html`, so CSS must be compiled after Jekyll builds; new classes only appear after a full `npm run build`.
- v4 default border color differs from v3; `src/style.css` keeps a small `@layer base` compatibility block (from `@tailwindcss/upgrade`) until explicit border utilities are added everywhere they matter.

## Known pitfalls

- `_books` has no `output: true`, so no per-book pages exist yet (Story 1.2); links to `/books/<slug>/` 404 today.

<!-- /bmad:context -->
