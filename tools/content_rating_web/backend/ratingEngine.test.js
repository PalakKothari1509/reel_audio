const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');
const { offlineEvaluate } = require('./ratingEngine');

const ideasPath = path.resolve(__dirname, '../../../assets/data/content_ideas.json');
const ideas = JSON.parse(fs.readFileSync(ideasPath, 'utf8')).ideas;

test('idea_30 is not flagged for the substring "hit" in "white"', () => {
  const idea = ideas.find(item => item.id === 'idea_30');
  assert.ok(idea, 'idea_30 should exist in the content ideas data');

  const result = offlineEvaluate(idea);
  assert.equal(result.criticalFindings.length, 0);
  assert.equal(result.scoreCapped, false);
  assert.match(
    result.dimensionScores.find(score => score.id === 'brandAndSafety').explanation,
    /Unsafe language: none/,
  );
});

test('offline safety check still detects unsafe terms as whole words', () => {
  const result = offlineEvaluate({
    id: 'unsafe-term-test',
    title: 'Rio hit Mumma',
    lesson: 'Use safe behavior.',
  });

  assert.equal(result.criticalFindings.length, 1);
  assert.match(result.criticalFindings[0].explanation, /hit/);
});

test('offline safety check ignores benign and explicitly prohibited mentions', () => {
  for (const text of ['The dance became the hit of the circle.', 'Physical punishment is not allowed.']) {
    const result = offlineEvaluate({
      id: 'benign-safety-language-test',
      title: text,
      lesson: 'Use safe behavior.',
    });
    assert.equal(result.criticalFindings.length, 0, text);
  }
});

test('archived idea 46 is not flagged for the benign phrase "hit of the circle"', () => {
  const idea = ideas.find(item => item.id === 'idea_46');
  assert.ok(idea, 'idea_46 should exist in the content ideas data');
  assert.equal(idea.archived, true);

  const result = offlineEvaluate(idea);
  assert.equal(result.criticalFindings.length, 0);
  assert.equal(result.dimensionScores.find(score => score.id === 'characterConsistency').needsImprovement, '');
});

test('idea_30 gets credit for its complete approved character cast', () => {
  const idea = ideas.find(item => item.id === 'idea_30');
  assert.ok(idea, 'idea_30 should exist in the content ideas data');

  const result = offlineEvaluate(idea);
  const characterScore = result.dimensionScores.find(score => score.id === 'characterConsistency');
  assert.equal(characterScore.score, 9);
  assert.match(characterScore.explanation, /Missing from cast: none/);
  assert.doesNotMatch(characterScore.needsImprovement, /Add character cast to defaultCast/);
});

test('character consistency identifies named characters missing from defaultCast', () => {
  const result = offlineEvaluate({
    id: 'missing-cast-test',
    title: 'Rio and Mumma',
    defaultCast: ['Rio'],
  });

  const characterScore = result.dimensionScores.find(score => score.id === 'characterConsistency');
  assert.equal(characterScore.score, 6);
  assert.match(characterScore.needsImprovement, /Add Mumma to defaultCast/);
});

test('complete ideas do not receive generic unchanged suggestions or boilerplate feedback', () => {
  const idea = ideas.find(item => item.id === 'idea_74');
  assert.ok(idea, 'idea_74 should exist in the content ideas data');

  const result = offlineEvaluate(idea);
  assert.equal(result.suggestions.some(suggestion => suggestion.original === suggestion.suggested), false);
  assert.equal(result.suggestions.length, 0);
  assert.equal(result.criticalFindings.length, 0);
  assert.equal(result.evaluationVersion, '1.2.0-offline');
  assert.equal(
    result.dimensionScores.find(score => score.id === 'storyStructure').needsImprovement,
    '',
  );
  assert.equal(
    result.dimensionScores.find(score => score.id === 'characterConsistency').needsImprovement,
    '',
  );
});

test('series recaps are not penalized for having no child problem', () => {
  const idea = ideas.find(item => item.id === 'idea_116');
  assert.ok(idea, 'idea_116 should exist in the content ideas data');

  const result = offlineEvaluate(idea);
  assert.equal(result.dimensionScores.find(score => score.id === 'relatability').needsImprovement, '');
  assert.equal(result.dimensionScores.find(score => score.id === 'engagementPotential').needsImprovement, '');
});

test('offline age feedback does not infer developmental fit from lesson length', () => {
  const idea = ideas.find(item => item.id === 'idea_14');
  assert.ok(idea, 'idea_14 should exist in the content ideas data');

  const result = offlineEvaluate(idea);
  assert.equal(result.dimensionScores.find(score => score.id === 'ageAppropriateness').needsImprovement, '');
});

test('visual-only ideas do not receive spoken-dialogue recommendations', () => {
  const idea = ideas.find(item => item.id === 'idea_93');
  assert.ok(idea, 'idea_93 should exist in the content ideas data');

  const result = offlineEvaluate(idea);
  assert.equal(result.dimensionScores.find(score => score.id === 'hinglishNaturalness').needsImprovement, '');
  assert.equal(result.dimensionScores.find(score => score.id === 'relatability').needsImprovement, '');
});
