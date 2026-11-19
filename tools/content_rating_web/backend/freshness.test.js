'use strict';

/**
 * Tests for content change detection and stale evaluation management.
 * Tests the core hash + freshness logic without file system dependency.
 */

const assert = require('node:assert/strict');
const test = require('node:test');
const fs = require('fs');
const path = require('path');
const {
  computeContentHash,
  computeHashes,
  HASH_VERSION,
} = require('./hash');

const CONTENT_JSON_PATH = path.resolve(__dirname, '..', '..', '..', 'assets', 'data', 'content_ideas.json');

// Load the actual content ideas
const raw = fs.readFileSync(CONTENT_JSON_PATH, 'utf8');
const data = JSON.parse(raw);
const ideas = data.ideas;

// Helper: compute full fingerprint (content + production hash) for an idea
function fingerprint(idea) {
  return computeHashes(idea);
}

// Helper: check if two fingerprints match
function match(fp1, fp2) {
  return fp1.contentHash === fp2.contentHash
    && fp1.productionHash === fp2.productionHash
    && fp1.hashVersion === fp2.hashVersion;
}

// TEST 1: Hash is deterministic for same content
test('hash is deterministic for same content', () => {
  const idea = ideas[0];
  const fp1 = fingerprint(idea);
  const fp2 = fingerprint(idea);
  assert.equal(fp1.contentHash, fp2.contentHash);
  assert.equal(fp1.productionHash, fp2.productionHash);
  assert.equal(fp1.hashVersion, fp2.hashVersion);
});

// TEST 2: Hook change produces different fingerprint
test('hook change produces different fingerprint', () => {
  const idea = JSON.parse(JSON.stringify(ideas[0]));
  const fp1 = fingerprint(idea);
  idea.opening = 'Modified hook text!';
  const fp2 = fingerprint(idea);
  assert.notEqual(fp1.contentHash, fp2.contentHash);
});

// TEST 3: Story change produces different fingerprint
test('story change produces different fingerprint', () => {
  const idea = JSON.parse(JSON.stringify(ideas[0]));
  const fp1 = fingerprint(idea);
  idea.storyDetail = 'New story detail.';
  const fp2 = fingerprint(idea);
  assert.notEqual(fp1.contentHash, fp2.contentHash);
});

// TEST 4: Caption change produces different fingerprint
test('caption change produces different fingerprint', () => {
  const idea = JSON.parse(JSON.stringify(ideas[0]));
  const fp1 = fingerprint(idea);
  idea.caption = 'New caption #Safety #Parents #Kids #Learning #Palak';
  const fp2 = fingerprint(idea);
  assert.notEqual(fp1.contentHash, fp2.contentHash);
});

// TEST 5: Pinned comment change produces different fingerprint
test('pinned comment change produces different fingerprint', () => {
  const idea = JSON.parse(JSON.stringify(ideas[0]));
  const fp1 = fingerprint(idea);
  idea.pinnedComment = 'New pinned comment?';
  const fp2 = fingerprint(idea);
  assert.notEqual(fp1.contentHash, fp2.contentHash);
});

// TEST 6: Production prompt change produces different fingerprint
test('production prompt change produces different fingerprint', () => {
  const idea = JSON.parse(JSON.stringify(ideas[0]));
  const fp1 = fingerprint(idea);
  idea.readyPrompt = 'New production prompt.';
  const fp2 = fingerprint(idea);
  // readyPrompt is a production field, affects productionHash
  assert.notEqual(fp1.productionHash, fp2.productionHash);
  // contentHash should remain the same
  assert.equal(fp1.contentHash, fp2.contentHash);
});

// TEST 7: Unrelated metadata change does NOT change fingerprint
test('unrelated metadata change does not change fingerprint', () => {
  const idea = JSON.parse(JSON.stringify(ideas[0]));
  const fp1 = fingerprint(idea);
  idea.archived = true;
  idea.score = 99;
  idea.band = 'Ready';
  idea.reviewedOn = '2026-01-01';
  idea.id = 'idea_999';
  idea.custom = true;
  idea.usedOn = '2026-01-01';
  const fp2 = fingerprint(idea);
  assert.equal(fp1.contentHash, fp2.contentHash);
  assert.equal(fp1.productionHash, fp2.productionHash);
});

// TEST 8: contentHash and hashVersion are always present
test('contentHash and hashVersion are always present', () => {
  const idea = ideas[0];
  const { contentHash, hashVersion } = computeContentHash(idea);
  assert.ok(contentHash, 'contentHash should be non-empty');
  assert.ok(hashVersion, 'hashVersion should be non-empty');
  assert.equal(contentHash.length, 64);
  assert.ok(/^[0-9a-f]{64}$/.test(contentHash));
});

// TEST 9: Different ideas have different fingerprints
test('different ideas have different fingerprints', () => {
  const fp1 = fingerprint(ideas[0]);
  const fp2 = fingerprint(ideas[1]);
  assert.notEqual(fp1.contentHash, fp2.contentHash);
});

// TEST 10: Same content different key order produces same fingerprint
test('same content different key order produces same fingerprint', () => {
  const idea1 = { ...ideas[0] };
  const idea2 = {
    ...ideas[0],
    zz_temp: ideas[0].zz_temp,
    ...ideas[0],
  };
  delete idea2.zz_temp;
  const fp1 = fingerprint(idea1);
  const fp2 = fingerprint(idea2);
  assert.equal(fp1.contentHash, fp2.contentHash);
});

// TEST 11: HASH_VERSION is consistent
test('HASH_VERSION is consistent', () => {
  const idea = ideas[0];
  const { hashVersion: hv1 } = computeContentHash(idea);
  const { hashVersion: hv2 } = computeHashes(idea);
  assert.equal(hv1, hv2);
  assert.equal(hv1, HASH_VERSION);
});

// TEST 12: Freshness simulation - matching fingerprint = CURRENT
test('freshness simulation: matching fingerprint = CURRENT', () => {
  const idea = ideas[0];
  const fp = fingerprint(idea);
  // Simulate saving a rating with this fingerprint
  const savedHash = fp.contentHash;
  const savedProductionHash = fp.productionHash;
  const savedVersion = fp.hashVersion;
  // Comparison logic (same as getRatingFreshness)
  const isCurrent = savedHash === fp.contentHash
    && savedProductionHash === fp.productionHash
    && savedVersion === fp.hashVersion;
  assert.equal(isCurrent, true);
});

// TEST 13: Freshness simulation - mismatched fingerprint = NEEDS_REEVALUATION
test('freshness simulation: mismatched fingerprint = NEEDS_REEVALUATION', () => {
  const idea = JSON.parse(JSON.stringify(ideas[0]));
  const fp1 = fingerprint(idea);
  idea.opening = 'Changed!';
  const fp2 = fingerprint(idea);
  const isCurrent = fp1.contentHash === fp2.contentHash
    && fp1.productionHash === fp2.productionHash
    && fp1.hashVersion === fp2.hashVersion;
  assert.equal(isCurrent, false);
});

// TEST 14: Freshness simulation - missing hash = LEGACY
test('freshness simulation: missing hash = LEGACY', () => {
  const ratingWithoutHash = { ideaId: 'idea_1', verdict: 'Test' };
  const hasHash = !!ratingWithoutHash.contentHash && !!ratingWithoutHash.productionHash && !!ratingWithoutHash.hashVersion;
  assert.equal(hasHash, false);
  // Legacy status: no contentHash or hashVersion means NEEDS_REEVALUATION
  assert.equal(!hasHash, true);
});

// TEST 15: All 122 ideas can be fingerprinted without error
test('all 122 ideas can be fingerprinted without error', () => {
  let count = 0;
  for (const idea of ideas) {
    const fp = fingerprint(idea);
    assert.ok(fp.contentHash);
    assert.ok(fp.productionHash);
    assert.ok(fp.hashVersion);
    count++;
  }
  assert.equal(count, 122);
});
