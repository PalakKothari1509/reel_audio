const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');
const {
  DIMENSIONS,
  SEVERITIES,
  VERDICTS,
  CRITICAL_CAP,
  computeWeightedScore,
  computeVerdict,
  isCriticalCapEnabled,
  getCriticalCapThreshold,
  getCriticalCapScore,
  getCriticalCapVerdict,
  getDimensionCount,
  getDimensionById,
  SPEC_PATH,
} = require('./schemas');
const { offlineEvaluate } = require('./ratingEngine');

const specRaw = fs.readFileSync(SPEC_PATH, 'utf8');
const spec = JSON.parse(specRaw);

const ideasPath = path.resolve(__dirname, '../../../assets/data/content_ideas.json');
const ideas = JSON.parse(fs.readFileSync(ideasPath, 'utf8')).ideas;

// ── Shared spec loading ──────────────────────────────────────────────────

test('shared spec loads from evaluation_rules.json', () => {
  assert.ok(spec, 'spec should be loaded');
  assert.ok(spec.dimensions, 'spec.dimensions should exist');
});

test('shared spec has source and version metadata', () => {
  assert.equal(spec.spec.id, 'shared-evaluation-rules');
  assert.equal(spec.spec.version, '1.0.0');
  assert.ok(spec.spec.sources, 'sources should be recorded');
  assert.ok(spec.spec.sources.browser, 'browser source should be recorded');
  assert.ok(spec.spec.sources.flutter, 'flutter source should be recorded');
});

// ── Dimensions ───────────────────────────────────────────────────────────

test('shared spec defines exactly 10 dimensions', () => {
  assert.equal(getDimensionCount(), 10);
  assert.equal(DIMENSIONS.length, 10);
});

test('all expected dimension IDs are present', () => {
  const expectedIds = [
    'hookStrength', 'relatability', 'storyStructure', 'ageAppropriateness',
    'hinglishNaturalness', 'characterConsistency', 'visualFeasibility',
    'soundOffReadability', 'engagementPotential', 'brandAndSafety',
  ];
  const actualIds = DIMENSIONS.map(d => d.id);
  for (const id of expectedIds) {
    assert.ok(actualIds.includes(id), `Dimension ${id} should be present`);
  }
});

test('each dimension has id, name, weight, minScore, maxScore', () => {
  for (const dim of DIMENSIONS) {
    assert.ok(dim.id, 'dimension should have id');
    assert.ok(dim.name, 'dimension should have name');
    assert.ok(typeof dim.weight === 'number', 'dimension should have numeric weight');
    assert.equal(dim.minScore, 0);
    assert.equal(dim.maxScore, 10);
  }
});

test('dimension weights total 100', () => {
  const total = DIMENSIONS.reduce((sum, d) => sum + d.weight, 0);
  assert.equal(total, 100);
});

test('individual dimension weights match expected values', () => {
  const expected = {
    hookStrength: 15, relatability: 15, storyStructure: 12,
    ageAppropriateness: 10, hinglishNaturalness: 10,
    characterConsistency: 8, visualFeasibility: 8,
    soundOffReadability: 7, engagementPotential: 8, brandAndSafety: 7,
  };
  for (const dim of DIMENSIONS) {
    assert.equal(dim.weight, expected[dim.id], `Weight for ${dim.id} should be ${expected[dim.id]}`);
  }
});

test('getDimensionById returns correct dimension', () => {
  const dim = getDimensionById('hookStrength');
  assert.ok(dim, 'hookStrength dimension should be found');
  assert.equal(dim.name, 'Hook Strength');
  assert.equal(dim.weight, 15);
  assert.equal(getDimensionById('nonexistent'), null);
});

// ── Severities ───────────────────────────────────────────────────────────

test('severities are critical, major, minor, suggestion', () => {
  assert.deepEqual(SEVERITIES, ['critical', 'major', 'minor', 'suggestion']);
});

// ── Verdict thresholds ───────────────────────────────────────────────────

test('verdict thresholds match expected values', () => {
  const expected = [
    { label: 'Ready to Post', minScore: 80, maxScore: 100 },
    { label: 'Needs Minor Fixes', minScore: 65, maxScore: 79 },
    { label: 'Needs Major Rewrite', minScore: 45, maxScore: 64 },
    { label: 'Reject', minScore: 0, maxScore: 44 },
  ];
  assert.equal(VERDICTS.length, 4);
  for (let i = 0; i < expected.length; i++) {
    assert.equal(VERDICTS[i].label, expected[i].label);
    assert.equal(VERDICTS[i].minScore, expected[i].minScore);
    assert.equal(VERDICTS[i].maxScore, expected[i].maxScore);
  }
});

test('computeVerdict returns correct labels for score boundaries', () => {
  assert.equal(computeVerdict(100), 'Ready to Post');
  assert.equal(computeVerdict(80), 'Ready to Post');
  assert.equal(computeVerdict(79), 'Needs Minor Fixes');
  assert.equal(computeVerdict(65), 'Needs Minor Fixes');
  assert.equal(computeVerdict(64), 'Needs Major Rewrite');
  assert.equal(computeVerdict(45), 'Needs Major Rewrite');
  assert.equal(computeVerdict(44), 'Reject');
  assert.equal(computeVerdict(0), 'Reject');
});

// ── Critical cap ─────────────────────────────────────────────────────────

test('critical cap is enabled', () => {
  assert.equal(isCriticalCapEnabled(), true);
});

test('critical cap threshold is 59', () => {
  assert.equal(getCriticalCapThreshold(), 59);
});

test('critical cap score is 59', () => {
  assert.equal(getCriticalCapScore(), 59);
});

test('critical cap verdict is Needs Major Rewrite', () => {
  assert.equal(getCriticalCapVerdict(), 'Needs Major Rewrite');
});

test('critical cap config comes from shared spec', () => {
  assert.equal(CRITICAL_CAP.enabled, true);
  assert.equal(CRITICAL_CAP.capThreshold, 59);
  assert.equal(CRITICAL_CAP.cappedScore, 59);
  assert.equal(CRITICAL_CAP.cappedVerdict, 'Needs Major Rewrite');
});

// ── Score calculation ────────────────────────────────────────────────────

test('computeWeightedScore returns 100 for all max scores', () => {
  const maxScores = DIMENSIONS.map(d => ({ id: d.id, score: 10 }));
  assert.equal(computeWeightedScore(maxScores), 100);
});

test('computeWeightedScore returns 0 for all zero scores', () => {
  const zeroScores = DIMENSIONS.map(d => ({ id: d.id, score: 0 }));
  assert.equal(computeWeightedScore(zeroScores), 0);
});

test('computeWeightedScore calculates weighted average correctly', () => {
  // All scores = 5, so weighted score = sum(0.5 * weight) = 0.5 * 100 = 50
  const midScores = DIMENSIONS.map(d => ({ id: d.id, score: 5 }));
  assert.equal(computeWeightedScore(midScores), 50);
});

test('computeWeightedScore handles missing dimension entries as 0', () => {
  const partial = [{ id: 'hookStrength', score: 10 }];
  // Only hookStrength (weight 15) contributes: (10/10) * 15 = 15
  assert.equal(computeWeightedScore(partial), 15);
});

// ── Offline evaluation compatibility ─────────────────────────────────────

test('offline evaluation returns all 10 dimension scores', () => {
  const idea = ideas.find(i => i.id === 'idea_1');
  assert.ok(idea, 'idea_1 should exist');
  const result = offlineEvaluate(idea);
  assert.equal(result.dimensionScores.length, 10);
  for (const dim of DIMENSIONS) {
    const entry = result.dimensionScores.find(d => d.id === dim.id);
    assert.ok(entry, `Dimension ${dim.id} should be in result`);
    assert.equal(entry.weight, dim.weight, `Weight for ${dim.id} should match spec`);
  }
});

test('offline evaluation result has overallScore and rawScore', () => {
  const idea = ideas.find(i => i.id === 'idea_1');
  const result = offlineEvaluate(idea);
  assert.ok(typeof result.overallScore === 'number');
  assert.ok(typeof result.rawScore === 'number');
  assert.ok(typeof result.scoreCapped === 'boolean');
});

test('offline evaluation critical cap applies when critical findings exist and score > 59', () => {
  // Create an idea with unsafe language and high scores to trigger cap
  const result = offlineEvaluate({
    id: 'cap-test',
    title: 'Rio hit Mumma',
    cover: 'Test cover',
    opening: 'Test opening hook with a question?',
    problem: 'Test problem description',
    lesson: 'Test lesson',
    storyDetail: 'Test story with twist resolution and moral ending',
    endingBeat: 'Test ending beat',
    caption: 'Test caption with hashtags #funlearningwithpalak #parenting #tips #kids #family',
    pinnedComment: 'Test pinned comment?',
    dialogue: 'Test dialogue chalo haan',
    defaultCast: ['Rio', 'Mumma'],
    category: 'Safety',
    setting: 'Test setting',
    sceneDetail: 'Test scene detail',
  });
  assert.ok(result.criticalFindings.length > 0, 'Should have critical findings for unsafe language');
  if (result.rawScore > 59) {
    assert.equal(result.scoreCapped, true);
    assert.equal(result.overallScore, 59);
    assert.equal(result.verdict, 'Needs Major Rewrite');
  }
});

test('offline evaluation does not cap when score <= 59 even with critical findings', () => {
  const result = offlineEvaluate({
    id: 'no-cap-test',
    title: 'Rio hit Mumma',
    cover: '',
    opening: '',
    problem: '',
    lesson: '',
    storyDetail: '',
    endingBeat: '',
    caption: '',
    pinnedComment: '',
    dialogue: '',
    defaultCast: [],
    category: 'Safety',
    setting: '',
    sceneDetail: '',
  });
  assert.ok(result.criticalFindings.length > 0, 'Should have critical findings');
  // With all empty fields, raw score will be low, so no cap
  assert.equal(result.scoreCapped, false);
});

// ── No duplicated constants ─────────────────────────────────────────────

test('DIMENSIONS are derived from shared spec, not hardcoded', () => {
  const specDimensions = spec.dimensions.map(d => ({ id: d.id, name: d.name, weight: d.weight }));
  assert.equal(DIMENSIONS.length, specDimensions.length);
  for (let i = 0; i < DIMENSIONS.length; i++) {
    assert.equal(DIMENSIONS[i].id, specDimensions[i].id);
    assert.equal(DIMENSIONS[i].name, specDimensions[i].name);
    assert.equal(DIMENSIONS[i].weight, specDimensions[i].weight);
  }
});

test('SEVERITIES are derived from shared spec', () => {
  const specSeverities = spec.severities.map(s => s.id);
  assert.deepEqual(SEVERITIES, specSeverities);
});

test('VERDICTS are derived from shared spec', () => {
  const specVerdicts = spec.verdicts.map(v => ({ label: v.label, minScore: v.minScore, maxScore: v.maxScore }));
  assert.equal(VERDICTS.length, specVerdicts.length);
  for (let i = 0; i < VERDICTS.length; i++) {
    assert.equal(VERDICTS[i].label, specVerdicts[i].label);
    assert.equal(VERDICTS[i].minScore, specVerdicts[i].minScore);
    assert.equal(VERDICTS[i].maxScore, specVerdicts[i].maxScore);
  }
});
