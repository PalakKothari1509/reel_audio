const assert = require('node:assert/strict');
const test = require('node:test');
const { offlineEvaluate } = require('./ratingEngine');
const fs = require('fs');
const path = require('path');

const ideasPath = path.join('C:', 'Flutter', 'reel_audio', 'assets', 'data', 'content_ideas.json');
const ideas = JSON.parse(fs.readFileSync(ideasPath, 'utf8')).ideas;

test('test 1: character consistency gate', () => {
  const result = offlineEvaluate({
    id: 'missing-cast-test',
    title: 'Test title',
    opening: 'Rio and Mumma play together',
    problem: 'Test problem',
    storyDetail: 'Story: Test with twist resolution moral',
    endingBeat: 'Ending',
    caption: 'Caption #tag1 #tag2 #tag3',
    pinnedComment: 'Comment?',
    dialogue: 'chalo haan',
    defaultCast: ['Rio'],
    category: 'Safety',
    setting: 'Home',
    sceneDetail: 'Scene',
    postFormat: 'Reel',
  }, ideas);

  console.log('Test 1 suggestions:', result.suggestions.length);
  result.suggestions.forEach((s, i) => console.log(`  ${i}: ${s.title} | equal=${s.original === s.suggested}`));
  const gate = result.gateResults.find(g => g.id === 'characterConsistency');
  assert.equal(gate.passed, false);
});

test('test 2: complete ideas', () => {
  const idea = ideas.find(item => item.id === 'idea_74');
  const result = offlineEvaluate(idea, ideas);
  
  console.log('Test 2 suggestions:', result.suggestions.length);
  result.suggestions.forEach((s, i) => {
    console.log(`  ${i}: "${s.title}" | original="${s.original}" | suggested="${s.suggested}" | equal=${s.original === s.suggested}`);
  });
  const someEqual = result.suggestions.some(s => s.original === s.suggested);
  console.log('someEqual:', someEqual);
  assert.equal(someEqual, false);
});