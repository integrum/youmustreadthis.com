<!-- bmad:context -->
<!-- Verified 2026-10-18 against 0ad4cdd. Managed by bmad-project-context; edits inside this block are replaced on refresh. Keep anything you want preserved outside the markers. -->

## youmustreadthis.com

Derek Neighbors' curated "you must read these books" list. Jekyll + Tailwind 2 static site built by gulp, deployed by Netlify from `master`. Planning lives in `_bmad-output/planning-artifacts/epics.md`, tracking in `_bmad-output/implementation-artifacts/sprint-status.yaml`, and each story mirrors a Benji todo on the "You Must Read This" list (`1451c017-e249-464d-902a-fe2450508acc`).

## Policy

- Never push to `master`; branch + PR only. Netlify deploys `master` on merge, so merging is deploying.
- Code work needs a Benji story todo plus matching entries in `epics.md` and `sprint-status.yaml` (story key + `BenjiID`, epic `BenjiProjectID`); never ship orphan work.
- Implement stories with the `bmad-swarm` skill (`.agents/skills/bmad-swarm`), passing the story's BenjiID; do not hand-roll an agent run.
- Never hand-edit installer-managed BMAD files (`_bmad/config.toml`, `_bmad/config.user.toml`, `_bmad/*/config.yaml`, `bmad-*` skills); re-run `npx bmad-method@latest install --action quick-update`, and put overrides in `_bmad/custom/config.toml`.

## Where things are

- Book entries: `_books/<slug>.md` (front matter `title`, `author`, `amazon`, `image`; body is the blurb); covers in `img/`.
- Page shell: `_includes/header.html` (opens `<html>`/`<head>`) + `_layouts/default.html` + `_includes/footer.html` (closes `</body></html>`).
- Homepage listing: `index.html`; styles source `src/style.css`; build pipeline `gulpfile.babel.js`.

## Running and verifying

- Build with `npm run build` (gulp: `bundle exec jekyll build`, then Tailwind/PostCSS into `_site/assets/css/`); plain `jekyll build` produces unstyled HTML.
- Netlify runs `JEKYLL_ENV=production npm run build`; analytics only renders when `jekyll.environment == "production"`.
- Pinned runtimes: Node 12 (`.nvmrc`, `package.json` engines) and Ruby 2.7.2 (`.ruby-version`) until Story 0.1 lands; use those versions locally, not the system defaults.
- There is no test suite; verify by building and checking `_site/` (and the Netlify deploy preview).

## Conventions that differ from defaults

- Ignore `README.md` build/deploy notes; they are the upstream jekyll-starter-tailwind boilerplate, not this project's process.
- Tailwind purges against `_site/**/*.html`, so CSS must be compiled after Jekyll builds; new classes only appear after a full `npm run build`.

## Known pitfalls

- `_books` has no `output: true`, so no per-book pages exist yet (Story 1.2); links to `/books/<slug>/` 404 today.

<!-- /bmad:context -->
