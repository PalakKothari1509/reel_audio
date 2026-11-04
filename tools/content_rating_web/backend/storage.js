const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const DATA_DIR = path.join(ROOT, 'data');
const RATINGS_DIR = path.join(DATA_DIR, 'ratings');

function ensureDirs() {
  if (!fs.existsSync(DATA_DIR)) fs.mkdirSync(DATA_DIR, { recursive: true });
  if (!fs.existsSync(RATINGS_DIR)) fs.mkdirSync(RATINGS_DIR, { recursive: true });
}

function ratingPath(ideaId) {
  return path.join(RATINGS_DIR, `${ideaId}.json`);
}

function listRatings() {
  ensureDirs();
  const files = fs.readdirSync(RATINGS_DIR).filter(f => f.endsWith('.json'));
  return files.map(f => {
    try {
      return JSON.parse(fs.readFileSync(path.join(RATINGS_DIR, f), 'utf8'));
    } catch (e) {
      return null;
    }
  }).filter(Boolean);
}

function getRating(ideaId) {
  ensureDirs();
  const p = ratingPath(ideaId);
  if (!fs.existsSync(p)) return null;
  try {
    return JSON.parse(fs.readFileSync(p, 'utf8'));
  } catch (e) {
    return null;
  }
}

function saveRating(record) {
  ensureDirs();
  const p = ratingPath(record.ideaId);
  fs.writeFileSync(p, JSON.stringify(record, null, 2), 'utf8');
  return record;
}

function deleteRating(ideaId) {
  ensureDirs();
  const p = ratingPath(ideaId);
  if (fs.existsSync(p)) {
    fs.unlinkSync(p);
    return true;
  }
  return false;
}

function clearRatings() {
  ensureDirs();
  const files = fs.readdirSync(RATINGS_DIR).filter(f => f.endsWith('.json'));
  files.forEach(f => fs.unlinkSync(path.join(RATINGS_DIR, f)));
  return files.length;
}

module.exports = { ensureDirs, listRatings, getRating, saveRating, deleteRating, clearRatings, RATINGS_DIR };
