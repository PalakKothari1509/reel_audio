const fs = require('fs');
const path = require('path');

const {
  computeHashes,
  computeContentHash,
  computeProductionHash,
  HASH_VERSION,
} = require('./hash');

const ROOT = path.resolve(__dirname, '..');
const DATA_DIR = path.join(ROOT, 'data');
const RATINGS_DIR = path.join(DATA_DIR, 'ratings');
const SOURCE_JSON_PATH = path.resolve(ROOT, '..', '..', 'assets', 'data', 'content_ideas.json');

let cachedSourceIds = null;
let contentIdeasCache = null;
let contentIdeasCacheMtime = null;

function loadSourceIds() {
  if (cachedSourceIds !== null) return cachedSourceIds;
  const raw = fs.readFileSync(SOURCE_JSON_PATH, 'utf8');
  const data = JSON.parse(raw);
  cachedSourceIds = new Set((data.ideas || []).map(i => i.id));
  return cachedSourceIds;
}

function validateIdeaId(ideaId) {
  const sourceIds = loadSourceIds();
  if (!sourceIds.has(ideaId)) {
    throw new Error(`Unknown ideaId "${ideaId}": not found in content_ideas.json`);
  }
}

function ensureDirs() {
  if (!fs.existsSync(DATA_DIR)) fs.mkdirSync(DATA_DIR, { recursive: true });
  if (!fs.existsSync(RATINGS_DIR)) fs.mkdirSync(RATINGS_DIR, { recursive: true });
}

function ratingPath(ideaId) {
  return path.join(RATINGS_DIR, `${ideaId}.json`);
}

function loadContentIdeas() {
  const stat = fs.statSync(SOURCE_JSON_PATH);
  const mtime = stat.mtimeMs;
  if (contentIdeasCache && contentIdeasCacheMtime === mtime) {
    return contentIdeasCache;
  }
  const raw = fs.readFileSync(SOURCE_JSON_PATH, 'utf8');
  const data = JSON.parse(raw);
  contentIdeasCache = data.ideas || [];
  contentIdeasCacheMtime = mtime;
  return contentIdeasCache;
}

function invalidateContentCache() {
  contentIdeasCache = null;
  contentIdeasCacheMtime = null;
}

function getSourceFingerprint(ideaId) {
  const ideas = loadContentIdeas();
  const idea = ideas.find(i => i.id === ideaId);
  if (!idea) return null;
  const { contentHash, productionHash, hashVersion } = computeHashes(idea);
  return { contentHash, productionHash, hashVersion };
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

function saveRating(record, sourceIdea = null) {
  ensureDirs();
  validateIdeaId(record.ideaId);
  const hashSource = sourceIdea || record;
  const { contentHash, productionHash, hashVersion } = computeHashes(hashSource);
  const enriched = {
    ...record,
    contentHash,
    productionHash,
    hashVersion,
  };
  const p = ratingPath(record.ideaId);
  fs.writeFileSync(p, JSON.stringify(enriched, null, 2), 'utf8');
  return enriched;
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

function getRatingFreshness(ideaId) {
  const rating = getRating(ideaId);
  if (!rating) {
    return { status: 'NOT_EVALUATED', rating: null };
  }

  const fingerprint = getSourceFingerprint(ideaId);
  if (!fingerprint) {
    return { status: 'NOT_EVALUATED', rating };
  }

  const savedHash = rating.contentHash;
  const savedProductionHash = rating.productionHash;
  const savedVersion = rating.hashVersion;

  if (!savedHash || !savedProductionHash || !savedVersion) {
    return { status: 'LEGACY', rating };
  }

  if (savedHash === fingerprint.contentHash
      && savedProductionHash === fingerprint.productionHash
      && savedVersion === fingerprint.hashVersion) {
    return { status: 'CURRENT', rating };
  }

  return { status: 'NEEDS_REEVALUATION', rating };
}

function getAllFreshness() {
  const ideas = loadContentIdeas();
  const ratings = listRatings();
  const ratingsById = new Map(ratings.map(r => [r.ideaId, r]));

  const results = [];
  for (const idea of ideas) {
    const rating = ratingsById.get(idea.id) || null;
    const fingerprint = getSourceFingerprint(idea.id);

    if (!rating) {
      results.push({ ideaId: idea.id, status: 'NOT_EVALUATED', rating: null });
    } else if (!fingerprint) {
      results.push({ ideaId: idea.id, status: 'NOT_EVALUATED', rating });
    } else if (!rating.contentHash || !rating.productionHash || !rating.hashVersion) {
      results.push({ ideaId: idea.id, status: 'LEGACY', rating });
    } else if (rating.contentHash === fingerprint.contentHash
      && rating.productionHash === fingerprint.productionHash
      && rating.hashVersion === fingerprint.hashVersion) {
      results.push({ ideaId: idea.id, status: 'CURRENT', rating });
    } else {
      results.push({ ideaId: idea.id, status: 'NEEDS_REEVALUATION', rating });
    }
  }

  return results;
}

module.exports = {
  ensureDirs,
  listRatings,
  getRating,
  saveRating,
  deleteRating,
  clearRatings,
  RATINGS_DIR,
  getSourceFingerprint,
  getRatingFreshness,
  getAllFreshness,
  invalidateContentCache,
};
