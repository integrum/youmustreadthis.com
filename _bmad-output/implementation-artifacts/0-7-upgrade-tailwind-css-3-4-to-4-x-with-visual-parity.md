# Story 0.7: Upgrade Tailwind CSS 3.4 to 4.x with visual parity

Status: done

<!-- BenjiID: 8ad9723e-8d94-4f76-9cea-0630af02ec5b -->
<!-- BenjiProjectID: 86f49183-aae5-45f7-9a71-05dc6ff462c3 -->

## Story

As a maintainer,
I want Tailwind CSS upgraded from 3.4 to 4.x with zero meaningful visual regression,
so that Dependabot can land security and feature updates without breaking the curated book list design.

## Acceptance Criteria

1. Baseline Playwright screenshots at 1440px and 390px for every page type in use; saved under `docs/visual-baseline/`.
2. Tailwind 4.x with migrated pipeline; `npm run build` green.
3. Post-upgrade pixel-diff vs baseline until every page matches.
4. PR supersedes Dependabot #10 with before/after/diff and diff percentages; comment on #10 (do not close).
5. `AGENTS.md` / README updated for new Tailwind conventions.

## Tasks / Subtasks

- [x] Add story to `epics.md` and `sprint-status.yaml` (Benji todo created)
- [x] Inventory page types (`scripts/visual-regression/pages.json`): homepage only in `_site/`; 404 probe URL (no custom `404.html`)
- [x] Baseline build on Tailwind 3.4.19; capture to `docs/visual-baseline/tw3/`
- [x] Run `npx @tailwindcss/upgrade`; add `@tailwindcss/cli`; remove `tailwind.config.js`
- [x] Visual compare iter 1: **0% diff** on all four captures (see `docs/visual-baseline/diff-iter1/summary.json`)
- [x] Production build re-check: **0% diff** (`docs/visual-baseline/diff-prod/summary.json`)
- [x] Update `AGENTS.md`, `README.md`, `_config.yml` excludes
- [x] Open PR; comment on Dependabot #10

## Dev Agent Record

### Page types covered

| ID | Template / layout | URLs |
|----|-------------------|------|
| homepage | `index.html` → `default.html` + header/footer | `/` |
| 404 | Jekyll/serve default (no repo `404.html`) | `/this-page-does-not-exist-yet/` |

### Visual regression iterations

1. After `@tailwindcss/upgrade` + first v4 build: **0 mismatched pixels** (all four PNG pairs).

### File List

- `_bmad-output/planning-artifacts/epics.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `_bmad-output/implementation-artifacts/0-7-upgrade-tailwind-css-3-4-to-4-x-with-visual-parity.md`
- `package.json`, `package-lock.json`
- `src/style.css` (v4 import, `@source`, v3 border compatibility layer)
- `tailwind.config.js` (removed)
- `_config.yml`
- `AGENTS.md`, `README.md`
- `scripts/visual-regression/*`
- `docs/visual-baseline/**`

### Change Log

- 2026-10-24: Tailwind 3.4.19 → 4.3.3 via official upgrade tool; `@tailwindcss/cli`; visual parity confirmed at 0% pixel diff.
