const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');
const {
  DIMENSIONS,
  GATES,
  SEVERITIES,
  VERDICTS,
  CRITICAL_CAP,
  ADDITIONAL_CAPS,
  DETERMINISTIC_CHECKS,
  CALIBRATION,
  PERFORMANCE_FEEDBACK,
  AUDIENCE,
  SCORING,
  computeWeightedScore,
  computeVerdict,
  isCriticalCapEnabled,
  getCriticalCapThreshold,
  getCriticalCapScore,
  getCriticalCapVerdict,
  getDimensionCount,
  getDimensionById,
  getGateById,
  getVerdictByLabel,
  getVerdictRequires,
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
  assert.equal(spec.spec.version, '2.0.0');
  assert.ok(spec.spec.sources, 'sources should be recorded');
  assert.ok(spec.spec.sources.browser, 'browser source should be recorded');
  assert.ok(spec.spec.sources.flutter, 'flutter source should be recorded');
});

// ── Dimensions ───────────────────────────────────────────────────────────

test('shared spec defines exactly 10 dimensions', () => {
  assert.equal(getDimensionCount(), 10);
  assert.equal(DIMENSIONS.length, 10);
});

test('all expected dimension IDs are present (v2)', () => {
  const expectedIds = [
    'hookStrength', 'relatabilityAudienceFit', 'payoffRetention', 'hinglishNaturalness',
    'visualFeasibility', 'soundOffReadability', 'shareSaveTrigger', 'captionCommentPackage',
    'originality', 'audioHook',
  ];
  const actualIds = DIMENSIONS.map(d => d.id);
  for (const id of expectedIds) {
    assert.ok(actualIds.includes(id), `Dimension ${id} should be present`);
  }
});

test('each dimension has id, name, weight, minScore, maxScore, anchors', () => {
  for (const dim of DIMENSIONS) {
    assert.ok(dim.id, 'dimension should have id');
    assert.ok(dim.name, 'dimension should have name');
    assert.ok(typeof dim.weight === 'number', 'dimension should have numeric weight');
    assert.equal(dim.minScore, 0);
    assert.equal(dim.maxScore, 10);
    assert.ok(dim.anchors, 'dimension should have anchors');
    assert.ok(dim.anchors['10'], 'dimension should have anchor 10');
    assert.ok(dim.anchors['6'], 'dimension should have anchor 6');
    assert.ok(dim.anchors['2'], 'dimension should have anchor 2');
  }
});

test('dimension weights total 100 (from scoring.weightsMustSumTo)', () => {
  const total = DIMENSIONS.reduce((sum, d) => sum + d.weight, 0);
  assert.equal(total, SCORING.weightsMustSumTo || 100);
});

test('individual dimension weights match expected values', () => {
  const expected = {
    hookStrength: 15, relatabilityAudienceFit: 15, payoffRetention: 14,
    hinglishNaturalness: 10, visualFeasibility: 10, soundOffReadability: 8,
    shareSaveTrigger: 8, captionCommentPackage: 8, originality: 7, audioHook: 5,
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

// ── Gates ────────────────────────────────────────────────────────────────

test('shared spec defines 4 gates', () => {
  assert.equal(GATES.length, 4);
});

test('all expected gate IDs are present', () => {
  const expectedIds = ['ageAppropriateness', 'characterConsistency', 'brandAndSafety', 'formatFit'];
  const actualIds = GATES.map(g => g.id);
  for (const id of expectedIds) {
    assert.ok(actualIds.includes(id), `Gate ${id} should be present`);
  }
});

test('each gate has id, name, description, severityOnFail', () => {
  for (const gate of GATES) {
    assert.ok(gate.id, 'gate should have id');
    assert.ok(gate.name, 'gate should have name');
    assert.ok(gate.description, 'gate should have description');
    assert.ok(['critical', 'major', 'minor', 'suggestion'].includes(gate.severityOnFail), 'gate should have valid severityOnFail');
  }
});

test('getGateById returns correct gate', () => {
  const gate = getGateById('ageAppropriateness');
  assert.ok(gate, 'ageAppropriateness gate should be found');
  assert.equal(gate.severityOnFail, 'critical');
  assert.equal(getGateById('nonexistent'), null);
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

test('verdict requires object exists for each verdict', () => {
  for (const v of VERDICTS) {
    const requires = getVerdictRequires(v.label);
    assert.ok(requires, `Verdict ${v.label} should have requires`);
    assert.ok(typeof requires.hookStrengthMin === 'number');
    assert.ok(typeof requires.payoffRetentionMin === 'number');
    assert.ok(typeof requires.criticalFindingsMax === 'number');
    assert.ok(typeof requires.majorFindingsMax === 'number');
  }
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

// ── Additional caps ──────────────────────────────────────────────────────

test('additional caps are defined', () => {
  assert.ok(Array.isArray(ADDITIONAL_CAPS));
  assert.ok(ADDITIONAL_CAPS.length >= 2);
  for (const cap of ADDITIONAL_CAPS) {
    assert.ok(cap.id, 'cap should have id');
    assert.ok(typeof cap.enabled === 'boolean');
    if (cap.enabled) {
      assert.ok(typeof cap.cappedScore === 'number');
      assert.ok(typeof cap.cappedVerdict === 'string');
    }
  }
});

// ── Deterministic checks ─────────────────────────────────────────────────

test('deterministic checks are defined', () => {
  assert.ok(DETERMINISTIC_CHECKS.checks);
  assert.ok(Array.isArray(DETERMINISTIC_CHECKS.checks));
  assert.ok(DETERMINISTIC_CHECKS.checks.length >= 15);
  for (const check of DETERMINISTIC_CHECKS.checks) {
    assert.ok(check.id, 'check should have id');
    assert.ok(check.name, 'check should have name');
    assert.ok(check.description, 'check should have description');
    assert.ok(['critical', 'major', 'minor', 'suggestion'].includes(check.severity));
    assert.ok(check.gate, 'check should reference a gate');
  }
});

// ── Calibration, Performance Feedback, Audience ──────────────────────────

test('calibration config exists', () => {
  assert.ok(CALIBRATION);
  assert.ok(CALIBRATION.targetDistributions);
});

test('performanceFeedback config exists', () => {
  assert.ok(PERFORMANCE_FEEDBACK);
  assert.equal(PERFORMANCE_FEEDBACK.enabled, true);
});

test('audience config exists', () => {
  assert.ok(AUDIENCE);
  assert.equal(AUDIENCE.primary, 'Parents of children aged 1-4');
  assert.equal(AUDIENCE.charactersShownAged, '1-4');
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
  const midScores = DIMENSIONS.map(d => ({ id: d.id, score: 5 }));
  assert.equal(computeWeightedScore(midScores), 50);
});

test('computeWeightedScore handles missing dimension entries as 0', () => {
  const partial = [{ id: 'hookStrength', score: 10 }];
  assert.equal(computeWeightedScore(partial), 15);
});

// ── Offline evaluation compatibility ─────────────────────────────────────

test('offline evaluation returns all 10 dimension scores', () => {
  const idea = ideas.find(i => i.id === 'idea_1');
  assert.ok(idea, 'idea_1 should exist');
  const result = offlineEvaluate(idea, ideas);
  assert.equal(result.dimensionScores.length, 10);
  for (const dim of DIMENSIONS) {
    const entry = result.dimensionScores.find(d => d.id === dim.id);
    assert.ok(entry, `Dimension ${dim.id} should be in result`);
    assert.equal(entry.weight, dim.weight, `Weight for ${dim.id} should match spec`);
    assert.ok(entry.anchorMatched, `Dimension ${dim.id} should have anchorMatched`);
  }
});

test('offline evaluation result has v2 fields', () => {
  const idea = ideas.find(i => i.id === 'idea_1');
  const result = offlineEvaluate(idea, ideas);
  assert.ok(typeof result.overallScore === 'number');
  assert.ok(typeof result.rawScore === 'number');
  assert.ok(typeof result.scoreCapped === 'boolean');
  assert.ok(Array.isArray(result.capsApplied));
  assert.ok(Array.isArray(result.gateResults));
  assert.ok(result.gateResults.length === 4);
  assert.ok(Array.isArray(result.fixesToReach10));
  assert.ok(typeof result.potentialScore === 'number');
  assert.ok(typeof result.rewrittenHook === 'string');
  assert.ok(Array.isArray(result.duplicateOf));
  assert.ok(typeof result.recommendedFormat === 'string');
  assert.ok(typeof result.confidence === 'string');
  assert.ok(Array.isArray(result.deterministicChecks));
  assert.equal(result.evaluationVersion, '2.0.0');
});

test('offline evaluation critical cap applies when critical findings exist and score > 59', () => {
  const result = offlineEvaluate({
    id: 'cap-test',
    title: 'Rio hit Mumma',
    cover: 'Test cover',
    opening: 'Test opening hook with a question?',
    problem: 'Test problem description',
    lesson: 'Test lesson',
    storyDetail: 'Story: Test story with twist resolution and moral ending',
    endingBeat: 'Test ending beat',
    caption: 'Test caption with hashtags #funlearningwithpalak #parenting #tips #kids #family',
    pinnedComment: 'Test pinned comment?',
    dialogue: 'Test dialogue chalo haan',
    defaultCast: ['Rio', 'Mumma'],
    category: 'Safety',
    setting: 'Test setting',
    sceneDetail: 'Test scene detail',
    postFormat: 'Reel',
  }, ideas);
  assert.ok(result.criticalFindings.length > 0, 'Should have critical findings for unsafe language');
  if (result.rawScore > 59) {
    assert.equal(result.scoreCapped, true);
    assert.equal(result.overallScore, 59);
    assert.equal(result.verdict, 'Needs Major Rewrite');
    assert.ok(result.capsApplied.includes('criticalCap'));
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
    postFormat: 'Reel',
  }, ideas);
  assert.ok(result.criticalFindings.length > 0, 'Should have critical findings');
  assert.equal(result.scoreCapped, false);
});

// ── Deterministic check regression tests ─────────────────────────────────

test('idea_4 flagged for placeholder text (XXXXXXXXXX)', () => {
  const idea = ideas.find(i => i.id === 'idea_4');
  assert.ok(idea, 'idea_4 should exist');
  const result = offlineEvaluate(idea, ideas);
  const check = result.deterministicChecks.find(c => c.id === 'placeholderText');
  assert.ok(check, 'placeholderText check should exist');
  assert.equal(check.passed, false, 'Should fail placeholderText check');
});

test('idea_46 flagged for empty readyPrompt and archived placeholder', () => {
  const idea = ideas.find(i => i.id === 'idea_46');
  assert.ok(idea, 'idea_46 should exist');
  assert.equal(idea.archived, true);
  const result = offlineEvaluate(idea, ideas);
  const check = result.deterministicChecks.find(c => c.id === 'placeholderText');
  assert.ok(check, 'placeholderText check should exist');
  assert.equal(check.passed, false, 'Should fail placeholderText check for Archived');
});

test('idea_1 flagged for opening cast mismatch (Uncle vs Daadi)', () => {
  const idea = ideas.find(i => i.id === 'idea_1');
  assert.ok(idea, 'idea_1 should exist');
  const result = offlineEvaluate(idea, ideas);
  const check = result.deterministicChecks.find(c => c.id === 'openingCastMismatch');
  assert.ok(check, 'openingCastMismatch check should exist');
  assert.equal(check.passed, false, 'Should fail openingCastMismatch check');
});

test('idea_5 and idea_6 flagged for pinned comment copied from another idea', () => {
  for (const id of ['idea_5', 'idea_6']) {
    const idea = ideas.find(i => i.id === id);
    assert.ok(idea, `${id} should exist`);
    const result = offlineEvaluate(idea, ideas);
    const check = result.deterministicChecks.find(c => c.id === 'pinnedCommentMismatch');
    assert.ok(check, 'pinnedCommentMismatch check should exist');
  }
});

test('ideas 2, 14, 15, 17 flagged for generic pinned comment', () => {
  for (const id of ['idea_2', 'idea_14', 'idea_15', 'idea_17']) {
    const idea = ideas.find(i => i.id === id);
    assert.ok(idea, `${id} should exist`);
    const result = offlineEvaluate(idea, ideas);
    const check = result.deterministicChecks.find(c => c.id === 'genericPinnedComment');
    assert.ok(check, 'genericPinnedComment check should exist');
    assert.equal(check.passed, false, `${id} should fail genericPinnedComment check`);
  }
});

test('ideas 52 and 53 flagged for brand names Britannia / Parle-G', () => {
  for (const id of ['idea_52', 'idea_53']) {
    const idea = ideas.find(i => i.id === id);
    assert.ok(idea, `${id} should exist`);
    const result = offlineEvaluate(idea, ideas);
    const check = result.deterministicChecks.find(c => c.id === 'brandNames');
    assert.ok(check, 'brandNames check should exist');
    assert.equal(check.passed, false, `${id} should fail brandNames check`);
  }
});

test('ideas with Pixar in readyPrompt flagged for IP-style term', () => {
  const pixarIdeas = ideas.filter(i => i.readyPrompt && i.readyPrompt.toLowerCase().includes('pixar'));
  assert.ok(pixarIdeas.length > 0, 'Should have ideas with Pixar in readyPrompt');
  for (const idea of pixarIdeas) {
    const result = offlineEvaluate(idea, ideas);
    const check = result.deterministicChecks.find(c => c.id === 'brandNames');
    assert.ok(check, 'brandNames check should exist');
    assert.equal(check.passed, false, `${idea.id} should fail brandNames check for Pixar`);
  }
});

// ── No duplicated constants ──────────────────────────────────────────────

test('DIMENSIONS are derived from shared spec, not hardcoded', () => {
  const specDimensions = spec.dimensions.map(d => ({ id: d.id, name: d.name, weight: d.weight }));
  assert.equal(DIMENSIONS.length, specDimensions.length);
  for (let i = 0; i < DIMENSIONS.length; i++) {
    assert.equal(DIMENSIONS[i].id, specDimensions[i].id);
    assert.equal(DIMENSIONS[i].name, specDimensions[i].name);
    assert.equal(DIMENSIONS[i].weight, specDimensions[i].weight);
  }
});

test('GATES are derived from shared spec, not hardcoded', () => {
  const specGates = spec.gates.map(g => ({ id: g.id, name: g.name, severityOnFail: g.severityOnFail }));
  assert.equal(GATES.length, specGates.length);
  for (let i = 0; i < GATES.length; i++) {
    assert.equal(GATES[i].id, specGates[i].id);
    assert.equal(GATES[i].name, specGates[i].name);
    assert.equal(GATES[i].severityOnFail, specGates[i].severityOnFail);
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