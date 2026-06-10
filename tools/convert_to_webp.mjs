import sharp from 'sharp';
import { readdirSync, statSync, unlinkSync } from 'fs';
import { join, basename, extname } from 'path';

// These files are used by flutter_launcher_icons / flutter_native_splash at build time
// and MUST remain as PNG.
const SKIP_FILES = new Set([
  'triumph_logo.png',
  'triumph_icon_generated.png',
  'triumph_icon_fg.png',
]);

let converted = 0;
let skipped = 0;
let savedBytes = 0;

async function processDir(dir) {
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const full = join(dir, entry.name);
    if (entry.isDirectory()) {
      await processDir(full);
    } else if (entry.isFile() && extname(entry.name).toLowerCase() === '.png') {
      if (SKIP_FILES.has(entry.name)) {
        console.log(`  SKIP  ${full}  (launcher/splash — must stay PNG)`);
        skipped++;
        continue;
      }
      const webpPath = full.replace(/\.png$/i, '.webp');
      await sharp(full).webp({ lossless: true }).toFile(webpPath);

      const pngSize = statSync(full).size;
      const webpSize = statSync(webpPath).size;
      const diff = pngSize - webpSize;
      const pct = ((diff / pngSize) * 100).toFixed(1);
      console.log(`  OK    ${basename(full)} → .webp  (${pct > 0 ? '-' : '+'}${Math.abs(pct)}%)`);

      // Delete original PNG only after successful conversion
      unlinkSync(full);
      savedBytes += diff;
      converted++;
    }
  }
}

console.log('Converting assets/  PNG → WebP (lossless)...\n');
await processDir('./assets');
console.log(`\nDone: ${converted} converted, ${skipped} skipped.`);
console.log(`Net size change: ${savedBytes >= 0 ? '-' : '+'}${Math.abs((savedBytes / 1024)).toFixed(1)} KB`);
