#!/usr/bin/env node
/**
 * Pixel-diff baseline vs candidate screenshots (PNG).
 * Usage: node scripts/visual-regression/compare.mjs <baselineDir> <candidateDir> <reportDir>
 */
import { readFile, writeFile, mkdir } from 'node:fs/promises';
import path from 'node:path';
import { PNG } from 'pngjs';
import pixelmatch from 'pixelmatch';

const [baselineDir, candidateDir, reportDir] = process.argv.slice(2);
if (!baselineDir || !candidateDir || !reportDir) {
  console.error('Usage: node compare.mjs <baselineDir> <candidateDir> <reportDir>');
  process.exit(1);
}

const { readdir } = await import('node:fs/promises');
const files = (await readdir(baselineDir)).filter((f) => f.endsWith('.png')).sort();

await mkdir(reportDir, { recursive: true });

const results = [];

for (const file of files) {
  const basePath = path.join(baselineDir, file);
  const candPath = path.join(candidateDir, file);
  let baseImg;
  let candImg;
  try {
    baseImg = PNG.sync.read(await readFile(basePath));
    candImg = PNG.sync.read(await readFile(candPath));
  } catch (e) {
    results.push({ file, error: String(e) });
    continue;
  }

  const { width, height } = baseImg;
  if (candImg.width !== width || candImg.height !== height) {
    results.push({
      file,
      error: `size mismatch baseline ${width}x${height} vs candidate ${candImg.width}x${candImg.height}`,
    });
    continue;
  }

  const diff = new PNG({ width, height });
  const mismatched = pixelmatch(baseImg.data, candImg.data, diff.data, width, height, {
    threshold: 0.1,
    includeAA: false,
  });
  const total = width * height;
  const diffPct = (mismatched / total) * 100;
  const diffPath = path.join(reportDir, file.replace('.png', '-diff.png'));
  await writeFile(diffPath, PNG.sync.write(diff));
  results.push({
    file,
    width,
    height,
    mismatchedPixels: mismatched,
    totalPixels: total,
    diffPercent: Number(diffPct.toFixed(4)),
    diffImage: path.basename(diffPath),
  });
}

const summaryPath = path.join(reportDir, 'summary.json');
await writeFile(summaryPath, JSON.stringify({ generatedAt: new Date().toISOString(), results }, null, 2));
console.log(JSON.stringify({ summaryPath, results }, null, 2));

const failed = results.filter((r) => r.error || (r.diffPercent ?? 0) > 0.01);
process.exitCode = failed.length ? 1 : 0;
