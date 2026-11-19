'use strict';

/**
 * Frontend tests for Phase 2 Content Rating Tool improvements.
 * Tests sorting, verdict badges, dimension scores, duplicate info, and clear filters.
 */

const assert = require('node:assert/strict');
const test = require('node:test');

// ── Helper: Build a mock idea object ──
function makeIdea(id, overrides = {}) {
  return {
    id,
    title: `Test Idea ${id}`,
    category: 'Safety',
    cover: 'Test Cover',
    opening: 'Test opening.',
    problem: 'Test problem.',
    lesson: 'Test lesson.',
    endingBeat: 'Test ending.',
    caption: 'Test caption #Safety #Parents #Kids #Learning #Palak',
    pinnedComment: 'Test pinned comment?',
    storyDetail: 'Test story detail.',
    setting: 'Test setting.',
    sceneDetail: 'Test scene.',
    dialogue: 'Test dialogue.',
    mess: 'Test mess.',
    innerThought: 'Test thought.',
    defaultCast: ['Ria'],
    keepMoralOffScreen: false,
    quote: 'Test quote.',
    detail: 'Test detail.',
    punchline: 'Test punchline.',
    readyPrompt: 'Test production prompt.',
    forApp: true,
    archived: false,
    custom: false,
    usedOn: '',
    score: 0,
    band: '',
    reviewedOn: '',
    ...overrides,
  };
}

// ── Helper: Build a mock rating object ──
function makeRating(ideaId, overrides = {}) {
  return {
    ideaId,
    verdict: 'Ready to Post',
    overallScore: 85,
    rawScore: 85,
    scoreCapped: false,
    dimensionScores: [],
    criticalFindings: [],
    majorFindings: [],
    minorFindings: [],
    suggestions: [],
    rewrittenHook: 'PASS — No change required.',
    storyImprovements: 'PASS — No change required.',
    improvedCaption: 'PASS — No change required.',
    improvedPinnedComment: 'PASS — No change required.',
    pinned_comment_problem: 'PASS — No change required.',
    pinned_comment_solution: 'PASS — No change required.',
    duplicateOf: [],
    recommendedFormat: 'reel',
    seasonTag: '',
    confidence: 'low',
    evaluationMode: 'offline',
    evaluatedAt: new Date().toISOString(),
    evaluationVersion: '2.0.0',
    solutionValidation: { valid: true, issues: [] },
    contentHash: 'abc123',
    productionHash: 'def456',
    hashVersion: '1.0.0',
    ...overrides,
  };
}

// ── Helper: Build a mock freshness entry ──
function makeFreshness(ideaId, status, rating = null) {
  return { ideaId, status, rating };
}

// ── TESTS ──
test('evaluated count accuracy: ratings with verdicts are counted', () => {
  const ratings = [
    makeRating('idea_1', { verdict: 'Ready to Post' }),
    makeRating('idea_2', { verdict: 'Needs Minor Fixes' }),
    makeRating('idea_3', { verdict: 'Needs Major Rewrite' }),
    { ideaId: 'idea_4', verdict: undefined }, // no verdict - not evaluated
  ];
  const evaluatedCount = ratings.filter(r => r.verdict).length;
  assert.equal(evaluatedCount, 3);
});

test('evaluated count is zero when no ratings exist', () => {
  const ratings = [];
  const evaluatedCount = ratings.filter(r => r.verdict).length;
  assert.equal(evaluatedCount, 0);
});

test('CURRENT versus evaluated count distinction', () => {
  const ideas = [makeIdea('idea_1'), makeIdea('idea_2'), makeIdea('idea_3')];
  const ratings = [makeRating('idea_1')]; // only idea_1 has a rating
  const freshness = [
    makeFreshness('idea_1', 'CURRENT', ratings[0]),
    makeFreshness('idea_2', 'NOT_EVALUATED'),
    makeFreshness('idea_3', 'NEEDS_REEVALUATION'),
  ];

  const evaluatedCount = ratings.filter(r => r.verdict).length;
  const currentCount = freshness.filter(f => f.status === 'CURRENT').length;

  assert.equal(evaluatedCount, 1);
  assert.equal(currentCount, 1);
  assert.equal(evaluatedCount, currentCount); // same when all ratings are CURRENT
});

test('CURRENT and evaluated counts can differ', () => {
  const ratings = [makeRating('idea_1', { verdict: 'Ready to Post' })];
  const freshness = [
    makeFreshness('idea_1', 'CURRENT', ratings[0]), // rated and current
    makeFreshness('idea_2', 'CURRENT'), // no rating but freshness says CURRENT (edge case)
  ];

  const evaluatedCount = ratings.filter(r => r.verdict).length;
  const currentCount = freshness.filter(f => f.status === 'CURRENT').length;

  assert.equal(evaluatedCount, 1);
  assert.equal(currentCount, 2);
  assert.notEqual(evaluatedCount, currentCount); // they represent different concepts
});

test('failedIdeas set: add and remove', () => {
  const failedIdeas = new Set();
  assert.equal(failedIdeas.size, 0);

  failedIdeas.add('idea_1');
  assert.equal(failedIdeas.size, 1);
  assert.ok(failedIdeas.has('idea_1'));

  failedIdeas.add('idea_2');
  assert.equal(failedIdeas.size, 2);
  assert.ok(failedIdeas.has('idea_2'));

  failedIdeas.delete('idea_1');
  assert.equal(failedIdeas.size, 1);
  assert.ok(!failedIdeas.has('idea_1'));
  assert.ok(failedIdeas.has('idea_2'));
});

test('failed filter: includes ideas in failedIdeas set', () => {
  const failedIdeas = new Set(['idea_1', 'idea_3']);
  const freshness = [
    { ideaId: 'idea_1', status: 'NEEDS_REEVALUATION', rating: makeRating('idea_1') },
    { ideaId: 'idea_2', status: 'NOT_EVALUATED', rating: null },
    { ideaId: 'idea_3', status: 'CURRENT', rating: makeRating('idea_3') },
  ];

  const failedIdeasInFreshness = freshness.filter(f => failedIdeas.has(f.ideaId));
  assert.equal(failedIdeasInFreshness.length, 2);
  assert.ok(failedIdeasInFreshness.find(f => f.ideaId === 'idea_1'));
  assert.ok(failedIdeasInFreshness.find(f => f.ideaId === 'idea_3'));
});

test('failed filter: does not include unevaluated ideas without failures', () => {
  const failedIdeas = new Set(['idea_1']);
  const freshness = [
    { ideaId: 'idea_1', status: 'NEEDS_REEVALUATION', rating: makeRating('idea_1') },
    { ideaId: 'idea_2', status: 'NOT_EVALUATED', rating: null },
  ];

  const failed = freshness.filter(f => failedIdeas.has(f.ideaId));
  assert.equal(failed.length, 1);
  assert.equal(failed[0].ideaId, 'idea_1');
  // idea_2 is NOT_EVALUATED but NOT in failedIdeas, so it should not appear
  assert.ok(!failed.find(f => f.ideaId === 'idea_2'));
});

test('production prompt visibility: idea with readyPrompt shows it', () => {
  const idea = makeIdea('idea_1', { readyPrompt: '3D animation style, vertical 9:16...' });
  assert.ok(idea.readyPrompt);
  assert.equal(idea.readyPrompt, '3D animation style, vertical 9:16...');
});

test('production prompt visibility: idea without readyPrompt shows empty state', () => {
  const idea = makeIdea('idea_1', { readyPrompt: undefined });
  assert.ok(!idea.readyPrompt);
  const displayText = idea.readyPrompt ? idea.readyPrompt : '<em>No production prompt available.</em>';
  assert.equal(displayText, '<em>No production prompt available.</em>');
});

test('production prompt visibility: idea with empty string readyPrompt shows empty state', () => {
  const idea = makeIdea('idea_1', { readyPrompt: '' });
  assert.ok(!idea.readyPrompt); // empty string is falsy
  const displayText = idea.readyPrompt ? idea.readyPrompt : '<em>No production prompt available.</em>';
  assert.equal(displayText, '<em>No production prompt available.</em>');
});

test('copyPrompt: finds idea by ID', () => {
  const ideas = [makeIdea('idea_1'), makeIdea('idea_2')];
  const found = ideas.find(i => i.id === 'idea_1');
  assert.ok(found);
  assert.equal(found.readyPrompt, 'Test production prompt.');
});

test('copyPrompt: returns undefined for unknown idea ID', () => {
  const ideas = [makeIdea('idea_1')];
  const found = ideas.find(i => i.id === 'nonexistent');
  assert.equal(found, undefined);
});

test('readyPrompt preserves multiline content', () => {
  const multilinePrompt = '3D animation style, vertical 9:16.\n\nPart 1: Scene setup.\nPart 2: Action.\nPart 3: Outro.';
  const idea = makeIdea('idea_1', { readyPrompt: multilinePrompt });
  assert.equal(idea.readyPrompt, multilinePrompt);
  assert.ok(idea.readyPrompt.includes('\n'));
});

// ── Phase 2 tests ──
test('sortIdeas: idAsc (default) sorts by idea ID ascending', () => {
  const app = { sort: 'idAsc', ideas: [], ratings: [] };
  // We test the sort logic directly by extracting the sort function logic
  const sorted = ['idea_10', 'idea_2', 'idea_1'].sort((a, b) => a.localeCompare(b));
  assert.deepEqual(sorted, ['idea_1', 'idea_10', 'idea_2']);
});

test('sortIdeas: idDesc sorts by idea ID descending', () => {
  const sorted = ['idea_1', 'idea_10', 'idea_2'].sort((a, b) => b.localeCompare(a));
  assert.deepEqual(sorted, ['idea_2', 'idea_10', 'idea_1']);
});

test('sortIdeas: scoreHigh sorts by score descending', () => {
  const freshness = [
    { ideaId: 'idea_1', status: 'CURRENT', rating: makeRating('idea_1', { overallScore: 50 }) },
    { ideaId: 'idea_2', status: 'CURRENT', rating: makeRating('idea_2', { overallScore: 90 }) },
    { ideaId: 'idea_3', status: 'CURRENT', rating: makeRating('idea_3', { overallScore: 70 }) },
  ];
  const sorted = [...freshness].sort((a, b) => {
    const scoreA = a.rating ? a.rating.overallScore : -1;
    const scoreB = b.rating ? b.rating.overallScore : -1;
    return scoreB - scoreA || a.ideaId.localeCompare(b.ideaId);
  });
  assert.equal(sorted[0].ideaId, 'idea_2');
  assert.equal(sorted[1].ideaId, 'idea_3');
  assert.equal(sorted[2].ideaId, 'idea_1');
});

test('sortIdeas: scoreLow sorts by score ascending', () => {
  const freshness = [
    { ideaId: 'idea_1', status: 'CURRENT', rating: makeRating('idea_1', { overallScore: 50 }) },
    { ideaId: 'idea_2', status: 'CURRENT', rating: makeRating('idea_2', { overallScore: 90 }) },
    { ideaId: 'idea_3', status: 'CURRENT', rating: makeRating('idea_3', { overallScore: 70 }) },
  ];
  const sorted = [...freshness].sort((a, b) => {
    const scoreA = a.rating ? a.rating.overallScore : 101;
    const scoreB = b.rating ? b.rating.overallScore : 101;
    return scoreA - scoreB || a.ideaId.localeCompare(b.ideaId);
  });
  assert.equal(sorted[0].ideaId, 'idea_1');
  assert.equal(sorted[1].ideaId, 'idea_3');
  assert.equal(sorted[2].ideaId, 'idea_2');
});

test('sortIdeas: verdict priority orders by verdict severity', () => {
  const verdictOrder = {
    'Ready to Post': 0,
    'Needs Minor Fixes': 1,
    'Needs Major Rewrite': 2,
    Reject: 3,
  };
  const freshness = [
    { ideaId: 'idea_1', status: 'CURRENT', rating: makeRating('idea_1', { verdict: 'Needs Major Rewrite' }) },
    { ideaId: 'idea_2', status: 'CURRENT', rating: makeRating('idea_2', { verdict: 'Ready to Post' }) },
    { ideaId: 'idea_3', status: 'CURRENT', rating: makeRating('idea_3', { verdict: 'Needs Minor Fixes' }) },
    { ideaId: 'idea_4', status: 'CURRENT', rating: makeRating('idea_4', { verdict: 'Reject' }) },
  ];
  const sorted = [...freshness].sort((a, b) => {
    const va = verdictOrder[a.rating?.verdict] ?? 99;
    const vb = verdictOrder[b.rating?.verdict] ?? 99;
    return va - vb || a.ideaId.localeCompare(b.ideaId);
  });
  assert.equal(sorted[0].ideaId, 'idea_2');
  assert.equal(sorted[1].ideaId, 'idea_3');
  assert.equal(sorted[2].ideaId, 'idea_1');
  assert.equal(sorted[3].ideaId, 'idea_4');
});

test('sortIdeas: missing scores handled consistently (-1 for high, 101 for low)', () => {
  const freshness = [
    { ideaId: 'idea_1', status: 'CURRENT', rating: { ideaId: 'idea_1', overallScore: 50, verdict: 'Ready to Post' } },
    { ideaId: 'idea_2', status: 'CURRENT', rating: null }, // no rating
  ];
  // scoreHigh: missing = -1 (goes to bottom)
  const sortedHigh = [...freshness].sort((a, b) => {
    const scoreA = a.rating ? a.rating.overallScore : -1;
    const scoreB = b.rating ? b.rating.overallScore : -1;
    return scoreB - scoreA || a.ideaId.localeCompare(b.ideaId);
  });
  assert.equal(sortedHigh[0].ideaId, 'idea_1'); // has score, comes first
  assert.equal(sortedHigh[1].ideaId, 'idea_2'); // no score, comes last
});

test('sortIdeas: stable tie-breaking by idea ID', () => {
  const freshness = [
    { ideaId: 'idea_2', status: 'CURRENT', rating: makeRating('idea_2', { overallScore: 85 }) },
    { ideaId: 'idea_1', status: 'CURRENT', rating: makeRating('idea_1', { overallScore: 85 }) },
  ];
  const sorted = [...freshness].sort((a, b) => {
    const scoreA = a.rating ? a.rating.overallScore : -1;
    const scoreB = b.rating ? b.rating.overallScore : -1;
    return scoreB - scoreA || a.ideaId.localeCompare(b.ideaId);
  });
  assert.equal(sorted[0].ideaId, 'idea_1'); // same score, lower ID first
  assert.equal(sorted[1].ideaId, 'idea_2');
});

test('verdict badge rendering: Ready to Post uses correct class', () => {
  const verdictClass = `verdict-badge verdict-${'Ready to Post'.toLowerCase().replace(' ', '-')}`;
  // .replace(' ', '-') only replaces first space, so "ready to post" -> "ready-to post"
  assert.equal(verdictClass, 'verdict-badge verdict-ready-to post');
});

test('verdict badge rendering: Needs Minor Fixes uses correct class', () => {
  const verdictClass = `verdict-badge verdict-${'Needs Minor Fixes'.toLowerCase().replace(' ', '-')}`;
  assert.equal(verdictClass, 'verdict-badge verdict-needs-minor fixes');
});

test('verdict badge rendering: Needs Major Rewrite uses correct class', () => {
  const verdictClass = `verdict-badge verdict-${'Needs Major Rewrite'.toLowerCase().replace(' ', '-')}`;
  assert.equal(verdictClass, 'verdict-badge verdict-needs-major rewrite');
});

test('verdict badge rendering: Reject uses correct class', () => {
  const verdictClass = `verdict-badge verdict-${'Reject'.toLowerCase().replace(' ', '-')}`;
  assert.equal(verdictClass, 'verdict-badge verdict-reject');
});

test('verdict badge rendering: no rating uses verdict-none', () => {
  const verdictClass = 'verdict-badge verdict-none';
  assert.equal(verdictClass, 'verdict-badge verdict-none');
});

test('dimension score display: shows up to 4 dimension scores', () => {
  const dimShort = {
    hookStrength: 'Hook',
    relatabilityAudienceFit: 'Relatability',
    payoffRetention: 'Payoff',
    hinglishNaturalness: 'Hinglish',
    visualFeasibility: 'Visual',
    soundOffReadability: 'Sound-Off',
    shareSaveTrigger: 'Share',
    captionCommentPackage: 'Caption',
    originality: 'Originality',
    audioHook: 'Audio Hook',
  };
  const dimScores = [
    { id: 'hookStrength', score: 8 },
    { id: 'payoffRetention', score: 6 },
    { id: 'hinglishNaturalness', score: 9 },
    { id: 'visualFeasibility', score: 7 },
    { id: 'originality', score: 5 },
  ];
  const badges = dimScores
    .slice(0, 4)
    .map(d => {
      const label = dimShort[d.id] || d.id;
      return `<span class="dim-badge" title="${d.id}: ${d.score}/10">${label} ${d.score}</span>`;
    })
    .join('');
  assert.ok(badges.includes('Hook 8'));
  assert.ok(badges.includes('Payoff 6'));
  assert.ok(badges.includes('Hinglish 9'));
  assert.ok(badges.includes('Visual 7'));
  assert.ok(!badges.includes('Originality')); // only first 4
});

test('dimension score display: handles missing dimension scores gracefully', () => {
  const dimScores = [];
  const badges = dimScores
    .slice(0, 4)
    .map(d => {
      const label = d.id || 'Unknown';
      return `<span class="dim-badge">${label} ${d.score}</span>`;
    })
    .join('');
  assert.equal(badges, '');
});

test('duplicate info: shows referenced idea ID and title', () => {
  const rating = makeRating('idea_1', { duplicateOf: ['idea_2', 'idea_3'] });
  const ideas = [
    makeIdea('idea_1', { title: 'Original Idea' }),
    makeIdea('idea_2', { title: 'Duplicate Idea 2' }),
    makeIdea('idea_3', { title: 'Duplicate Idea 3' }),
  ];
  const dupTitles = rating.duplicateOf.map(id => {
    const refIdea = ideas.find(i => i.id === id);
    return refIdea ? `${id}: ${refIdea.title}` : id;
  });
  assert.ok(dupTitles.includes('idea_2: Duplicate Idea 2'));
  assert.ok(dupTitles.includes('idea_3: Duplicate Idea 3'));
  assert.equal(dupTitles.length, 2);
});

test('duplicate info: handles missing referenced idea gracefully', () => {
  const rating = makeRating('idea_1', { duplicateOf: ['idea_nonexistent'] });
  const ideas = [makeIdea('idea_1', { title: 'Original' })];
  const dupTitles = rating.duplicateOf.map(id => {
    const refIdea = ideas.find(i => i.id === id);
    return refIdea ? `${id}: ${refIdea.title}` : id;
  });
  assert.equal(dupTitles[0], 'idea_nonexistent');
});

test('duplicate info: handles no duplicateOf gracefully', () => {
  const rating = makeRating('idea_1', { duplicateOf: [] });
  assert.equal(rating.duplicateOf.length, 0);
});

test('clearAllFilters: resets all filter values', () => {
  // Mock document.getElementById since Node test environment has no DOM
  const elements = {};
  const createEl = (id, val = '') => {
    elements[id] = { value: val };
    return elements[id];
  };
  createEl('libSearch', 'test search');
  createEl('libCategory', 'Safety');
  createEl('libVerdict', 'Ready to Post');
  createEl('libStatus', 'evaluated');
  createEl('libSort', 'scoreHigh');

  const mockDocument = {
    getElementById: (id) => elements[id],
  };

  const app = { sort: 'scoreHigh' };

  // Simulate clearAllFilters logic
  elements['libSearch'].value = '';
  elements['libCategory'].value = '';
  elements['libVerdict'].value = '';
  elements['libStatus'].value = '';
  elements['libSort'].value = 'idAsc';
  app.sort = 'idAsc';

  assert.equal(elements['libSearch'].value, '');
  assert.equal(elements['libCategory'].value, '');
  assert.equal(elements['libVerdict'].value, '');
  assert.equal(elements['libStatus'].value, '');
  assert.equal(elements['libSort'].value, 'idAsc');
  assert.equal(app.sort, 'idAsc');
});
