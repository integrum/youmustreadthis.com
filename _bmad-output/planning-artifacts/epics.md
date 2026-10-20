---
status: approved
stepsCompleted: []
inputDocuments:
  - GM baseline review 10-18-2026 (repo, Benji list, live-site SEO check)
benjiList: "You Must Read This"
benjiListId: 1451c017-e249-464d-902a-fe2450508acc
repo: integrum/youmustreadthis.com
---

# youmustreadthis.com - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for youmustreadthis.com (Derek Neighbors' curated book list; Jekyll + Tailwind on Netlify). No PRD exists; requirements come from the 10-18-2026 GM baseline review. Every epic mirrors a Benji project and every story mirrors a Benji todo on the **You Must Read This** list (`1451c017-e249-464d-902a-fe2450508acc`). Keys match `_bmad-output/implementation-artifacts/sprint-status.yaml`. Implement only via `bmad-swarm` (`.agents/skills/bmad-swarm`), passing the story's BenjiID.

## Requirements Inventory

### Functional Requirements

- FR1: Each book has its own indexable page at `/books/<slug>/`.
- FR2: Every page has a descriptive title, meta description, canonical URL and social card.
- FR3: The site publishes `sitemap.xml` and `robots.txt`.
- FR4: Pages emit Book, ItemList, Person and WebSite structured data.
- FR5: Amazon links carry the Associates tag from one config value, with disclosure.
- FR6: Each book page explains why to read it, in the curator's voice.
- FR7: An about page establishes who curates the list.
- FR8: Curators can add new books via a documented front matter pattern.

### NonFunctional Requirements

- NFR1: Builds on a supported Node LTS / Ruby / Jekyll toolchain on Netlify.
- NFR2: No open high/critical Dependabot alerts.
- NFR3: Analytics records production traffic (UA is sunset).
- NFR4: Valid HTML; Lighthouse accessibility ≥ 95; all images have alt text.

### Additional Requirements

- Non-code dependencies tracked as plain Benji todos on the same list (no project): Amazon Associates tag (`0d10131c-ce83-4dda-883e-34baa2f529d4`), GA4 property (`96a8aa60-8195-448c-affd-2322e2b43ea0`), Search Console verification (`9b384013-7339-4730-bf1f-3c8b5bb3f4b8`), GoDaddy → Cloudflare transfer (`5d9f4f24-b708-462d-831c-fdbabd1a1c5a`), domain renewal decision (`f94dd2fc-1d1a-4ac8-b117-743204c3dfa8`).

### UX Design Requirements

- Keep the existing Tailwind look; book pages reuse the homepage card styling.

### FR Coverage Map

- FR1: Story 1.2
- FR2: Story 1.3
- FR3: Story 1.4
- FR4: Story 1.5
- FR5: Story 2.1
- FR6: Story 2.2
- FR7: Story 2.4
- FR8: Story 2.3
- NFR1: Stories 0.1, 0.4
- NFR2: Stories 0.2, 0.3
- NFR3: Story 0.5
- NFR4: Stories 1.1, 1.6

## Epic List

- Epic 0: Ops Hygiene & Infra (BenjiProjectID: `86f49183-aae5-45f7-9a71-05dc6ff462c3`)
- Epic 1: Technical SEO (BenjiProjectID: `3237eea1-d269-4757-8c6d-b42e1c7a5478`)
- Epic 2: Content & Monetization (BenjiProjectID: `7bb7c96f-1451-4d8b-8e40-adcb9153dd04`)

## Epic 0: Ops Hygiene & Infra

Get the 2021-era build back to a supported, secure, observable baseline so every later epic ships on a toolchain that builds on Netlify today. Also the standing Bugs & Chores container for one-off code chores.

- BenjiProjectID: `86f49183-aae5-45f7-9a71-05dc6ff462c3`
- Benji project: Epic 0: Ops Hygiene & Infra (youmustreadthis.com)
- Benji list: You Must Read This (`1451c017-e249-464d-902a-fe2450508acc`)

### Story 0.1: Modernize Node and build toolchain

- Story key: `0-1-modernize-node-and-build-toolchain`
- BenjiID: `b485e1f8-3fc8-42b0-acc9-3b7a2730e361`
- BenjiProjectID: `86f49183-aae5-45f7-9a71-05dc6ff462c3`

As a maintainer of youmustreadthis.com,
I want the site to build on a supported Node LTS, Ruby, Jekyll and Tailwind toolchain,
So that Netlify builds succeed and dependency upgrades are no longer blocked.

**Acceptance Criteria:**

- `.nvmrc`, `package.json` `engines` and Netlify build env pin a current Node LTS (20 or 22); Node 12 is gone
- `.ruby-version` / `Gemfile` / `Gemfile.lock` move to a supported Ruby and Jekyll 4.x; `bundle exec jekyll build` succeeds
- Tailwind, PostCSS, autoprefixer, cssnano, gulp and Babel deps are upgraded (or gulp is replaced by a simpler npm-script/Tailwind CLI pipeline) and `npm run build` produces `_site/` with the compiled CSS
- Rendered homepage is visually unchanged (before/after screenshot in the PR)
- README replaces the upstream starter-kit boilerplate with real local dev/build instructions

### Story 0.2: Patch js-yaml Dependabot alert #116

- Story key: `0-2-patch-js-yaml-dependabot-alert-116`
- BenjiID: `bd8c50cf-a34e-47c8-936c-5295f1bc41f6`
- BenjiProjectID: `86f49183-aae5-45f7-9a71-05dc6ff462c3`

As a maintainer,
I want the high-severity js-yaml advisory (GHSA-2883-xcg3-v3hh) resolved in package-lock.json,
So that the repo has no open high-severity Dependabot alerts.

**Acceptance Criteria:**

- `npm ls js-yaml` shows only patched versions
- Dependabot alert https://github.com/integrum/youmustreadthis.com/security/dependabot/116 closes as fixed
- `npm audit --omit=dev` and `npm audit` report no high/critical issues (or remaining ones are documented in the PR)
- Build still passes (coordinate with Story 0.1 if the toolchain bump already fixes it)

### Story 0.3: Resolve stale Dependabot PRs #2 and #4

- Story key: `0-3-resolve-stale-dependabot-prs-2-and-4`
- BenjiID: `a655dc61-068e-4e14-81a9-8c30c0d8cf92`
- BenjiProjectID: `86f49183-aae5-45f7-9a71-05dc6ff462c3`

As a maintainer,
I want the rexml (#2) and addressable (#4) Dependabot PRs merged or closed as superseded,
So that the PR queue reflects real work only.

**Acceptance Criteria:**

- PR #2 (rexml 3.2.4→3.2.5) and PR #4 (addressable 2.7.0→2.8.1) are merged or closed with a comment pointing at the Story 0.1 Gemfile.lock refresh
- `Gemfile.lock` contains rexml ≥ 3.2.5 and addressable ≥ 2.8.1
- Dependabot config (`.github/dependabot.yml`) exists for npm and bundler with a sane schedule

### Story 0.4: Confirm Netlify production build and deploy previews

- Story key: `0-4-confirm-netlify-production-build-and-deploy-previews`
- BenjiID: `0fa36d42-f938-4600-b71c-db83f2c37faf`
- BenjiProjectID: `86f49183-aae5-45f7-9a71-05dc6ff462c3`

As a maintainer,
I want proof that Netlify builds master and deploy previews from the current repo,
So that we know the live site is not a stale 2021 artifact and PRs can be reviewed on previews.

**Acceptance Criteria:**

- Latest Netlify production deploy log for master is green on the Story 0.1 toolchain
- `netlify.toml` declares build command, publish dir and pinned Node/Ruby versions
- Deploy previews are enabled for PRs and the preview URL is posted on the PR
- Any build failure found is fixed or captured as a new Story 0.N

### Story 0.5: Replace dead Universal Analytics tag

- Story key: `0-5-replace-dead-universal-analytics-tag`
- BenjiID: `da68deac-2508-4c0e-b43e-4df3ea020d93`
- BenjiProjectID: `86f49183-aae5-45f7-9a71-05dc6ff462c3`

As a site owner,
I want working analytics in place of the sunset UA-185254703-5 tag,
So that traffic and outbound Amazon clicks are measurable.

**Acceptance Criteria:**

- `UA-185254703-5` gtag snippet is removed from `_includes/header.html`
- GA4 measurement ID (or the chosen privacy-friendly alternative) is read from `_config.yml`, rendered only when `jekyll.environment == "production"`
- Outbound Amazon link clicks fire an event
- Realtime view shows a hit from the production site after deploy
- Blocked by the non-code todo 'Set up GA4 property for youmustreadthis.com' for the measurement ID

### Story 0.6: Pull add-shared-skill and mirror .claude/skills

- Story key: `0-6-pull-add-shared-skill-and-mirror-claude-skills`
- BenjiID: `abec7881-bad3-4008-bb43-e29bd3899fc6`
- BenjiProjectID: `86f49183-aae5-45f7-9a71-05dc6ff462c3`

As an agent operator,
I want the latest add-shared-skill from dneighbors/chiron-agent-skills and a complete .claude/skills mirror of .agents/skills,
So that Cursor and Claude Code agents see the same skills.

**Acceptance Criteria:**

- `npx skills add dneighbors/chiron-agent-skills --skill add-shared-skill --agent cursor,claude-code --copy -y` run; `skills-lock.json` updated
- Every `.agents/skills/*` skill has a matching `.claude/skills/*` entry (copy or symlink, consistent with the BMAD installer output)
- Committed on a branch with a PR; no unrelated skill churn

## Epic 1: Technical SEO

Turn a single unindexable homepage into a crawlable site: one indexable page per book, correct metadata, sitemap, robots.txt, structured data and valid accessible HTML.

- BenjiProjectID: `3237eea1-d269-4757-8c6d-b42e1c7a5478`
- Benji project: Epic 1: Technical SEO (youmustreadthis.com)
- Benji list: You Must Read This (`1451c017-e249-464d-902a-fe2450508acc`)

### Story 1.1: Fix base HTML shell

- Story key: `1-1-fix-base-html-shell`
- BenjiID: `448aba51-efd1-4f29-b111-ff8b19c75817`
- BenjiProjectID: `3237eea1-d269-4757-8c6d-b42e1c7a5478`

As a visitor and crawler,
I want valid HTML on every page,
So that browsers, crawlers and assistive tech parse the page correctly.

**Acceptance Criteria:**

- `_includes/header.html` / `_layouts/default.html` emit a proper `<body>` open tag; header/footer includes balance their tags
- Remove the stray `no-js` class or add the script that uses it
- Favicon / apple-touch-icon referenced
- W3C validator shows no structural errors on the homepage

### Story 1.2: Book pages via collection output and book layout

- Story key: `1-2-book-pages-via-collection-output-and-book-layout`
- BenjiID: `365f19d8-bf3d-460d-a729-08e6ae2c97b9`
- BenjiProjectID: `3237eea1-d269-4757-8c6d-b42e1c7a5478`

As a reader arriving from search,
I want a dedicated page for each book at /books/<slug>/,
So that each book can rank and be shared on its own.

**Acceptance Criteria:**

- `_config.yml` sets `collections.books.output: true` with `permalink: /books/:name/`
- New `_layouts/book.html` renders title, author, cover, Derek's blurb and the Amazon CTA
- Homepage cards link to the book page (Amazon link stays as secondary CTA)
- All 10 existing books render at `/books/<slug>/` with 200 status; no 404s from homepage links

### Story 1.3: Titles, meta descriptions and social cards via jekyll-seo-tag

- Story key: `1-3-titles-meta-descriptions-and-social-cards-via-jekyll-seo-tag`
- BenjiID: `fd76e618-c61f-4d0e-b373-da8b5d4ddbdc`
- BenjiProjectID: `3237eea1-d269-4757-8c6d-b42e1c7a5478`

As a searcher,
I want descriptive titles, meta descriptions, canonical URLs and Open Graph/Twitter cards,
So that results and shares are compelling and duplicate-safe.

**Acceptance Criteria:**

- `jekyll-seo-tag` added to Gemfile and `_config.yml` plugins; `{% seo %}` replaces hand-written title/description
- `_config.yml` sets `url: https://youmustreadthis.com`, `author`, `social`, default image
- Homepage title is keyword-bearing (e.g. 'Books Every Leader and Developer Must Read | You Must Read This'), not just the site name
- Book pages: `<Book Title> by <Author> — Why You Must Read It | You Must Read This`; description from front matter `description` or excerpt
- Canonical, og:title/description/image and twitter:card present on every page

### Story 1.4: sitemap.xml via jekyll-sitemap and robots.txt

- Story key: `1-4-sitemap-xml-via-jekyll-sitemap-and-robots-txt`
- BenjiID: `a68cf36b-6647-4360-866b-4fd7b5a404f4`
- BenjiProjectID: `3237eea1-d269-4757-8c6d-b42e1c7a5478`

As a crawler,
I want a sitemap and robots.txt,
So that every page is discovered and crawl rules are explicit.

**Acceptance Criteria:**

- `jekyll-sitemap` plugin added; `/sitemap.xml` lists homepage, every book page and the about page
- `/robots.txt` allows all and points at `https://youmustreadthis.com/sitemap.xml`
- Both return 200 on the Netlify deploy preview

### Story 1.5: Structured data for Book, ItemList and Person

- Story key: `1-5-structured-data-for-book-itemlist-and-person`
- BenjiID: `dfb86c72-6a8e-4654-b423-cf9b7d6e0d15`
- BenjiProjectID: `3237eea1-d269-4757-8c6d-b42e1c7a5478`

As a search engine,
I want JSON-LD describing the list, each book and the curator,
So that rich results and entity understanding are possible.

**Acceptance Criteria:**

- Homepage emits `ItemList` of the books (position, url, name)
- Each book page emits `Book` (name, author, isbn when known, image, url) and a `Review`/recommendation by the curator where appropriate
- Site-wide `Person` (Derek Neighbors, sameAs links) and `WebSite` JSON-LD
- Google Rich Results Test passes with no errors on homepage and one book page

### Story 1.6: Cover image alt text and image optimization

- Story key: `1-6-cover-image-alt-text-and-image-optimization`
- BenjiID: `dda62b84-2380-493e-a920-61b1f91fbafa`
- BenjiProjectID: `3237eea1-d269-4757-8c6d-b42e1c7a5478`

As a screen-reader user and image searcher,
I want meaningful alt text and right-sized cover images,
So that the site is accessible and images can rank.

**Acceptance Criteria:**

- Every cover `<img>` has `alt="<Title> by <Author> book cover"` driven from front matter
- `width`/`height` (or aspect-ratio) set to avoid layout shift; `loading="lazy"` below the fold
- Image paths are absolute (`/img/...`) so they work on book pages
- Lighthouse accessibility ≥ 95 on homepage

### Story 1.7: Footer refresh with current year and curator byline

- Story key: `1-7-footer-refresh-with-current-year-and-curator-byline`
- BenjiID: `8334c891-59c8-41b1-ba35-668c093bc4c8`
- BenjiProjectID: `3237eea1-d269-4757-8c6d-b42e1c7a5478`

As a visitor,
I want a footer that shows who curates the list and that the site is alive,
So that trust signals and internal links improve.

**Acceptance Criteria:**

- Copyright uses `{{ site.time | date: '%Y' }}` instead of hard-coded 2013
- Curated-by Derek Neighbors byline linking to the about page (Story 2.4) and derekneighbors.com
- Footer nav: Home, Books, About; affiliate disclosure link once Story 2.1 lands

## Epic 2: Content & Monetization

Give the site an author voice and real depth per book, grow the list, and earn from the traffic through properly disclosed Amazon affiliate links.

- BenjiProjectID: `7bb7c96f-1451-4d8b-8e40-adcb9153dd04`
- Benji project: Epic 2: Content & Monetization (youmustreadthis.com)
- Benji list: You Must Read This (`1451c017-e249-464d-902a-fe2450508acc`)

### Story 2.1: Amazon Associates tag wiring and disclosure

- Story key: `2-1-amazon-associates-tag-wiring-and-disclosure`
- BenjiID: `c343bf98-17bd-4730-9e47-09f909bc52ad`
- BenjiProjectID: `7bb7c96f-1451-4d8b-8e40-adcb9153dd04`

As a site owner,
I want every Amazon link to carry Derek's Associates tag from one config value,
So that book clicks earn commission without hand-editing each link.

**Acceptance Criteria:**

- `_config.yml` holds `amazon_associates_tag`; links are built from front matter ASIN/ISBN (`asin:`) plus the tag, not hard-coded URLs
- All 10 books migrated; The Phoenix Project points at the same edition type as the others (print vs Kindle decided and consistent)
- Links use `rel="sponsored noopener"` and open as before
- FTC/Amazon disclosure line on homepage, book pages and footer
- Blocked by the non-code todo 'Provide Amazon Associates tag for youmustreadthis.com'

### Story 2.2: Per-book Why read this long-form content

- Story key: `2-2-per-book-why-read-this-long-form-content`
- BenjiID: `ea6f170f-6ae6-4b58-bb2f-8c0e6a9acc1b`
- BenjiProjectID: `7bb7c96f-1451-4d8b-8e40-adcb9153dd04`

As a reader deciding what to read next,
I want each book page to explain why it matters, who it is for and the key ideas, in Derek's voice,
So that pages are worth ranking and convert to reads.

**Acceptance Criteria:**

- Front matter schema extended: `description`, `who_for`, `key_ideas` (list), `pairs_with` (related books)
- Each of the 10 books has 300+ words of original 'Why you must read this' copy drafted for Derek's review (humanizer / copywriting skills), no AI boilerplate
- Book layout renders the new sections and related-book links
- Derek approves copy before merge

### Story 2.3: Add new books pipeline and first batch

- Story key: `2-3-add-new-books-pipeline-and-first-batch`
- BenjiID: `1b24763d-4d50-4518-a7e6-a481e8a9f933`
- BenjiProjectID: `7bb7c96f-1451-4d8b-8e40-adcb9153dd04`

As a curator,
I want a documented way to add a book and a first batch of new recommendations,
So that the list grows beyond the 2015 set.

**Acceptance Criteria:**

- `docs/` or README section documents how to add a book (front matter fields, cover image size, ASIN)
- Book template/archetype file exists
- First batch of new books (titles chosen by Derek) added with covers, blurbs and pages
- Homepage ordering/grouping still works with 15+ books (consider categories)

### Story 2.4: About page and curator voice

- Story key: `2-4-about-page-and-curator-voice`
- BenjiID: `33d840cd-4999-4cda-9d97-2904730b4a22`
- BenjiProjectID: `7bb7c96f-1451-4d8b-8e40-adcb9153dd04`

As a visitor,
I want to know who curates this list and why to trust it,
So that the recommendations carry authority (E-E-A-T).

**Acceptance Criteria:**

- `/about/` page with Derek's bio, why the list exists and how books are chosen; Person schema links here
- Homepage hero copy refreshed in Derek's voice
- Linked from header/footer; included in sitemap
- Derek approves copy before merge
