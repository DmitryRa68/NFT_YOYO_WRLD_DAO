#!/usr/bin/env node
/*
 * generate_metadata.js
 *
 * This script composes 64×64 PNG layers into final character images and writes
 * corresponding JSON metadata. It picks a random file from each trait folder (shoes,
 * pants, shirt, hoodie, face, hair, yoyo) to construct a unique character. All
 * layers must be exactly 64×64 pixels with transparent backgrounds.
 *
 * Usage:
 *   npm install sharp
 *   node scripts/generate_metadata.js <count>
 *
 * Outputs `output/<id>.png` and `output/<id>.json` in the repository root.
 */
const fs = require('fs');
const path = require('path');
const sharp = require('sharp');

const layersDir = path.join(__dirname, '..', 'art');
const outputDir = path.join(__dirname, '..', 'output');

function getFiles(dir) {
  return fs
    .readdirSync(dir)
    .filter((f) => f.toLowerCase().endsWith('.png'));
}

const layers = {
  base: getFiles(path.join(layersDir, 'base')),
  shoes: getFiles(path.join(layersDir, 'shoes')),
  pants: getFiles(path.join(layersDir, 'pants')),
  shirt: getFiles(path.join(layersDir, 'shirt')),
  hoodie: getFiles(path.join(layersDir, 'hoodie')),
  face: getFiles(path.join(layersDir, 'face')),
  hair: getFiles(path.join(layersDir, 'hair')),
  yoyo: getFiles(path.join(layersDir, 'yoyo')),
};

function pickRandom(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

async function composeLayers(selected) {
  // start with base image as the background
  let composite = sharp(selected.base);
  const overlays = [];
  for (const key of ['shoes', 'pants', 'shirt', 'hoodie', 'face', 'hair', 'yoyo']) {
    if (selected[key]) {
      overlays.push({ input: selected[key], top: 0, left: 0 });
    }
  }
  return composite.composite(overlays).png();
}

function ensureDir(dir) {
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
}

async function generateOne(id) {
  const choice = {};
  for (const key of Object.keys(layers)) {
    const files = layers[key];
    if (files.length === 0) {
      throw new Error(`No files found in art/${key}`);
    }
    choice[key] = path.join(layersDir, key, pickRandom(files));
  }
  // compose image
  const image = await composeLayers(choice);
  ensureDir(outputDir);
  const imageName = `${id}.png`;
  await image.toFile(path.join(outputDir, imageName));

  // build metadata
  const metadata = {
    name: `YOYO #${id}`,
    description: 'Generated YOYO DAO NFT (64x64 pixel art).',
    image: `REPLACE_ME_WITH_IPFS_CID/${imageName}`,
    attributes: [
      { trait_type: 'Shoes', value: path.basename(choice.shoes, '.png') },
      { trait_type: 'Pants', value: path.basename(choice.pants, '.png') },
      { trait_type: 'Shirt', value: path.basename(choice.shirt, '.png') },
      { trait_type: 'Hoodie', value: path.basename(choice.hoodie, '.png') },
      { trait_type: 'Face', value: path.basename(choice.face, '.png') },
      { trait_type: 'Hair', value: path.basename(choice.hair, '.png') },
      { trait_type: 'YoYo', value: path.basename(choice.yoyo, '.png') },
    ],
  };
  fs.writeFileSync(path.join(outputDir, `${id}.json`), JSON.stringify(metadata, null, 2));
}

async function main() {
  const count = parseInt(process.argv[2], 10) || 1;
  for (let i = 1; i <= count; i++) {
    await generateOne(i);
  }
}

main().catch((err) => {
  console.error(err);
});
