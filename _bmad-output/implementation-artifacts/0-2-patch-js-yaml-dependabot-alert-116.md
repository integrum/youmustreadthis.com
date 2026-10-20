# Story 0.2: Patch js-yaml Dependabot alert #116

Status: done

<!-- BenjiID: bd8c50cf-a34e-47c8-936c-5295f1bc41f6 -->

## Story

As a maintainer,
I want the high-severity js-yaml advisory (GHSA-2883-xcg3-v3hh) resolved in package-lock.json,
so that the repo has no open high-severity Dependabot alerts for this transitive dependency.

## Acceptance Criteria

1. **Given** `package-lock.json` pins transitive `js-yaml` via `cosmiconfig` (through `gulp-postcss` → `postcss-load-config`), **when** dependencies are installed, **then** `npm ls js-yaml` shows only `3.15.2` (patched for GHSA-2883-xcg3-v3hh).
2. **Given** the lockfile change, **when** Dependabot re-scans, **then** alert #116 closes as fixed.
3. **Given** the repo toolchain, **when** `npm audit` runs after install, **then** `js-yaml` is not reported vulnerable for GHSA-2883-xcg3-v3hh (other unrelated advisories may remain until Story 0.1/0.3).
4. **Given** production build path, **when** `npm run build` runs on Node 12 + Ruby 2.7.2, **then** Jekyll and Tailwind compile successfully.

## Tasks / Subtasks

- [x] Identify js-yaml resolution path in lockfile (AC: #1)
  - [x] Confirm `cosmiconfig@5.2.1` requires `js-yaml@^3.13.1`
- [x] Bump lockfile `js-yaml` from `3.14.1` to `3.15.2` (AC: #1, #2, #3)
  - [x] Update both `packages` and legacy `dependencies` entries with correct integrity
- [x] Verify with `npm ci` and `npm ls js-yaml` (AC: #1)
- [x] Run `npm audit` and confirm GHSA-2883-xcg3-v3hh no longer applies to installed js-yaml (AC: #3)
- [x] Run `npm run build` (AC: #4)

## Dev Notes

- Minimal change: **only** `package-lock.json`; no `package.json` dependency additions.
- Patched version `3.15.2` satisfies `^3.13.1` and fixes GHSA-2883-xcg3-v3hh (`>=3.0.0 <3.15.2`).
- Do not run `npm install` with npm 6 without care — it can rewrite lockfile v2 → v1; prefer manual lockfile bump + `npm ci`.

### Project Structure Notes

- Build: `npm run build` → gulp → `bundle exec jekyll build` + Tailwind/PostCSS.

### References

- [Source: _bmad-output/planning-artifacts/epics.md — Story 0.2]
- [Advisory: GHSA-2883-xcg3-v3hh](https://github.com/advisories/GHSA-2883-xcg3-v3hh)

## Dev Agent Record

### Agent Model Used

Composer (Cloud Agent)

### Completion Notes List

- Bumped `js-yaml` in `package-lock.json` from 3.14.1 → 3.15.2 (transitive via cosmiconfig).
- Verified `npm ls js-yaml` shows single version 3.15.2 after `npm ci`.
- `npm run build` succeeded (Jekyll + Tailwind).

### File List

- `package-lock.json`

## Senior Developer Review (AI)

### Findings addressed

- Confirmed lockfile-only diff (no spurious lockfileVersion downgrade).
- Confirmed patched version matches npm registry integrity for 3.15.2.

### Review Follow-ups (AI)

- [x] Validate no `3.14.x` remains in lockfile
- [x] Validate build pipeline after lockfile change

## Change Log

- 2026-10-20: Patch js-yaml 3.14.1 → 3.15.2 in package-lock.json for Dependabot #116 / GHSA-2883-xcg3-v3hh.
