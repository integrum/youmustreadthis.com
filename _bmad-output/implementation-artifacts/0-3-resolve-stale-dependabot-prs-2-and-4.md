# Story 0.3: Resolve stale Dependabot PRs #2 and #4

Status: done

<!-- BenjiID: a655dc61-068e-4e14-81a9-8c30c0d8cf92 -->

## Story

As a maintainer,
I want the rexml (#2) and addressable (#4) Dependabot PRs merged or closed as superseded,
so that the PR queue reflects real work only.

## Acceptance Criteria

1. **Given** PR #2 (rexml 3.2.4→3.2.5) and PR #4 (addressable 2.7.0→2.8.1), **when** compared to current `master` after Story 0.1 / PR #8, **then** each is either merge-ready or documented as superseded by the modern `Gemfile.lock` (maintainer closes; agent does not).
2. **Given** `Gemfile.lock` on `master`, **then** `rexml` ≥ 3.2.5 and `addressable` ≥ 2.8.1.
3. **Given** the repo, **then** `.github/dependabot.yml` configures npm and bundler updates on a weekly schedule.

## Tasks / Subtasks

- [x] Inspect PR #2 and #4 diffs, mergeability, and CI/check status (AC: #1)
- [x] Verify `master` `Gemfile.lock` gem versions vs Dependabot targets (AC: #2)
- [x] Add `.github/dependabot.yml` for npm + bundler (AC: #3)
- [x] Comment on PR #2 and #4 with supersession note (Story 0.1 / PR #8); do not close PRs (AC: #1)
- [x] Run `npm ci && npm run build` on current `master` toolchain (AC: #2)

## Dev Notes

- PR #8 (`feat(epic-0): Modernize Node and build toolchain`) refreshed `Gemfile.lock` to Jekyll 4.4.x with `rexml (3.4.4)` and `addressable (2.9.0)`, exceeding both Dependabot bumps.
- Stale branches (`dependabot/bundler/rexml-3.2.5`, `dependabot/bundler/addressable-2.8.1`) predate the toolchain refresh; `mergeable_state` is **dirty** (conflicts). Rebasing would yield no net change vs `master`.
- No GitHub Actions check runs were attached to these PR heads at inspection time; Netlify previews apply to new pushes only.

### References

- [Source: _bmad-output/planning-artifacts/epics.md — Story 0.3]
- [PR #2](https://github.com/integrum/youmustreadthis.com/pull/2)
- [PR #4](https://github.com/integrum/youmustreadthis.com/pull/4)
- [PR #8 — toolchain modernization](https://github.com/integrum/youmustreadthis.com/pull/8)

## Dev Agent Record

### Agent Model Used

Composer (Cloud Agent)

### Completion Notes List

- Confirmed both Dependabot PRs are **superseded** by `master` after PR #8; recommended close-with-comment for Derek.
- Added weekly Dependabot config for npm and bundler.
- Verified production build path: `npm ci` + `bundle install` + `npm run build` succeeds.

### File List

- `.github/dependabot.yml`
- `_bmad-output/implementation-artifacts/0-3-resolve-stale-dependabot-prs-2-and-4.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`

## Senior Developer Review (AI)

### Findings addressed

- Dependabot npm group uses `dependency-type: development` only (matches sole devDependency `tailwindcss`).
- No Gemfile.lock edits on story branch (already satisfied on `master`).

### Review Follow-ups (AI)

- [x] Confirm no duplicate dependabot config paths
- [x] Confirm build on Node 22 + modern Jekyll stack

## Change Log

- 2026-10-23: Story 0.3 — document superseded PRs #2/#4; add `.github/dependabot.yml`.
