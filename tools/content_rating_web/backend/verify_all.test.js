'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');
const fs = require('fs');
const path = require('path');
const {
  computeHashes,
} = require('./hash');

const CONTENT_JSON_PATH = path.resolve(__dirname, '..', '..', '..', 'assets', 'data', 'content_ideas.json');
const RATINGS_DIR = path.resolve(__dirname, '..', 'data', 'ratings');

// Load all ideas
const raw = fs.readFileSync(CONTENT_JSON_PATH, 'utf8');
const data = JSON.parse(raw);
const ideas = data.ideas;

// Load all ratings
const ratingFiles = fs.readdirSync(RATINGS_DIR).filter(f => f.endsWith('.json'));
const ratings = ratingFiles.map(f => {
  try {
    return JSON.parse(fs.readFileSync(path.join(RATINGS_DIR, f), 'utf8'));
  } catch (e) {
    return null;
  }
}).filter(Boolean);
const ratingsById = new Map(ratings.map(r => [r.ideaId, r]));

console.log(`Source ideas: ${ideas.length}`);
console.log(`Rating files: ${ratings.length}`);

// TEST: All 122 ideas loaded
test('all 122 ideas loaded', () => {
  assert.equal(ideas.length, 122);
});

// TEST: All 122 ratings exist
test('all 122 rating files exist', () => {
  assert.equal(ratings.length, 122);
});

// TEST: Every idea has a matching rating
test('every idea has a matching rating', () => {
  for (const idea of ideas) {
    assert.ok(ratingsById.has(idea.id), `Missing rating for ${idea.id}`);
  }
});

// TEST: Every rating corresponds to a valid idea
test('every rating corresponds to valid idea', () => {
  const ideaIds = new Set(ideas.map(i => i.id));
  for (const rating of ratings) {
    assert.ok(ideaIds.has(rating.ideaId), `Rating for unknown idea: ${rating.ideaId}`);
  }
});

// TEST: All ratings have fingerprints
test('all ratings have contentHash, productionHash, hashVersion', () => {
  for (const rating of ratings) {
    assert.ok(rating.contentHash, `${rating.ideaId}: missing contentHash`);
    assert.ok(rating.productionHash, `${rating.ideaId}: missing productionHash`);
    assert.ok(rating.hashVersion, `${rating.ideaId}: missing hashVersion`);
    assert.equal(rating.hashVersion, '1.0.0', `${rating.ideaId}: wrong hashVersion`);
  }
});

// TEST: All fingerprints match source (CURRENT status)
let currentCount = 0;
let mismatchCount = 0;
const mismatchIds = [];

for (const idea of ideas) {
  const rating = ratingsById.get(idea.id);
  const fp = computeHashes(idea);
  const matches = rating.contentHash === fp.contentHash
    && rating.productionHash === fp.productionHash
    && rating.hashVersion === fp.hashVersion;
  if (matches) {
    currentCount++;
  } else {
    mismatchCount++;
    mismatchIds.push(idea.id);
  }
}

test('all fingerprints match source (122 CURRENT)', () => {
  assert.equal(currentCount, 122, `Expected 122 CURRENT, got ${currentCount}`);
  assert.equal(mismatchCount, 0, `Expected 0 mismatches, got ${mismatchCount}: ${mismatchIds.join(', ')}`);
});

// TEST: All ratings have valid verdicts
const validVerdicts = ['Ready to Post', 'Needs Minor Fixes', 'Needs Major Rewrite', 'Reject'];
test('all ratings have valid verdicts', () => {
  for (const rating of ratings) {
    assert.ok(validVerdicts.includes(rating.verdict), `${rating.ideaId}: invalid verdict '${rating.verdict}'`);
  }
});

// TEST: All ratings have confidence=low
test('all ratings have confidence=low', () => {
  for (const rating of ratings) {
    assert.equal(rating.confidence, 'low', `${rating.ideaId}: confidence is ${rating.confidence}`);
  }
});

// TEST: All ratings have evaluationMode=offline
test('all ratings have evaluationMode=offline', () => {
  for (const rating of ratings) {
    assert.equal(rating.evaluationMode, 'offline', `${rating.ideaId}: mode is ${rating.evaluationMode}`);
  }
});

// TEST: All ratings have evaluationVersion=2.0.0
test('all ratings have evaluationVersion=2.0.0', () => {
  for (const rating of ratings) {
    assert.equal(rating.evaluationVersion, '2.0.0', `${rating.ideaId}: version is ${rating.evaluationVersion}`);
  }
});

// Verdict distribution
const verdictCounts = {};
for (const rating of ratings) {
  const v = rating.verdict || 'unknown';
  verdictCounts[v] = (verdictCounts[v] || 0) + 1;
}

console.log('\n=== VERDICT DISTRIBUTION ===');
for (const [v, c] of Object.entries(verdictCounts)) {
  console.log(`  ${v}: ${c}`);
}

console.log('\n=== FRESHNESS STATUS ===');
console.log(`  CURRENT: ${currentCount}`);
console.log(`  NEEDS_REEVALUATION: ${mismatchCount}`);
console.log(`  LEGACY: 0`);
console.log(`  NOT_EVALUATED: 0`);
console.log(`  Total: ${currentCount + mismatchCount}`);

console.log('\n=== INDEPENDENT VERIFICATION COMPLETE ===');
