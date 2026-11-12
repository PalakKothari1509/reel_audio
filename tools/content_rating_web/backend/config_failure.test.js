const assert = require('node:assert/strict');
const test = require('node:test');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { loadSpec } = require('./schemas');

function writeTempSpec(content) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'eval-spec-test-'));
  const file = path.join(dir, 'evaluation_rules.json');
  fs.writeFileSync(file, content, 'utf8');
  return file;
}

function validSpec() {
  return JSON.stringify({
    dimensions: [
      { id: 'hookStrength', name: 'Hook Strength', weight: 15, minScore: 0, maxScore: 10, anchors: { '10': 'a', '6': 'b', '2': 'c' } },
      { id: 'relatabilityAudienceFit', name: 'Relatability', weight: 15, minScore: 0, maxScore: 10, anchors: { '10': 'a', '6': 'b', '2': 'c' } },
      { id: 'payoffRetention', name: 'Story Structure', weight: 14, minScore: 0, maxScore: 10, anchors: { '10': 'a', '6': 'b', '2': 'c' } },
      { id: 'hinglishNaturalness', name: 'Hinglish Naturalness', weight: 10, minScore: 0, maxScore: 10, anchors: { '10': 'a', '6': 'b', '2': 'c' } },
      { id: 'visualFeasibility', name: 'Visual Feasibility', weight: 10, minScore: 0, maxScore: 10, anchors: { '10': 'a', '6': 'b', '2': 'c' } },
      { id: 'soundOffReadability', name: 'Sound-Off Readability', weight: 8, minScore: 0, maxScore: 10, anchors: { '10': 'a', '6': 'b', '2': 'c' } },
      { id: 'shareSaveTrigger', name: 'Engagement Potential', weight: 8, minScore: 0, maxScore: 10, anchors: { '10': 'a', '6': 'b', '2': 'c' } },
      { id: 'captionCommentPackage', name: 'Caption Package', weight: 8, minScore: 0, maxScore: 10, anchors: { '10': 'a', '6': 'b', '2': 'c' } },
      { id: 'originality', name: 'Originality', weight: 7, minScore: 0, maxScore: 10, anchors: { '10': 'a', '6': 'b', '2': 'c' } },
      { id: 'audioHook', name: 'Audio Hook', weight: 5, minScore: 0, maxScore: 10, anchors: { '10': 'a', '6': 'b', '2': 'c' } },
    ],
    gates: [
      { id: 'ageAppropriateness', name: 'Age Appropriateness', description: 'Age check', severityOnFail: 'critical' },
      { id: 'characterConsistency', name: 'Character Consistency', description: 'Character check', severityOnFail: 'major' },
      { id: 'brandAndSafety', name: 'Brand & Safety', description: 'Brand check', severityOnFail: 'critical' },
      { id: 'formatFit', name: 'Format Fit', description: 'Format check', severityOnFail: 'major' },
    ],
    verdicts: [
      { id: 'ready_to_post', label: 'Ready to Post', minScore: 80, maxScore: 100 },
      { id: 'needs_minor_fixes', label: 'Needs Minor Fixes', minScore: 65, maxScore: 79 },
      { id: 'needs_major_rewrite', label: 'Needs Major Rewrite', minScore: 45, maxScore: 64 },
      { id: 'reject', label: 'Reject', minScore: 0, maxScore: 44 },
    ],
    criticalCap: {
      enabled: true,
      capThreshold: 59,
      cappedScore: 59,
      cappedVerdict: 'Needs Major Rewrite',
    },
    additionalCaps: [],
    deterministicChecks: { checks: [] },
    severities: [
      { id: 'critical', label: 'Critical', blocksPublishing: true },
      { id: 'major', label: 'Major', blocksPublishing: false },
      { id: 'minor', label: 'Minor', blocksPublishing: false },
      { id: 'suggestion', label: 'Suggestion', blocksPublishing: false },
    ],
  });
}

// ── Configuration failure tests ──────────────────────────────────────────

test('loadSpec throws explicit error when shared JSON file is missing', () => {
  const missingPath = path.join(os.tmpdir(), 'nonexistent-spec-12345.json');
  assert.throws(() => loadSpec(missingPath), /Failed to load shared evaluation spec/);
});

test('loadSpec throws explicit error on invalid JSON syntax', () => {
  const file = writeTempSpec('{ not valid json }');
  assert.throws(() => loadSpec(file), /Invalid JSON in shared evaluation spec/);
  fs.rmSync(path.dirname(file), { recursive: true, force: true });
});

test('loadSpec throws explicit error when dimensions is missing', () => {
  const file = writeTempSpec(JSON.stringify({ version: '1.0.0' }));
  assert.throws(() => loadSpec(file), /missing spec\.dimensions/);
  fs.rmSync(path.dirname(file), { recursive: true, force: true });
});

test('loadSpec throws explicit error when dimension weights do not total 100', () => {
  const spec = JSON.parse(validSpec());
  spec.dimensions[0].weight = 99; // break the total
  const file = writeTempSpec(JSON.stringify(spec));
  assert.throws(() => loadSpec(file), /dimension weights must total 100/);
  fs.rmSync(path.dirname(file), { recursive: true, force: true });
});

test('loadSpec throws explicit error when dimension missing anchors', () => {
  const spec = JSON.parse(validSpec());
  delete spec.dimensions[0].anchors;
  const file = writeTempSpec(JSON.stringify(spec));
  assert.throws(() => loadSpec(file), /missing anchors/);
  fs.rmSync(path.dirname(file), { recursive: true, force: true });
});

test('loadSpec throws explicit error when verdicts is missing', () => {
  const spec = JSON.parse(validSpec());
  delete spec.verdicts;
  const file = writeTempSpec(JSON.stringify(spec));
  assert.throws(() => loadSpec(file), /missing spec\.verdicts/);
  fs.rmSync(path.dirname(file), { recursive: true, force: true });
});

test('loadSpec throws explicit error when gates is missing', () => {
  const spec = JSON.parse(validSpec());
  delete spec.gates;
  const file = writeTempSpec(JSON.stringify(spec));
  assert.throws(() => loadSpec(file), /missing spec\.gates/);
  fs.rmSync(path.dirname(file), { recursive: true, force: true });
});

test('loadSpec throws explicit error when criticalCap.enabled is true but capThreshold is missing', () => {
  const spec = JSON.parse(validSpec());
  spec.criticalCap = { enabled: true, cappedScore: 59, cappedVerdict: 'Needs Major Rewrite' };
  delete spec.criticalCap.capThreshold;
  const file = writeTempSpec(JSON.stringify(spec));
  assert.throws(() => loadSpec(file), /criticalCap\.capThreshold must be a number/);
  fs.rmSync(path.dirname(file), { recursive: true, force: true });
});

test('loadSpec throws explicit error when criticalCap.enabled is true but cappedScore is missing', () => {
  const spec = JSON.parse(validSpec());
  spec.criticalCap = { enabled: true, capThreshold: 59, cappedVerdict: 'Needs Major Rewrite' };
  delete spec.criticalCap.cappedScore;
  const file = writeTempSpec(JSON.stringify(spec));
  assert.throws(() => loadSpec(file), /criticalCap\.cappedScore must be a number/);
  fs.rmSync(path.dirname(file), { recursive: true, force: true });
});

test('loadSpec throws explicit error when criticalCap.enabled is true but cappedVerdict is missing', () => {
  const spec = JSON.parse(validSpec());
  spec.criticalCap = { enabled: true, capThreshold: 59, cappedScore: 59 };
  delete spec.criticalCap.cappedVerdict;
  const file = writeTempSpec(JSON.stringify(spec));
  assert.throws(() => loadSpec(file), /criticalCap\.cappedVerdict must be a string/);
  fs.rmSync(path.dirname(file), { recursive: true, force: true });
});

test('loadSpec succeeds with valid spec and returns all expected fields', () => {
  const file = writeTempSpec(validSpec());
  const result = loadSpec(file);
  assert.equal(result.dimensions.length, 10);
  assert.equal(result.verdicts.length, 4);
  assert.equal(result.gates.length, 4);
  assert.equal(result.criticalCap.enabled, true);
  assert.equal(result.criticalCap.capThreshold, 59);
  assert.equal(result.criticalCap.cappedScore, 59);
  assert.equal(result.criticalCap.cappedVerdict, 'Needs Major Rewrite');
  fs.rmSync(path.dirname(file), { recursive: true, force: true });
});

test('loadSpec succeeds when criticalCap is disabled (no cap fields required)', () => {
  const spec = JSON.parse(validSpec());
  spec.criticalCap = { enabled: false };
  const file = writeTempSpec(JSON.stringify(spec));
  const result = loadSpec(file);
  assert.equal(result.criticalCap.enabled, false);
  fs.rmSync(path.dirname(file), { recursive: true, force: true });
});

test('loadSpec succeeds when criticalCap is entirely absent', () => {
  const spec = JSON.parse(validSpec());
  delete spec.criticalCap;
  const file = writeTempSpec(JSON.stringify(spec));
  const result = loadSpec(file);
  assert.equal(result.criticalCap.enabled, false);
  fs.rmSync(path.dirname(file), { recursive: true, force: true });
});

test('loadSpec throws explicit error when top-level value is not an object', () => {
  const file = writeTempSpec(JSON.stringify(['not', 'an', 'object']));
  assert.throws(() => loadSpec(file), /top-level value is not an object/);
  fs.rmSync(path.dirname(file), { recursive: true, force: true });
});

test('loadSpec throws explicit error when top-level value is null', () => {
  const file = writeTempSpec('null');
  assert.throws(() => loadSpec(file), /top-level value is not an object/);
  fs.rmSync(path.dirname(file), { recursive: true, force: true });
});