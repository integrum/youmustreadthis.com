# Visual baseline (Story 0.7)

Captured with Playwright full-page screenshots while serving `_site` via a static server.

| Directory | Contents |
|-----------|----------|
| `tw3/` | Tailwind **3.4.19** baseline (before upgrade) |
| `tw4/` | Tailwind **4.3.3** after upgrade |
| `diff-iter1/` | Pixelmatch diff images + `summary.json` |

Viewport widths: **1440px** (desktop), **390px** (mobile). Page IDs match `scripts/visual-regression/pages.json`.

Regenerate:

```bash
npm run build
npx serve -l 4173 _site   # separate terminal
npm run visual:capture -- docs/visual-baseline/tw4
npm run visual:compare -- docs/visual-baseline/tw3 docs/visual-baseline/tw4 docs/visual-baseline/diff-iter1
```
