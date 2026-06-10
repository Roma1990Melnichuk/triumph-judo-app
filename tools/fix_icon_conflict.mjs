// For 5 icons used with ColorFiltered across the app:
//   trophy, medal, calendar, training, motivation
// We must keep the originals (simple monochrome, transparent bg) for ColorFiltered to work.
// The new 3D versions go to *3d.webp names.
//
// The other 5 (home, coach, sparring, goals, experience) are NOT used with ColorFiltered,
// so they can safely stay at their current names.

import sharp from 'sharp';
import { renameSync, existsSync, writeFileSync } from 'fs';
import { execSync } from 'child_process';

const CONFLICT = ['trophy', 'medal', 'calendar', 'training', 'motivation'];

for (const name of CONFLICT) {
  const current3d = `assets/icons/ti_${name}.webp`;   // currently holds the 3D image
  const new3d     = `assets/icons/ti_${name}3d.webp`; // where 3D image should live
  const restored  = `assets/icons/ti_${name}.webp`;   // where original must be restored

  // 1. Move 3D version out of the way
  if (existsSync(current3d)) {
    renameSync(current3d, new3d);
    console.log(`Moved  ti_${name}.webp → ti_${name}3d.webp`);
  }

  // 2. Extract original PNG from git history (initial commit)
  try {
    const pngBuf = execSync(`git show HEAD:assets/icons/ti_${name}.png`);
    const tmpPng = `assets/icons/_tmp_${name}.png`;
    writeFileSync(tmpPng, pngBuf);
    await sharp(tmpPng).webp({ lossless: true }).toFile(restored);
    const { unlinkSync } = await import('fs');
    unlinkSync(tmpPng);
    console.log(`Restored ti_${name}.webp from git (original simple icon)`);
  } catch (e) {
    console.error(`ERROR restoring ti_${name}: ${e.message}`);
  }
}

console.log('\nDone.');
