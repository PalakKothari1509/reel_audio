'use strict';

/**
 * Tests for the canonical hashing module (backend/hash.js).
 *
 * Covers:
 * - All 22 creative hash fields
 * - All 24 production hash fields (22 + readyPrompt + forApp)
 * - Excluded fields (archived, id, custom, usedOn, score, band, reviewedOn)
 * - Canonicalization: key ordering, nested objects, arrays, NFC, null/empty
 * - Hash stability under reordering
 * - Content-only vs production-only changes
 */

const assert = require('node:assert/strict');
const test = require('node:test');
const {
  computeHashes,
  computeContentHash,
  computeProductionHash,
  getCreativeHashFields,
  getProductionHashFields,
  getExcludedFields,
  canonicalize,
  buildCanonicalObject,
  hashCanonicalObject,
  HASH_VERSION,
} = require('./hash');

const BASE_IDEA = {
  id: 'idea_1',
  category: 'Safety',
  title: 'Garden Safety',
  cover: 'Stay Safe in Garden',
  opening: 'Did you know?',
  problem: 'Children run near tools.',
  lesson: 'Always supervise kids.',
  postFormat: 'Reel',
  strategy: 'Educational',
  caption: 'Garden safety tips!',
  pinnedComment: 'Any questions?',
  storyDetail: 'Story about garden safety.',
  setting: 'Garden',
  sceneDetail: 'Rake on grass.',
  dialogue: 'Be careful!',
  mess: 'Tools left out.',
  innerThought: 'I should clean up.',
  endingBeat: 'All tools away.',
  defaultCast: ['Ria', 'Mumma'],
  keepMoralOffScreen: false,
  quote: 'Watch out!',
  detail: 'Red rake.',
  punchline: 'Safe and sound.',
  readyPrompt: 'Prompt text.',
  forApp: true,
  archived: false,
  custom: false,
  usedOn: '',
  score: 0,
  band: '',
  reviewedOn: '',
};

test('computeHashes returns correct structure', () => {
  const result = computeHashes(BASE_IDEA);
  assert.ok(result.contentHash);
  assert.ok(result.productionHash);
  assert.equal(result.hashVersion, HASH_VERSION);
  assert.equal(result.contentHash.length, 64);
  assert.equal(result.productionHash.length, 64);
  assert.ok(/^[0-9a-f]{64}$/.test(result.contentHash));
  assert.ok(/^[0-9a-f]{64}$/.test(result.productionHash));
});

test('getCreativeHashFields returns 22 fields', () => {
  const fields = getCreativeHashFields();
  assert.equal(fields.length, 22);
  assert.ok(fields.includes('caption'));
  assert.ok(fields.includes('category'));
  assert.ok(fields.includes('cover'));
  assert.ok(fields.includes('defaultCast'));
  assert.ok(fields.includes('dialogue'));
  assert.ok(fields.includes('endingBeat'));
  assert.ok(fields.includes('keepMoralOffScreen'));
  assert.ok(fields.includes('lesson'));
  assert.ok(fields.includes('mess'));
  assert.ok(fields.includes('opening'));
  assert.ok(fields.includes('pinnedComment'));
  assert.ok(fields.includes('postFormat'));
  assert.ok(fields.includes('problem'));
  assert.ok(fields.includes('punchline'));
  assert.ok(fields.includes('quote'));
  assert.ok(fields.includes('sceneDetail'));
  assert.ok(fields.includes('setting'));
  assert.ok(fields.includes('strategy'));
  assert.ok(fields.includes('storyDetail'));
  assert.ok(fields.includes('title'));
  assert.ok(fields.includes('innerThought'));
  assert.ok(fields.includes('detail'));
});

test('getProductionHashFields returns 24 fields', () => {
  const fields = getProductionHashFields();
  assert.equal(fields.length, 24);
  assert.ok(fields.includes('forApp'));
  assert.ok(fields.includes('readyPrompt'));
  // All creative fields should be in production
  for (const f of getCreativeHashFields()) {
    assert.ok(fields.includes(f), `${f} should be in production fields`);
  }
});

test('getExcludedFields returns correct groups', () => {
  const excluded = getExcludedFields();
  assert.deepEqual(excluded.availability, ['archived']);
  assert.deepEqual(excluded.identity, ['id', 'custom', 'usedOn']);
  assert.deepEqual(excluded.derived, ['score', 'band', 'reviewedOn']);
});

test('contentHash changes when creative field changes', () => {
  const base = computeContentHash(BASE_IDEA);
  const modified = { ...BASE_IDEA, caption: 'New caption!' };
  const changed = computeContentHash(modified);
  assert.notEqual(base.contentHash, changed.contentHash);
});

test('productionHash changes when readyPrompt changes', () => {
  const base = computeHashes(BASE_IDEA);
  const modified = { ...BASE_IDEA, readyPrompt: 'New prompt!' };
  const changed = computeHashes(modified);
  assert.equal(base.contentHash, changed.contentHash); // creative unchanged
  assert.notEqual(base.productionHash, changed.productionHash); // production changed
});

test('productionHash changes when forApp changes', () => {
  const base = computeHashes(BASE_IDEA);
  const modified = { ...BASE_IDEA, forApp: false };
  const changed = computeHashes(modified);
  assert.equal(base.contentHash, changed.contentHash);
  assert.notEqual(base.productionHash, changed.productionHash);
});

test('contentHash does NOT change when archived changes', () => {
  const base = computeHashes(BASE_IDEA);
  const modified = { ...BASE_IDEA, archived: true };
  const changed = computeHashes(modified);
  assert.equal(base.contentHash, changed.contentHash);
  assert.equal(base.productionHash, changed.productionHash);
});

test('contentHash does NOT change when metadata changes', () => {
  const base = computeHashes(BASE_IDEA);
  const modified = {
    ...BASE_IDEA,
    id: 'idea_999',
    custom: true,
    usedOn: '2026-01-01',
    score: 99,
    band: 'Ready',
    reviewedOn: '2026-11-04',
  };
  const changed = computeHashes(modified);
  assert.equal(base.contentHash, changed.contentHash);
  assert.equal(base.productionHash, changed.productionHash);
});

test('canonicalize sorts object keys recursively', () => {
  const obj = { z: 1, a: { y: 2, b: 3 }, m: [5, 1] };
  const result = canonicalize(obj);
  assert.deepEqual(Object.keys(result), ['a', 'm', 'z']);
  assert.deepEqual(Object.keys(result.a), ['b', 'y']);
});

test('canonicalize preserves array order', () => {
  const obj = { items: ['b', 'a', 'c'] };
  const result = canonicalize(obj);
  assert.deepEqual(result.items, ['b', 'a', 'c']);
});

test('canonicalize normalizes Unicode NFC', () => {
  const decomposed = 'e\u0301'; // e + combining acute
  const composed = 'é'; // precomposed é
  assert.notEqual(decomposed, composed);
  assert.equal(canonicalize(decomposed), canonicalize(composed));
});

test('canonicalize omits null values', () => {
  const obj = { a: 1, b: null, c: undefined, d: 2 };
  const result = canonicalize(obj);
  assert.deepEqual(Object.keys(result), ['a', 'd']);
});

test('canonicalize preserves empty strings', () => {
  const obj = { a: '', b: 'text' };
  const result = canonicalize(obj);
  assert.deepEqual(result, { a: '', b: 'text' });
});

test('canonicalize recursively processes nested objects', () => {
  const obj = { outer: { inner: { z: 1, a: 2 } } };
  const result = canonicalize(obj);
  assert.deepEqual(Object.keys(result.outer.inner), ['a', 'z']);
});

test('canonicalize recursively processes array elements', () => {
  const obj = { items: [{ z: 1, a: 2 }, { b: 3, c: 4 }] };
  const result = canonicalize(obj);
  assert.deepEqual(Object.keys(result.items[0]), ['a', 'z']);
  assert.deepEqual(Object.keys(result.items[1]), ['b', 'c']);
});

test('hashCanonicalObject produces deterministic output for canonically-equivalent objects', () => {
  const obj1 = { b: 2, a: 1 };
  const obj2 = { a: 1, b: 2 };
  const h1 = hashCanonicalObject(canonicalize(obj1));
  const h2 = hashCanonicalObject(canonicalize(obj2));
  assert.equal(h1, h2);
});

test('buildCanonicalObject only includes allowlisted fields', () => {
  const source = { a: 1, b: 2, c: 3, d: 4 };
  const result = buildCanonicalObject(source, ['a', 'c']);
  assert.deepEqual(Object.keys(result).sort(), ['a', 'c']);
});

test('buildCanonicalObject omits missing fields', () => {
  const source = { a: 1 };
  const result = buildCanonicalObject(source, ['a', 'b']);
  assert.deepEqual(Object.keys(result), ['a']);
});

test('computeContentHash and computeProductionHash are consistent', () => {
  const content = computeContentHash(BASE_IDEA);
  const production = computeProductionHash(BASE_IDEA);
  const both = computeHashes(BASE_IDEA);
  assert.equal(content.contentHash, both.contentHash);
  assert.equal(production.productionHash, both.productionHash);
  assert.equal(content.hashVersion, both.hashVersion);
});

test('different content with same fields produces different hashes', () => {
  const idea1 = { ...BASE_IDEA, title: 'Safety First' };
  const idea2 = { ...BASE_IDEA, title: 'Safety Second' };
  const h1 = computeContentHash(idea1);
  const h2 = computeContentHash(idea2);
  assert.notEqual(h1.contentHash, h2.contentHash);
});

test('same content different key order produces same hash', () => {
  const idea1 = { ...BASE_IDEA };
  const idea2 = {
    detail: BASE_IDEA.detail,
    title: BASE_IDEA.title,
    cover: BASE_IDEA.cover,
    // ... all other fields in different order
    ...BASE_IDEA,
  };
  const h1 = computeHashes(idea1);
  const h2 = computeHashes(idea2);
  assert.equal(h1.contentHash, h2.contentHash);
});

test('HASH_VERSION is a non-empty string', () => {
  assert.ok(HASH_VERSION);
  assert.equal(typeof HASH_VERSION, 'string');
});
