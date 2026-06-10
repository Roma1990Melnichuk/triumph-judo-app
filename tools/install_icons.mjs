import sharp from 'sharp';
import { copyFileSync, existsSync } from 'fs';
import { join } from 'path';

const SRC = 'c:/Users/flamehost/Downloads/New folder';
const DEST = './assets/icons';

const MAP = [
  { src: '1.png',     dest: 'ti_home.webp' },
  { src: '2 (2).png', dest: 'ti_coach.webp' },
  { src: '3.png',     dest: 'ti_sparring.webp' },
  { src: '4.png',     dest: 'ti_training.webp' },
  { src: '5.png',     dest: 'ti_goals.webp' },
  { src: '6.png',     dest: 'ti_experience.webp' },
  { src: '7.png',     dest: 'ti_motivation.webp' },
  { src: '8.png',     dest: 'ti_calendar.webp' },
  { src: '9.png',     dest: 'ti_trophy.webp' },
  { src: '10.png',    dest: 'ti_medal.webp' },
];

for (const { src, dest } of MAP) {
  const srcPath = join(SRC, src);
  const destPath = join(DEST, dest);
  await sharp(srcPath).resize(512, 512, { fit: 'inside' }).webp({ quality: 92 }).toFile(destPath);
  const { size } = (await import('fs')).statSync(destPath);
  console.log(`OK  ${src.padEnd(12)} → ${dest}  (${(size / 1024).toFixed(0)} KB)`);
}
console.log('\nDone.');
