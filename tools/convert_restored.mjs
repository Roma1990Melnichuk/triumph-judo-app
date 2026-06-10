import sharp from 'sharp';
import { unlinkSync } from 'fs';

const files = ['trophy', 'medal', 'training', 'motivation'];
for (const name of files) {
  await sharp(`assets/icons/ti_${name}.png`).webp({ lossless: true }).toFile(`assets/icons/ti_${name}.webp`);
  unlinkSync(`assets/icons/ti_${name}.png`);
  console.log(`OK  ti_${name}.webp restored`);
}
