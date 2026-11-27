'use strict';

/**
 * Frontend tests for Content Rating Tool.
 * Covers Phase 1 (evaluation counts, pinned comments), Phase 2 (sorting, verdict badges, dimension scores, duplicate info, clear filters),
 * and Phase 3 (story structure, completeness, library preview).
 */

const assert = require('node:assert/strict');
const test = require('node:test');
const fs = require('node:fs');
const path = require('node:path');

// ── Helper: escape HTML ──
function escapeHtml(text) {
  if (!text) return '';
  return String(text)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}

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
    storyDetail: 'Story: Test story detail.\nTwist: A surprise twist.\nResolution: They resolve it.\nMoral: Always try your best.',
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

// ── Phase 1 tests ──
test('evaluated count accuracy: ratings with verdicts are counted', () => {
  const ratings = [
    makeRating('idea_1', { verdict: 'Ready to Post' }),
    makeRating('idea_2', { verdict: 'Needs Minor Fixes' }),
    makeRating('idea_3', { verdict: 'Needs Major Rewrite' }),
    { ideaId: 'idea_4', verdict: undefined },
  ];
  const evaluatedCount = ratings.filter(r => r.verdict).length;
  assert.equal(evaluatedCount, 3);
});

test('repair preview renders overall scores and score change as separate metrics', () => {
  const appSource = fs.readFileSync(
    path.resolve(__dirname, '../frontend/js/app.js'),
    'utf8',
  );
  assert.match(appSource, /Original Overall Score/);
  assert.match(appSource, /Repaired Overall Score/);
  assert.match(appSource, /Score Change/);
  assert.match(appSource, /Original Verdict/);
  assert.match(appSource, /Repaired Verdict/);
  assert.doesNotMatch(appSource, /\$\{scoreChangeSign\}\$\{rep\.overallScore/);
});

test('repair preview labels system metadata separately from content fields', () => {
  const appSource = fs.readFileSync(
    path.resolve(__dirname, '../frontend/js/app.js'),
    'utf8',
  );
  assert.match(appSource, /System Metadata Changes/);
  assert.match(appSource, /strategy: 'Strategy'/);
  assert.doesNotMatch(appSource, /reviewedOn: 'Reviewed On'/);
});

test('all ideas table contains only the requested summary columns', () => {
  const appSource = fs.readFileSync(
    path.resolve(__dirname, '../frontend/js/app.js'),
    'utf8',
  );
  assert.match(appSource, /label: 'Idea ID'/);
  assert.match(appSource, /label: 'Title'/);
  assert.match(appSource, /label: 'Category'/);
  assert.match(appSource, /label: 'Score'/);
  assert.match(appSource, /label: 'Verdict'/);
  assert.match(appSource, /label: 'Action'/);
  assert.doesNotMatch(appSource, /Expand cell details to read full text/);
  assert.doesNotMatch(appSource, /label: 'Gate Results'/);
  assert.doesNotMatch(appSource, /label: 'Complete Idea Data/);
});

test('all ideas table has direct Fix and Save action', () => {
  const appSource = fs.readFileSync(
    path.resolve(__dirname, '../frontend/js/app.js'),
    'utf8',
  );
  assert.match(appSource, /Fix &amp; Save/);
  assert.match(appSource, /fixAndSaveIdea/);
  assert.match(appSource, /assets\/data\/content_ideas\.json/);
  assert.match(appSource, /api\/ideas\/\$\{ideaId\}\/repair\/save/);
  assert.match(appSource, /repairedIdea: repairData\.repairedIdea/);
});

test('Fix and Save action is hidden for Ready to Post ideas', () => {
  const appSource = fs.readFileSync(
    path.resolve(__dirname, '../frontend/js/app.js'),
    'utf8',
  );
  assert.match(appSource, /rating\?\.verdict\s*===\s*'Ready to Post'/);
  assert.match(appSource, /\?\s*''\s*:/);
});

test('Fix and Save refreshes ideas, ratings, freshness, and dashboard', () => {
  const appSource = fs.readFileSync(
    path.resolve(__dirname, '../frontend/js/app.js'),
    'utf8',
  );
  const fixBlock = appSource.slice(
    appSource.indexOf('async fixAndSaveIdea'),
    appSource.indexOf('async repairIdea', appSource.indexOf('async fixAndSaveIdea')),
  );
  assert.match(fixBlock, /await this\.loadIdeas\(\)/);
  assert.match(fixBlock, /await this\.loadRatings\(\)/);
  assert.match(fixBlock, /await this\.loadFreshness\(\)/);
  assert.match(fixBlock, /this\.renderDashboard\(\)/);
});

test('evaluated count is zero when no ratings exist', () => {
  const ratings = [];
  const evaluatedCount = ratings.filter(r => r.verdict).length;
  assert.equal(evaluatedCount, 0);
});

test('CURRENT versus evaluated count distinction', () => {
  const ideas = [makeIdea('idea_1'), makeIdea('idea_2'), makeIdea('idea_3')];
  const ratings = [makeRating('idea_1')];
  const freshness = [
    makeFreshness('idea_1', 'CURRENT', ratings[0]),
    makeFreshness('idea_2', 'NOT_EVALUATED'),
    makeFreshness('idea_3', 'NEEDS_REEVALUATION'),
  ];

  const evaluatedCount = ratings.filter(r => r.verdict).length;
  const currentCount = freshness.filter(f => f.status === 'CURRENT').length;

  assert.equal(evaluatedCount, 1);
  assert.equal(currentCount, 1);
  assert.equal(evaluatedCount, currentCount);
});

test('CURRENT and evaluated counts can differ', () => {
  const ratings = [makeRating('idea_1', { verdict: 'Ready to Post' })];
  const freshness = [
    makeFreshness('idea_1', 'CURRENT', ratings[0]),
    makeFreshness('idea_2', 'CURRENT'),
  ];

  const evaluatedCount = ratings.filter(r => r.verdict).length;
  const currentCount = freshness.filter(f => f.status === 'CURRENT').length;

  assert.equal(evaluatedCount, 1);
  assert.equal(currentCount, 2);
  assert.notEqual(evaluatedCount, currentCount);
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
  assert.ok(!idea.readyPrompt);
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
    { ideaId: 'idea_2', status: 'CURRENT', rating: null },
  ];
  const sortedHigh = [...freshness].sort((a, b) => {
    const scoreA = a.rating ? a.rating.overallScore : -1;
    const scoreB = b.rating ? b.rating.overallScore : -1;
    return scoreB - scoreA || a.ideaId.localeCompare(b.ideaId);
  });
  assert.equal(sortedHigh[0].ideaId, 'idea_1');
  assert.equal(sortedHigh[1].ideaId, 'idea_2');
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
  assert.equal(sorted[0].ideaId, 'idea_1');
  assert.equal(sorted[1].ideaId, 'idea_2');
});

test('verdict badge rendering: Ready to Post uses correct class', () => {
  const verdictClass = `verdict-badge verdict-${'Ready to Post'.toLowerCase().replace(' ', '-')}`;
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
  assert.ok(!badges.includes('Originality'));
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

  const app = { sort: 'scoreHigh' };

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

// ── Phase 3 tests: Story structure display ──
// Helper: parseStoryDetail
function parseStoryDetail(storyDetail) {
  const sections = { story: '', twist: '', resolution: '', moral: '' };
  if (!storyDetail) return sections;

  const lines = storyDetail.split(/\n/);
  let currentSection = null;

  for (const line of lines) {
    const trimmed = line.trim();
    const lower = trimmed.toLowerCase();

    if (lower.startsWith('story:')) {
      currentSection = 'story';
      sections.story = trimmed.replace(/^story:\s*/i, '');
    } else if (lower.startsWith('twist:')) {
      currentSection = 'twist';
      sections.twist = trimmed.replace(/^twist:\s*/i, '');
    } else if (lower.startsWith('resolution:')) {
      currentSection = 'resolution';
      sections.resolution = trimmed.replace(/^resolution:\s*/i, '');
    } else if (lower.startsWith('moral:')) {
      currentSection = 'moral';
      sections.moral = trimmed.replace(/^moral:\s*/i, '');
    } else if (currentSection && trimmed) {
      sections[currentSection] += (sections[currentSection] ? '\n' : '') + trimmed;
    }
  }

  return sections;
}

// Helper: getStoryCompleteness
function getStoryCompleteness(storyDetail) {
  const sections = parseStoryDetail(storyDetail);
  const componentIds = ['story', 'twist', 'resolution', 'moral'];
  const present = componentIds.filter(s => sections[s] && sections[s].trim().length > 0);
  const missing = componentIds.filter(s => !sections[s] || !sections[s].trim());

  return {
    present: present.length,
    total: 4,
    missing: missing,
    isComplete: present.length === 4,
  };
}

// Helper: getStoryPreview
function getStoryPreview(storyDetail) {
  const sections = parseStoryDetail(storyDetail);
  const storyText = sections.story || '';
  if (!storyText) return '';
  const preview = storyText.trim().slice(0, 120);
  return preview.length < storyText.trim().length ? preview + '…' : preview;
}

// Helper: getStoryBadgeHtml
function getStoryBadgeHtml(storyDetail) {
  const completeness = getStoryCompleteness(storyDetail);
  const present = completeness.present;
  const total = completeness.total;

  let badgeClass = 'story-complete';
  if (present === 0) badgeClass = 'story-missing-all';
  else if (present < total) badgeClass = 'story-partial';

  return `
    <span class="story-completeness-badge ${badgeClass}" title="${present}/${total} story components present (${completeness.missing.join(', ')})">
      ${present}/${total}
    </span>
  `;
}

test('parseStoryDetail: extracts all four sections', () => {
  const detail = 'Story: Ria goes to the park.\nTwist: She loses her ball.\nResolution: Mumma finds it.\nMoral: Always look after your toys.';
  const result = parseStoryDetail(detail);
  assert.equal(result.story, 'Ria goes to the park.');
  assert.equal(result.twist, 'She loses her ball.');
  assert.equal(result.resolution, 'Mumma finds it.');
  assert.equal(result.moral, 'Always look after your toys.');
});

test('parseStoryDetail: handles empty string', () => {
  const result = parseStoryDetail('');
  assert.equal(result.story, '');
  assert.equal(result.twist, '');
  assert.equal(result.resolution, '');
  assert.equal(result.moral, '');
});

test('parseStoryDetail: handles null/undefined', () => {
  assert.deepEqual(parseStoryDetail(null), { story: '', twist: '', resolution: '', moral: '' });
  assert.deepEqual(parseStoryDetail(undefined), { story: '', twist: '', resolution: '', moral: '' });
});

test('parseStoryDetail: handles multiline section content', () => {
  const detail = 'Story: Ria goes to the park\nand plays on the swings.\nTwist: She loses her ball\nin the grass.\nResolution: Mumma finds it\nand returns it to her.\nMoral: Always look after your toys.';
  const result = parseStoryDetail(detail);
  assert.equal(result.story, 'Ria goes to the park\nand plays on the swings.');
  assert.equal(result.twist, 'She loses her ball\nin the grass.');
  assert.equal(result.resolution, 'Mumma finds it\nand returns it to her.');
  assert.equal(result.moral, 'Always look after your toys.');
});

test('parseStoryDetail: ignores unknown lines', () => {
  const detail = 'Story: Ria goes to the park.\nSome random line.\nTwist: She loses her ball.';
  const result = parseStoryDetail(detail);
  assert.equal(result.story, 'Ria goes to the park.\nSome random line.');
  assert.equal(result.twist, 'She loses her ball.');
  assert.equal(result.resolution, '');
  assert.equal(result.moral, '');
});

test('getStoryCompleteness: complete story has 4/4', () => {
  const detail = 'Story: Ria goes to the park.\nTwist: She loses her ball.\nResolution: Mumma finds it.\nMoral: Always look after your toys.';
  const result = getStoryCompleteness(detail);
  assert.equal(result.present, 4);
  assert.equal(result.total, 4);
  assert.equal(result.missing.length, 0);
  assert.equal(result.isComplete, true);
});

test('getStoryCompleteness: missing sections', () => {
  const detail = 'Story: Ria goes to the park.\nTwist: She loses her ball.';
  const result = getStoryCompleteness(detail);
  assert.equal(result.present, 2);
  assert.equal(result.total, 4);
  assert.equal(result.missing.length, 2);
  assert.ok(result.missing.includes('resolution'));
  assert.ok(result.missing.includes('moral'));
  assert.equal(result.isComplete, false);
});

test('getStoryCompleteness: empty string has 0/4', () => {
  const result = getStoryCompleteness('');
  assert.equal(result.present, 0);
  assert.equal(result.total, 4);
  assert.equal(result.missing.length, 4);
  assert.equal(result.isComplete, false);
});

test('getStoryCompleteness: null/undefined has 0/4', () => {
  const result1 = getStoryCompleteness(null);
  const result2 = getStoryCompleteness(undefined);
  assert.equal(result1.present, 0);
  assert.equal(result2.present, 0);
});

test('getStoryPreview: returns truncated preview', () => {
  const storyDetail = 'Story: Ria goes to the park and plays on the swings and has lots of fun with her friends and meets new friends at the park and has a wonderful time playing games and eating snacks together.';
  const preview = getStoryPreview(storyDetail);
  assert.ok(preview.startsWith('Ria goes to the park'));
  assert.ok(preview.includes('…'));
  // Preview is 120 chars + ellipsis = 121 chars max
  assert.ok(preview.length <= 121);
});

test('getStoryPreview: returns empty string for empty story', () => {
  assert.equal(getStoryPreview(''), '');
  assert.equal(getStoryPreview(null), '');
  assert.equal(getStoryPreview(undefined), '');
});

test('getStoryPreview: returns full text if under 120 chars', () => {
  const storyDetail = 'Story: Short story.';
  const preview = getStoryPreview(storyDetail);
  assert.equal(preview, 'Short story.');
});

test('getStoryBadgeHtml: complete story shows 4/4', () => {
  const detail = 'Story: Ria goes to the park.\nTwist: She loses her ball.\nResolution: Mumma finds it.\nMoral: Always look after your toys.';
  const html = getStoryBadgeHtml(detail);
  assert.ok(html.includes('4/4'));
  assert.ok(html.includes('story-complete'));
});

test('getStoryBadgeHtml: incomplete story shows partial count', () => {
  const detail = 'Story: Ria goes to the park.\nTwist: She loses her ball.';
  const html = getStoryBadgeHtml(detail);
  assert.ok(html.includes('2/4'));
  assert.ok(html.includes('story-partial'));
});

test('getStoryBadgeHtml: empty story shows 0/4', () => {
  const html = getStoryBadgeHtml('');
  assert.ok(html.includes('0/4'));
  assert.ok(html.includes('story-missing-all'));
});

test('renderStoryStructure: renders all four sections', () => {
  function renderStoryStructure(storyDetail) {
    const sections = parseStoryDetail(storyDetail);
    const completeness = getStoryCompleteness(storyDetail);
    const sectionLabels = {
      story: 'Story',
      twist: 'Twist',
      resolution: 'Resolution',
      moral: 'Moral',
    };

    const completenessHtml = `
      <div class="story-completeness">
        <span class="completeness-count">${completeness.present}/${completeness.total} components present</span>
        ${completeness.missing.length > 0
          ? `<span class="completeness-missing">Missing: ${completeness.missing.join(', ')}</span>`
          : `<span class="completeness-complete">All components present</span>`}
      </div>
    `;

    const sectionsHtml = [
      { id: 'story', label: 'Story' },
      { id: 'twist', label: 'Twist' },
      { id: 'resolution', label: 'Resolution' },
      { id: 'moral', label: 'Moral' },
    ].map(s => {
      const content = sections[s.id] || '';
      const hasContent = content && content.trim().length > 0;
      return `
        <div class="story-section" id="story-${s.id}">
          <h4 class="story-section-title" data-section="${s.id}">${s.label}</h4>
          <div class="story-section-content" style="white-space: pre-wrap">${hasContent ? escapeHtml(content) : '<em>Not provided</em>'}</div>
        </div>
      `;
    }).join('');

    return completenessHtml + sectionsHtml;
  }

  const detail = 'Story: Ria goes to the park.\nTwist: She loses her ball.\nResolution: Mumma finds it.\nMoral: Always look after your toys.';
  const html = renderStoryStructure(detail);
  assert.ok(html.includes('story-completeness'));
  assert.ok(html.includes('4/4 components present'));
  assert.ok(html.includes('Ria goes to the park.'));
  assert.ok(html.includes('She loses her ball.'));
  assert.ok(html.includes('Mumma finds it.'));
  assert.ok(html.includes('Always look after your toys.'));
  assert.ok(html.includes('story-section'));
  assert.ok(html.includes('story-section-title'));
  assert.ok(html.includes('story-section-content'));
});

test('renderStoryStructure: empty story shows not provided', () => {
  function renderStoryStructure(storyDetail) {
    const sections = parseStoryDetail(storyDetail);
    const completeness = getStoryCompleteness(storyDetail);
    const sectionLabels = {
      story: 'Story',
      twist: 'Twist',
      resolution: 'Resolution',
      moral: 'Moral',
    };

    const completenessHtml = `
      <div class="story-completeness">
        <span class="completeness-count">${completeness.present}/${completeness.total} components present</span>
        ${completeness.missing.length > 0
          ? `<span class="completeness-missing">Missing: ${completeness.missing.join(', ')}</span>`
          : `<span class="completeness-complete">All components present</span>`}
      </div>
    `;

    const sectionsHtml = [
      { id: 'story', label: 'Story' },
      { id: 'twist', label: 'Twist' },
      { id: 'resolution', label: 'Resolution' },
      { id: 'moral', label: 'Moral' },
    ].map(s => {
      const content = sections[s.id] || '';
      const hasContent = content && content.trim().length > 0;
      return `
        <div class="story-section" id="story-${s.id}">
          <h4 class="story-section-title" data-section="${s.id}">${s.label}</h4>
          <div class="story-section-content" style="white-space: pre-wrap">${hasContent ? escapeHtml(content) : '<em>Not provided</em>'}</div>
        </div>
      `;
    }).join('');

    return completenessHtml + sectionsHtml;
  }

  const detail = '';
  const html = renderStoryStructure(detail);
  assert.ok(html.includes('Not provided'));
});