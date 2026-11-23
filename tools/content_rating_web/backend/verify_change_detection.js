'use strict';

const fs = require('fs');
const path = require('path');
const {
  computeHashes,
} = require('./hash');

const CONTENT_JSON_PATH = path.resolve(__dirname, '..', '..', '..', 'assets', 'data', 'content_ideas.json');

// Load ideas
const raw = fs.readFileSync(CONTENT_JSON_PATH, 'utf8');
const data = JSON.parse(raw);
const ideas = data.ideas;

// Pick idea_1 for the controlled test
const testIdeaId = 'idea_1';
const testIdea = ideas.find(i => i.id === testIdeaId);

console.log(`Controlled change detection test using ${testIdeaId}: ${testIdea.title}`);

// Step 1: Compute original fingerprint
const originalFp = computeHashes(testIdea);
console.log(`\n1. Original fingerprint: ${originalFp.contentHash.slice(0, 16)}...`);

// Step 2: Simulate saving a rating with this fingerprint (CURRENT)
let savedContentHash = originalFp.contentHash;
let savedProductionHash = originalFp.productionHash;
let savedHashVersion = originalFp.hashVersion;

function checkFreshness(savedHash, savedProdHash, savedVer, currentFp) {
  if (!savedHash || !savedProdHash || !savedVer) return 'LEGACY';
  if (savedHash === currentFp.contentHash && savedProdHash === currentFp.productionHash && savedVer === currentFp.hashVersion) {
    return 'CURRENT';
  }
  return 'NEEDS_REEVALUATION';
}

let status = checkFreshness(savedContentHash, savedProductionHash, savedHashVersion, originalFp);
console.log(`2. Status with matching fingerprint: ${status}`);
if (status !== 'CURRENT') { console.error('FAIL: Expected CURRENT'); process.exit(1); }

// Step 3: Change one evaluation-relevant field (opening hook)
const modifiedIdea = JSON.parse(JSON.stringify(testIdea));
const originalOpening = modifiedIdea.opening;
modifiedIdea.opening = 'Modified hook for change detection test!';

const modifiedFp = computeHashes(modifiedIdea);
console.log(`\n3. Modified fingerprint: ${modifiedFp.contentHash.slice(0, 16)}...`);

status = checkFreshness(savedContentHash, savedProductionHash, savedHashVersion, modifiedFp);
console.log(`4. Status after hook change: ${status}`);
if (status !== 'NEEDS_REEVALUATION') { console.error('FAIL: Expected NEEDS_REEVALUATION'); process.exit(1); }

// Step 4: Restore original field
const restoredIdea = JSON.parse(JSON.stringify(testIdea));
const restoredFp = computeHashes(restoredIdea);

status = checkFreshness(savedContentHash, savedProductionHash, savedHashVersion, restoredFp);
console.log(`5. Status after restoring original: ${status}`);
if (status !== 'CURRENT') { console.error('FAIL: Expected CURRENT after restore'); process.exit(1); }

// Step 6: Verify the fingerprints match exactly
if (originalFp.contentHash !== restoredFp.contentHash) {
  console.error('FAIL: Original and restored fingerprints differ');
  process.exit(1);
}
if (originalFp.productionHash !== restoredFp.productionHash) {
  console.error('FAIL: Original and restored production hashes differ');
  process.exit(1);
}

console.log('\n6. Fingerprints match after restore: YES');
console.log('\n=== CHANGE DETECTION TEST PASSED ===');
console.log(`  CURRENT → NEEDS_REEVALUATION → CURRENT: All transitions correct`);
