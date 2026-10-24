#!/usr/bin/env node
/**
 * Capture full-page screenshots for visual regression (Tailwind upgrade).
 * Usage: node scripts/visual-regression/capture.mjs <outputDir> [baseUrl]
 */
import { chromium } from 'playwright';
import { mkdir } from 'node:fs/promises';
import path from 'node:path';

const outputDir = process.argv[2];
const baseUrl = process.argv[3] ?? 'http://127.0.0.1:4173';

if (!outputDir) {
  console.error('Usage: node capture.mjs <outputDir> [baseUrl]');
  process.exit(1);
}

/** Page types in this Jekyll site (Story 0.7 inventory). */
const PAGES = [
  { id: 'homepage', path: '/' },
  { id: '404', path: '/this-page-does-not-exist-yet/' },
];

const VIEWPORTS = [
  { id: 'desktop', width: 1440, height: 900 },
  { id: 'mobile', width: 390, height: 844 },
];

await mkdir(outputDir, { recursive: true });

const browser = await chromium.launch();
for (const page of PAGES) {
  for (const vp of VIEWPORTS) {
    const context = await browser.newContext({
      viewport: { width: vp.width, height: vp.height },
      deviceScaleFactor: 1,
    });
    const tab = await context.newPage();
    const url = `${baseUrl.replace(/\/$/, '')}${page.path}`;
    const response = await tab.goto(url, { waitUntil: 'networkidle', timeout: 60_000 });
    await tab.waitForTimeout(300);
    const filename = `${page.id}-${vp.id}.png`;
    await tab.screenshot({
      path: path.join(outputDir, filename),
      fullPage: true,
    });
    console.log(
      JSON.stringify({
        page: page.id,
        viewport: vp.id,
        url,
        status: response?.status(),
        file: filename,
      })
    );
    await context.close();
  }
}
await browser.close();
