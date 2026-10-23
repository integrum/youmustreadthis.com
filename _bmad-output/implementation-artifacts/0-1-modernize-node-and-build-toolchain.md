# Story 0.1: Modernize Node and build toolchain

Status: review

<!-- BenjiID: b485e1f8-3fc8-42b0-acc9-3b7a2730e361 -->
<!-- BenjiProjectID: 86f49183-aae5-45f7-9a71-05dc6ff462c3 -->

## Story

As a maintainer of youmustreadthis.com,
I want the site to build on a supported Node LTS, Ruby, Jekyll and Tailwind toolchain,
so that Netlify builds succeed and dependency upgrades are no longer blocked.

## Acceptance Criteria

1. **Given** the repo, **when** I inspect `.nvmrc`, `package.json` `engines` and `netlify.toml` `[build.environment]`, **then** all three pin Node 22 (current LTS line allowed by the epic: "20 or 22"; Node 20 reached EOL 2026-04-30 so 22 is the only valid choice), and no reference to Node 12 remains anywhere in the repo (excluding `_bmad*` history and story files).
2. **Given** `.ruby-version`, `Gemfile` and `Gemfile.lock`, **when** I run `bundle install && bundle exec jekyll build` under the pinned Ruby, **then** Ruby is a supported 3.4.x patch, Jekyll resolves to 4.4.x (`gem "jekyll", "~> 4.4"`), the build succeeds with no errors, and `Gemfile.lock` lists the `x86_64-linux` platform (Netlify) and contains `rexml >= 3.2.5` and `addressable >= 2.8.1` (side effect consumed by Story 0.3).
3. **Given** the npm toolchain, **when** I run `npm ci && npm run build` (and `JEKYLL_ENV=production npm run build`, which is what Netlify runs), **then** gulp, gulp-postcss, Babel (`babel-preset-env`, `babel-register`, `.babelrc`), browser-sync, cross-env, cross-spawn, postcss-import and the standalone cssnano/autoprefixer/postcss pins are gone, Tailwind is upgraded to 3.4.x, and `_site/` is produced with a purged, autoprefixed, minified `_site/assets/css/style.css`.
4. **Given** the before and after builds, **when** the homepage is rendered at desktop (1280px) and mobile (390px) widths, **then** it is visually unchanged; before/after screenshots for both widths are attached to (or linked from) the PR description.
5. **Given** `README.md`, **when** a new contributor reads it, **then** the upstream jekyll-starter-tailwind boilerplate (badges, contributors table, Deploy-to-Netlify button, gulp/BrowserSync text) is gone and replaced by real project instructions: prerequisites (mise or nvm/rbenv with the pinned versions), install, build, local dev server, how Netlify deploys, and where book entries live.
6. **Given** `npm audit` and `bundle exec jekyll build` after the upgrade, **when** run, **then** `npm audit` reports no high/critical issues (the gulp/babel tree that held most advisories is removed), and `npm ls js-yaml` shows no vulnerable version (keeps Story 0.2's fix intact; js-yaml may disappear entirely).
7. **Given** `AGENTS.md` (not installer-managed), **when** this story lands, **then** its "Running and verifying", "Pinned runtimes" and gulp/Tailwind notes describe the new pipeline (no "Node 12 ... until Story 0.1 lands", no gulp).

## Tasks / Subtasks

Task groups are labelled; groups B, C, D, E touch disjoint files and can run in parallel. Group A can run in parallel with everything (it works from a separate checkout of `master`). Group F runs last.

- [x] **Group A - Baseline "before" capture** (AC: #4)
  - [x] A.1 Create a throwaway checkout of `master` outside this worktree (e.g. `git worktree add /tmp/ymrt-before master`) - do not modify this worktree.
  - [x] A.2 Build the "before" site with the old toolchain. Try in order and record which one worked in Completion Notes:
    1. `mise exec node@12 ruby@2.7.2 -- bash -c 'bundle install && npm ci && JEKYLL_ENV=production npm run build'` (Ruby 2.7.2 may fail to compile against OpenSSL 3 on Arch - if so go to 2).
    2. Build HTML with any working Ruby (`mise exec ruby@3.4 -- bundle exec jekyll build` after temporarily `bundle update` in the throwaway checkout only - template output is identical between Jekyll 4.2 and 4.4), then compile CSS with the original gulp task under Node 12: `mise exec node@12 -- npx gulp processStyles` with `NODE_ENV=production`.
    3. Last resort: screenshot the live site https://youmustreadthis.com (note in PR that live may be a stale 2021 artifact; Story 0.4 verifies that).
  - [x] A.3 Save `/tmp/ymrt-before/_site/assets/css/style.css` as the baseline CSS for diffing.
  - [x] A.4 Serve the before `_site` (`python3 -m http.server 4001 -d /tmp/ymrt-before/_site`) and capture full-page screenshots: `chromium --headless --disable-gpu --hide-scrollbars --window-size=1280,6000 --screenshot=/tmp/ymrt-shots/before-1280.png http://localhost:4001/` and the same at `--window-size=390,12000` (`before-390.png`). Screenshots are PR artifacts only; do NOT commit them.

- [x] **Group B - Ruby / Jekyll** (AC: #2) - files: `.ruby-version`, `Gemfile`, `Gemfile.lock`
  - [x] B.1 Set `.ruby-version` to an exact supported 3.4 patch (3.4.6 is already installed via mise locally; any 3.4.x >= 3.4.6 is fine - prefer the newest 3.4 patch mise/Netlify can install, latest upstream is 3.4.12). Netlify installs the version in `.ruby-version` automatically.
  - [x] B.2 Change `Gemfile` to `source "https://rubygems.org"` + `gem "jekyll", "~> 4.4"`. Do not add plugins (jekyll-seo-tag/jekyll-sitemap belong to Stories 1.3/1.4).
  - [x] B.3 Regenerate the lockfile from scratch: `rm Gemfile.lock && mise exec ruby@<pinned> -- bundle install`, then `bundle lock --add-platform x86_64-linux` (keep `ruby` platform; add `arm64-darwin`/`x86_64-darwin` only if harmless). `BUNDLED WITH` becomes the Bundler shipped with Ruby 3.4.
  - [x] B.4 Verify `grep -E '^    (rexml|addressable|jekyll) ' Gemfile.lock` shows jekyll 4.4.x, rexml >= 3.2.5, addressable >= 2.8.1; record the exact versions in Completion Notes for Story 0.3.
  - [x] B.5 `bundle exec jekyll build` succeeds with no errors (deprecation warnings from sass-embedded/csv are acceptable if build succeeds; note them).

- [ ] **Group C - Node / CSS pipeline** (AC: #1, #3, #6) - files: `.nvmrc`, `package.json`, `package-lock.json`, `tailwind.config.js`, `src/style.css` (only if needed), `_config.yml`, delete `gulpfile.babel.js` and `.babelrc`
  - [x] C.1 `.nvmrc` -> `22`.
  - [x] C.2 Rewrite `package.json`:
    - `name: "youmustreadthis"`, `private: true`, real `description`, `repository` -> `https://github.com/integrum/youmustreadthis.com.git`, drop upstream `main`, `bugs`, `publishConfig`, author -> Derek Neighbors / Integrum (keep `license: MIT`, LICENSE.md untouched).
    - `engines: { "node": ">=22 <23" }` (or `"22.x"`).
    - `devDependencies`: only `tailwindcss` pinned to `3.4.19` (exact or `~3.4.19`). Tailwind 3.4's CLI already runs autoprefixer and, with `--minify`, cssnano (it lazy-loads its bundled copies when no local package exists - verified in `tailwindcss/lib/cli/build/plugin.js` and `deps.js`), so no separate postcss/autoprefixer/cssnano/postcss-cli deps are required. If you prefer explicit pins, `autoprefixer@^10.4` + `postcss@^8.5` are acceptable; do not add a `postcss.config.js` (the CLI would switch to it and drop the built-in pipeline).
    - Remove: `gulp`, `gulp-postcss`, `babel-preset-env`, `babel-register`, `browser-sync`, `cross-env`, `cross-spawn`, `postcss-import`, `cssnano`, `postcss`, `autoprefixer` (unless explicitly kept per above).
    - `scripts`:
      - `"build:jekyll": "bundle exec jekyll build"`
      - `"build:css": "tailwindcss -i src/style.css -o _site/assets/css/style.css --minify"`
      - `"build": "npm run build:jekyll && npm run build:css"`
      - `"dev": ...` local dev loop (see Dev Notes "Local dev loop"); `"start": "npm run dev"`.
      - Drop `build:production` / `build:dev` (or alias them to `build` if you want backward compat - one line each, no cross-env).
  - [x] C.3 Delete `gulpfile.babel.js` and `.babelrc`.
  - [x] C.4 `tailwind.config.js` -> Tailwind 3 shape: `content: ["./_site/**/*.html"]` (replaces v2 `purge`), drop `variants`, keep `theme.extend: {}`, `plugins: []`. Keep CommonJS `module.exports`.
  - [x] C.5 `src/style.css` stays `@tailwind base; @tailwind components; @tailwind utilities;` (valid in v3) - no change expected.
  - [x] C.6 `_config.yml`: remove `gulpfile.babel.js` from `exclude` (file is gone); add `keep_files: [assets/css]` so `jekyll serve`/`--watch` rebuilds don't delete the Tailwind output during dev. Do not change `collections` or anything Epic 1 owns.
  - [x] C.7 Regenerate the lockfile under Node 22: `rm -rf node_modules package-lock.json && mise exec node@22 -- npm install` (lockfileVersion 3). Then `npm ci` must succeed.
  - [ ] C.8 `npm audit` -> 0 high/critical; `npm ls js-yaml` -> none or patched only (AC #6). Record output summary in Completion Notes.

- [x] **Group D - Netlify build environment** (AC: #1) - file: `netlify.toml`
  - [x] D.1 Add `[build.environment]` with `NODE_VERSION = "22"` (and `RUBY_VERSION` matching `.ruby-version` exactly, for belt-and-braces; Netlify reads `.ruby-version` too). Keep `command = "JEKYLL_ENV=production npm run build"` and `publish = "_site/"` unchanged.
  - [x] D.2 Do not add deploy-preview/context config - Story 0.4 owns the rest of `netlify.toml` and the deploy-log verification.

- [x] **Group E - Documentation** (AC: #5, #7) - files: `README.md`, `AGENTS.md`
  - [x] E.1 Rewrite `README.md` from scratch (drop all upstream content incl. All Contributors table and Deploy button). Sections: what the site is (one paragraph), Prerequisites (Node 22 via `.nvmrc`, Ruby from `.ruby-version`, Bundler; `mise install` picks up both files - mention `mise exec -- ...` or `nvm use`/`rbenv`), Install (`bundle install`, `npm ci`), Build (`npm run build`; production analytics only render with `JEKYLL_ENV=production npm run build`), Local dev (`npm run dev`, URL/port), How it's deployed (Netlify builds `master`; merging = deploying; PRs get deploy previews - Story 0.4), Adding/editing a book (`_books/<slug>.md` front matter `title`, `author`, `amazon`, `image`; cover in `img/`), Project layout pointers (`_includes/header.html`, `_layouts/default.html`, `_includes/footer.html`, `index.html`, `src/style.css`, `tailwind.config.js`). Keep the MIT license line.
  - [x] E.2 Update `AGENTS.md`: "Build with `npm run build` (gulp: ...)" -> describe the npm-script pipeline (`bundle exec jekyll build` then Tailwind CLI into `_site/assets/css/`); replace the "Pinned runtimes: Node 12 ... Ruby 2.7.2 ... until Story 0.1 lands" bullet with the new pins (Node 22, Ruby 3.4.x, Jekyll 4.4, Tailwind 3.4); keep the "Tailwind purges against `_site/**/*.html`" pitfall (now `content` instead of `purge`). Remove the "Ignore `README.md` build/deploy notes" bullet since README becomes authoritative. Do not touch `CLAUDE.md` (it only includes AGENTS.md).

- [x] **Group F - Integration verification** (AC: #2, #3, #4, #6) - runs after B, C, D, E
  - [x] F.1 Clean build from scratch with pinned runtimes: `rm -rf _site .jekyll-cache node_modules && mise exec -- bash -c 'bundle install && npm ci && JEKYLL_ENV=production npm run build'`.
  - [x] F.2 Check `_site/index.html` exists, contains all 10 books and the gtag snippet (production env), and `_site/assets/css/style.css` exists, is minified (single/few lines), and contains the classes used in `index.html` (spot check: `.text-indigo-600`, `.sm\:flex-row`, `.space-y-16`, `.bg-gradient-to-b`, `.xl\:inline`, `.md\:text-6xl`). Confirm vendor prefixes are present where autoprefixer would add them (e.g. `-webkit-` on `appearance`/`text-size-adjust` in preflight).
  - [x] F.3 Diff the after CSS against the Group A baseline: `npx prettier --parser css` both files (or `npx -y prettier`) and review differences; expected deltas are Tailwind 3's CSS-variable based shadows/transforms/gradients and preflight additions, not changed colors/sizes.
  - [x] F.4 Capture after screenshots with the same chromium commands as A.4 (`after-1280.png`, `after-390.png`) against `python3 -m http.server 4002 -d _site`. Compare visually (and optionally `compare -metric AE` with ImageMagick if available). Any visible difference must be fixed (see Dev Notes "Tailwind 2 -> 3 parity") or explicitly justified in the PR.
  - [x] F.5 `npm audit` (no high/critical), `npm ls js-yaml`, `grep -rn "node.*12\|gulp\|babel" --exclude-dir=node_modules --exclude-dir=_site --exclude-dir=_bmad --exclude-dir=_bmad-output --exclude-dir=.agents --exclude-dir=.claude .` returns nothing relevant.
  - [x] F.6 `npm run dev` smoke test: site serves locally, editing `index.html` rebuilds HTML and CSS.
  - [x] F.7 PR description: attach/link before + after screenshots for 1280 and 390 widths, list the version matrix (Node, Ruby, Bundler, Jekyll, Tailwind), state which baseline method from A.2 was used, and note the Gemfile.lock rexml/addressable versions for Story 0.3. Netlify deploy preview link (if Netlify posts one) is a bonus; formal verification is Story 0.4.

## Dev Notes

### Current state (what you are replacing)

- `package.json` is still the upstream `jekyll-starter-tailwind` v6.0.0 manifest: gulp 4 + `gulpfile.babel.js` (ES modules via `babel-register` + `babel-preset-env` 1.x, which is why Node 12 is pinned), gulp-postcss 9, postcss 8.2.13, postcss-import 14, tailwindcss 2.1.2, autoprefixer 10.2.5, cssnano ^5, browser-sync 2.26, cross-env, cross-spawn. `engines.node: "12"`.
- Gulp pipeline (`gulpfile.babel.js`): `buildJekyll` spawns `bundle exec jekyll build` (`--incremental` in dev) -> `processStyles` runs `src/style.css` through postcss-import + tailwind + (prod only) autoprefixer + cssnano into `_site/assets/css/`. `serve` adds BrowserSync on port 4000 watching sources.
- `tailwind.config.js` uses v2 `purge: ["_site/**/*.html"]` and `variants: {}`. `src/style.css` is the three `@tailwind` directives.
- `netlify.toml`: `command = "JEKYLL_ENV=production npm run build"`, `publish = "_site/"`, no `[build.environment]`.
- Ruby: `.ruby-version` 2.7.2 (EOL 2023), `Gemfile` = `gem 'jekyll'` unpinned, `Gemfile.lock` has jekyll 4.2.0, rexml 3.2.4, addressable 2.7.0, Bundler 2.1.2, `PLATFORMS ruby` only.
- Pages: `index.html` (all markup, inline Tailwind classes), `_layouts/default.html`, `_includes/header.html` (UA gtag in production, stylesheet `{{ site.baseurl }}/assets/css/style.css`), `_includes/footer.html`. 10 books in `_books/`, covers in `img/`.

### Key design decision: drop gulp/Babel/BrowserSync, use npm scripts + Tailwind 3.4 CLI

Recorded decision for this story:

- **Pipeline:** `npm run build` = `bundle exec jekyll build` then `tailwindcss -i src/style.css -o _site/assets/css/style.css --minify`. Ordering is mandatory: Tailwind scans `_site/**/*.html` (AGENTS.md pitfall), so CSS must compile after Jekyll. Two sequential npm scripts replace ~80 lines of gulp + Babel + 10 devDependencies. Babel existed only to run the ES-module gulpfile; it goes with gulp.
- **Minify + autoprefixer equivalence:** Tailwind 3.4 CLI applies autoprefixer by default (disable flag is `--no-autoprefixer`) and cssnano (`preset default`, `cssDeclarationSorter: false`) when `--minify` is passed; it inlines `@import` with postcss-import too. This equals the old production gulp chain (postcss-import -> tailwind -> autoprefixer -> cssnano). Autoprefixer targets come from browserslist defaults (no `browserslist` key exists today, so behaviour is unchanged).
- **Why Tailwind 3.4, not 4:** v2 -> v3 is mostly config renames (`purge` -> `content`, `variants` removed), and the v3 `gray`/`indigo` palettes are the same hex values as v2's defaults (v2 `gray` was already the "coolGray" palette that v3 calls `gray`; e.g. gray-50 `#f9fafb`, indigo-600 `#4f46e5`). Tailwind 4 rewrites colors to OKLCH (visibly shifted hues), renames the shadow/rounded/blur scales (`shadow-sm` -> `shadow-xs`, etc.), changes the default border color and other preflight defaults, removes `transform`-style helpers and moves configuration to CSS (`@import "tailwindcss"`, `@theme`) with a different CLI package (`@tailwindcss/cli`). That breaks AC #4 ("visually unchanged") for no benefit on a 1-page site. A v4 migration can be its own future chore story if wanted. Tailwind 3.4.19 is the latest v3 (checked 2026-10-22).
- **Node 22:** The epic AC allows 20 or 22. Node 20 is EOL (2026-04-30); Node 22 is Maintenance LTS until 2027-04-30. Node 24 is now Active LTS, but it is outside the epic's AC wording - stay on 22 for this story and flag 24 as a follow-up (a one-line change in `.nvmrc`, `engines` and `NODE_VERSION`). Locally available via mise: 22.23.3.
- **Ruby 3.4 + Jekyll 4.4:** Jekyll 4.4.1 (latest) declares `csv`, `base64`, `json` and `webrick` as runtime deps, which is what makes it clean on Ruby 3.4 (those left default gems). Jekyll 4.4 allows `jekyll-sass-converter` 3.x, which pulls `sass-embedded` + `google-protobuf` platform-specific gems - this is why the lockfile needs `x86_64-linux` for Netlify. The site has no Sass, so the converter is inert. Ruby 3.4 is supported upstream until ~2028 (latest patch 3.4.12). Ruby 4.0 exists but is avoided for gem-compat risk (eventmachine/ffi native builds).

### Tailwind 2 -> 3 parity checklist (AC #4)

Classes used in `index.html`: layout (`relative`, `absolute`, `hidden sm:block`, `inset-y-0`, `max-w-*`, `mx-auto`, `flex`, `flex-col`, `sm:flex-row`, `space-y-16`, `w-full`, `sm:w-1/3`, `sm:w-48`), typography (`text-4xl..6xl`, `tracking-tight`, `font-extrabold`, `text-gray-*`, `text-indigo-*`, `hover:underline`), decoration (`bg-gray-50`, `bg-gradient-to-b from-gray-50 to-white`, `shadow-md`), transforms (`transform translate-y-1/4 translate-x-1/4 lg:translate-x-1/2 -translate-y-3/4 ...`). All exist in v3.
Known v3 deltas to check in screenshots:
- `transform` is a no-op class in v3 (translate utilities apply transforms themselves) - fine.
- `shadow-md` second layer changed from `0 2px 4px -1px rgba(0,0,0,.06)` to `0 2px 4px -2px rgb(0 0 0 / .1)` - very subtle on the book covers. If it is visibly different, restore the v2 value via `theme.extend.boxShadow.md` in `tailwind.config.js`.
- Default `fontFamily.sans` stack differs slightly between 2.1 and 3.4. If text renders differently, copy the v2.1.2 `fontFamily.sans` (and `mono`) stack into `theme.extend.fontFamily` (take it from `node_modules/tailwindcss/stubs/defaultConfig.stub.js` in the Group A baseline checkout).
- `px4` in `index.html` is a typo (not a Tailwind class in v2 or v3). Leave it - fixing it would change the rendered layout and violate AC #4. Note it for Story 1.1/1.6.
- Do NOT edit `index.html`, `_includes/*` or `_layouts/*` in this story except if strictly needed for parity (none expected).

### Local dev loop (`npm run dev`)

BrowserSync is removed. Recommended replacement with zero extra deps:
`"dev": "npm run build && (bundle exec jekyll serve --skip-initial-build --watch --livereload --port 4000 & tailwindcss -i src/style.css -o _site/assets/css/style.css --watch)"`
plus `keep_files: [assets/css]` in `_config.yml` so Jekyll's regeneration does not delete the CSS. Tailwind `--watch` rescans `_site/**/*.html` when Jekyll rewrites it. If the `&` subshell is too fragile, adding `concurrently` (single devDep) is acceptable: `concurrently -k "bundle exec jekyll serve ..." "tailwindcss ... --watch"`. Document whichever you pick in README. Dev mode does not need `--minify`.
Alternative considered and rejected for this story: scanning source templates (`content: ["./*.html", "./_layouts/**/*.html", "./_includes/**/*.html", "./_books/**/*.md"]`) and emitting CSS into source `assets/css/` (already gitignored) before Jekyll. Cleaner dev loop, but it changes the documented `_site`-purge convention; leave for a later story if desired.

### Scope guards

- Do not touch analytics (Story 0.5), HTML validity/`no-js` (Story 1.1), SEO plugins (1.3/1.4), Dependabot config (0.3), or deploy-preview settings (0.4).
- Never hand-edit `_bmad/**` installer-managed files or `bmad-*` skills.
- Do not commit screenshots, `_site/`, `.jekyll-cache`, or `node_modules`.
- Pre-existing oddity, out of scope: Jekyll copies `AGENTS.md`, `CLAUDE.md`, `skills-lock.json` and `docs/` into `_site/` because they are not in `exclude`. Mention it in the PR as a follow-up; do not fix here unless trivial and you note it (adding them to `exclude` is safe and does not change the homepage).

### Previous story learnings (Story 0.2)

- Story 0.2 bumped transitive js-yaml 3.14.1 -> 3.15.2 in `package-lock.json` (via cosmiconfig <- postcss-load-config <- gulp-postcss). Removing gulp-postcss removes that path entirely; verify with `npm ls js-yaml` so Dependabot #116 stays closed.
- Story 0.2 warned about npm 6 downgrading lockfileVersion. Under Node 22 (npm 10) the regenerated lockfile will be v3 - that is expected and correct here.

### Testing standards

No test suite exists. Verification = clean `npm run build` with pinned runtimes, inspection of `_site/`, CSS diff vs baseline, before/after screenshots (desktop + mobile), `npm audit`, and the Netlify deploy preview when available. Use `mise exec` (or `mise install` in the worktree) to get pinned Node/Ruby - system Node is 26 and Ruby is 4.0, which must not be used for verification.

### Project Structure Notes

- Files changed: `.nvmrc`, `.ruby-version`, `Gemfile`, `Gemfile.lock`, `package.json`, `package-lock.json`, `tailwind.config.js`, `_config.yml`, `netlify.toml`, `README.md`, `AGENTS.md`.
- Files deleted: `gulpfile.babel.js`, `.babelrc`.
- Unchanged: `index.html`, `_layouts/default.html`, `_includes/header.html`, `_includes/footer.html`, `_books/*`, `img/*`, `src/style.css`.
- Output contract preserved: `_site/` publish dir and `_site/assets/css/style.css` path (referenced by `_includes/header.html`).

### References

- [Source: _bmad-output/planning-artifacts/epics.md - Epic 0, Story 0.1; NFR1; Stories 0.2, 0.3, 0.4 for boundaries]
- [Source: AGENTS.md - Running and verifying; Conventions; Known pitfalls]
- [Source: _bmad-output/implementation-artifacts/0-2-patch-js-yaml-dependabot-alert-116.md - js-yaml path, lockfile notes]
- [Source: gulpfile.babel.js, package.json, tailwind.config.js, netlify.toml, Gemfile.lock - current toolchain]
- [Tailwind CSS v3 upgrade guide](https://v3.tailwindcss.com/docs/upgrade-guide) and [v4 upgrade guide](https://tailwindcss.com/docs/upgrade-guide)
- [Netlify: manage build dependencies (NODE_VERSION, RUBY_VERSION, .nvmrc, .ruby-version)](https://docs.netlify.com/configure-builds/manage-dependencies/)
- [Jekyll 4.4 release notes](https://jekyllrb.com/news/)
- [Node.js release schedule](https://nodejs.org/en/about/previous-releases)
- Versions checked 2026-10-22: tailwindcss 3.4.19 (v4 is 4.3.3), jekyll 4.4.1, Node LTS lines 22 (maintenance) / 24 (active), Ruby 3.4.12.

## Dev Agent Record

### Agent Model Used

Claude Opus 5.5 (claude-opus-5-5) - all groups (bmad-swarm: story creator, Group A agent, Groups B-E agent, orchestrator for F and review fixes)

### Debug Log References

- Runtimes used for all verification: `mise exec node@22.23.3 ruby@3.4.11 -- ...` (mise has idiomatic version files enabled for ruby only, so Node is passed explicitly). System Node 26 / Ruby 4.0 not used.
- `tailwindcss --watch` exits when stdin closes (observed when run with stdin=/dev/null: jekyll was orphaned). Fixed by using `--watch=always` in the `dev` script.

### Completion Notes List

- **B (Ruby/Jekyll):** `.ruby-version` = `3.4.11` (newest 3.4 patch in `mise ls-remote ruby`; installed as a prebuilt mise binary). `Gemfile` = `source "https://rubygems.org"` + `gem "jekyll", "~> 4.4"`. Lockfile regenerated from scratch; Bundler 2.6.9 (ships with Ruby 3.4.11) auto-added ~20 platforms, trimmed with `bundle lock --remove-platform` to `arm64-darwin`, `ruby`, `x86_64-darwin`, `x86_64-linux`. `BUNDLED WITH 2.6.9`.
  - **Versions for Story 0.3:** jekyll **4.4.1**, rexml **3.4.4**, addressable **2.9.0** (also google-protobuf 4.36.2, sass-embedded 1.106.1 with x86_64-linux-gnu variants for Netlify).
  - `bundle exec jekyll build`: succeeds in ~0.06s, no errors and no deprecation warnings.
  - Note: every non-incremental Jekyll 4.4 build deletes the tracked-but-gitignored `.jekyll-metadata` (stale 2021 artifact). Untracked in this story with `git rm --cached .jekyll-metadata` (it was already in `.gitignore`).
- **C (Node/CSS):** `.nvmrc` = `22`; `package.json` rewritten (name `youmustreadthis`, private, engines `>=22 <23`, only devDependency `tailwindcss` `3.4.19` exact - confirmed latest 3.x via `npm view tailwindcss@3 version`). No postcss/autoprefixer/cssnano deps, no `postcss.config.js`. `build:production`/`build:dev` dropped. `gulpfile.babel.js` and `.babelrc` deleted (`git rm`). `tailwind.config.js` -> v3 `content: ["./_site/**/*.html"]`, `variants` dropped. `src/style.css` unchanged. `_config.yml`: removed `gulpfile.babel.js` exclude, added `keep_files: [assets/css]`. `package-lock.json` regenerated under Node 22.23.3 / npm 10 (lockfileVersion 3); `npm ci` succeeds.
  - `JEKYLL_ENV=production npm run build` from clean (`rm -rf _site .jekyll-cache`): OK. `_site/assets/css/style.css` 10155 bytes, single line (minified), contains `.text-indigo-600`, `.sm\:flex-row`, `.space-y-16`, `.bg-gradient-to-b`, `.xl\:inline`, `.md\:text-6xl`, plus `-webkit-text-size-adjust` / `-webkit-appearance` (autoprefixer active). `_site/index.html` contains gtag (production). Harmless "caniuse-lite is outdated" browserslist notice printed by the Tailwind CLI.
  - `dev` script: zero-dep variant chosen: `npm run build && (bundle exec jekyll serve --skip-initial-build --watch --livereload --port 4000 & tailwindcss -i src/style.css -o _site/assets/css/style.css --watch=always)`. Tested: `/` 200, `/assets/css/style.css` 200, livereload script injected, CSS survives Jekyll regeneration after touching `index.html` (keep_files works), SIGINT to the process group (= Ctrl-C) terminates npm, sh, jekyll and tailwind with nothing left on port 4000. No `concurrently` needed.
  - **C.8 partially met (left unchecked; AC #6 exception needs Derek's sign-off).** Initial state: `npm audit` = 7 vulnerabilities (2 moderate, 5 high), all inside tailwindcss@3.4.19's own dependency tree.** High: GHSA-vfj7-8cjw-p6xm (braces <=3.0.3, stack-exhaustion DoS on deeply nested brace patterns, published 2026-09-18, CVSS 7.5, **no patched braces release exists**) via chokidar 3.6.0 / micromatch 4.0.8 / fast-glob -> tailwindcss. Moderate: GHSA-rj75-hqrm-r3gf (postcss-selector-parser <7.1.6) via postcss-nested 6.2.0 -> tailwindcss. npm's only fix is `--force` to tailwindcss 4.3.3 (rejected by this story's design: breaks AC #4). Gulp/babel tree is gone (0 gulp/babel entries in lockfile). Needs a decision (see report). `npm ls js-yaml` -> `(empty)`: js-yaml is gone entirely, Story 0.2's fix is moot/intact.
- **C.8 follow-up (orchestrator):** added `"overrides": { "postcss-selector-parser": "^7.1.6" }` to `package.json` -> clears GHSA-rj75-hqrm-r3gf (moderate); `npm ls postcss-selector-parser` = 7.1.7 deduped; compiled CSS byte-identical before/after the override. This is outside Tailwind 3.4's declared `^6` range (v7's only breaking change is iteration-safe insertions); pitfall recorded in AGENTS.md. **Remaining: 5 "high" entries, all one advisory GHSA-vfj7-8cjw-p6xm (braces <= 3.0.3, no patched release).** Proposed documented exception: braces is reached only through Tailwind's build-time globbing of our own `content` pattern (`./_site/**/*.html`) and chokidar watch paths; no untrusted input reaches it and nothing ships to the browser. Exit paths: a patched braces release (then `npm update`), or a Tailwind 4 migration story. For comparison, master's Node 12 lockfile reported ~96 vulnerabilities.
- **D (Netlify):** `netlify.toml` gains `[build.environment]` `NODE_VERSION = "22"`, `RUBY_VERSION = "3.4.11"` (identical to `.ruby-version`); `[build]` unchanged. Netlify availability of Ruby 3.4.11 not verifiable locally - confirm in the deploy preview log (Story 0.4); fall back to an older 3.4 patch in both files if Netlify cannot install it.
- **E (Docs):** `README.md` rewritten from scratch (what it is, prerequisites via mise or nvm/rbenv, install, build, local dev, deployment, adding a book, project layout, MIT license). `AGENTS.md` updated inside the bmad:context block: Jekyll 4.4 + Tailwind 3.4 via npm scripts, new build/dev description, new pinned runtimes, removed the "Ignore README.md" bullet, purge note now refers to `content`. Note: that block is marked as managed by bmad-project-context; a future refresh should reproduce the same facts from the repo.
- **A (baseline):** A.2 method 1 failed: mise has no prebuilt Ruby 2.7.2 for x86_64 Linux and compiling it fails on Arch's GCC (`conflicting types for 'onig_jis_property'`). Method 2 used: in a detached worktree of `origin/master` (ccdeae8), HTML built with Ruby 3.4.6 after a throwaway `bundle update` (jekyll 4.4.1), CSS built with the original gulp `processStyles` task under Node 12.22.12 (Tailwind 2.1.2, `NODE_ENV=production`, purged and minified, 7,885 bytes). Screenshots: headless Chromium at 1280x6000 and 390x12000, trimmed to the content height.
- **F (integration):** F.1 clean `rm -rf _site .jekyll-cache node_modules` + `bundle install` + `npm ci` + `JEKYLL_ENV=production npm run build` under node 22.23.3 / ruby 3.4.11: exit 0. F.2 all 10 books and gtag present; CSS minified (10,155 bytes, one line), autoprefixed; 89/90 classes from `index.html` are present (missing one is the known `px4` typo). F.3 CSS diff vs baseline: size difference is Tailwind 3's CSS-variable preflight (`--tw-*`), no color/size changes. F.4 `magick compare -metric AE`: 14 px (1280) and 22 px (390) differ at exact match, **0 px at 2% fuzz**: sub-2% shade shifts in the book-cover `shadow-md` (v3 changed its second layer). Visually unchanged. F.5 audit as in C.8; `npm ls js-yaml` empty; old-toolchain grep clean. F.6 `npm run dev` smoke test passed (both 200s, CSS survives regeneration, process group cleans up, ports 4000/35729 freed).
- **Review fixes:** see "Senior Developer Review (AI)".
- Residual reference check (`grep -rni "node.*12|gulp|babel|browsersync"` excluding node_modules/_site/_bmad*/.agents/.claude/.git/package-lock): no matches.

### File List

- .nvmrc (modified)
- .ruby-version (modified)
- Gemfile (modified)
- Gemfile.lock (regenerated)
- package.json (rewritten)
- package-lock.json (regenerated, lockfileVersion 3)
- tailwind.config.js (modified)
- _config.yml (modified)
- netlify.toml (modified)
- README.md (rewritten)
- AGENTS.md (modified)
- gulpfile.babel.js (deleted)
- .babelrc (deleted)
- .jekyll-metadata (removed from git, file stays gitignored)
- _bmad-output/implementation-artifacts/0-1-modernize-node-and-build-toolchain.md (new story file)
- _bmad-output/implementation-artifacts/sprint-status.yaml (0-1 -> review)

### Change Log

- 2026-10-22: Story created; Groups A-F implemented (Node 22, Ruby 3.4.11, Jekyll 4.4.1, Tailwind 3.4.19 CLI via npm scripts; gulp/Babel/BrowserSync removed; README rewritten; AGENTS.md updated).
- 2026-10-22: Code review fixes applied (postcss-selector-parser override, mise instructions, `_config.yml` exclude/keep_files, README caveats, story bookkeeping). Status -> review pending Derek's approval of the AC #6 braces exception and a green Netlify deploy preview.

## Senior Developer Review (AI)

Adversarial review: 0 critical, 2 high, 5 medium, 4 low. Test runner: 5/6 checks pass; npm audit was conditional (the braces exception).

- [x] F1 (HIGH, AC #6) npm audit has 5 high entries -> override fixed the moderate advisory. braces GHSA-vfj7-8cjw-p6xm is recorded as a proposed exception (Completion Notes + PR body). **Derek must sign off.**
- [x] F2 (HIGH) story/sprint status out of sync -> Status `review` in both; A/F ticked with evidence; `.jekyll-metadata` note corrected; override documented.
- [x] F3 (MED) postcss-selector-parser v7 is outside Tailwind's range -> kept (CSS byte-identical), pitfall added to AGENTS.md.
- [x] F4 (MED) README mise instructions relied on a per-user mise setting -> explicit `mise install node@22 ruby@3.4.11` / `mise exec node@22 ruby@3.4.11 -- ...`.
- [x] F5 (MED) AGENTS.md mise example -> same fix. Note: the edits sit in the bmad:context block; re-run bmad-project-context after merge to refresh the "Verified" stamp.
- [x] F6 (MED) `dev` script has no supervision of the backgrounded process -> README now documents the port-busy failure mode. A supervised runner (`concurrently -k`) is a possible follow-up; Ctrl-C cleanup is verified.
- [x] F7 (MED) Netlify Ruby 3.4.11 availability is unverified -> a green deploy preview is a merge gate (stated in the PR); fallback is an older 3.4 patch in `.ruby-version` + `netlify.toml`.
- [x] F8 (LOW) File List gaps -> added `.jekyll-metadata` and `sprint-status.yaml`.
- [x] F9 (LOW) README overstated deploy previews -> softened to "should get ... (confirmed in Story 0.4)".
- [x] F10 (LOW) `keep_files` dropped Jekyll's defaults, and agent files were published -> `keep_files: [.git, .svn, assets/css]`; `AGENTS.md`, `CLAUDE.md`, `skills-lock.json`, `docs` added to `exclude` (the homepage and CSS are unchanged, verified byte-identical).
- [x] F11 (LOW) caniuse-lite outdated warning -> README notes it is harmless (data is bundled in the Tailwind CLI).
