const fs = require('fs');
const path = require('path');
const { offlineEvaluate } = require('./backend/ratingEngine');

const CONTENT_JSON_PATH = path.resolve(__dirname, '../../assets/data/content_ideas.json');
const raw = fs.readFileSync(CONTENT_JSON_PATH, 'utf8');
const data = JSON.parse(raw);
const ideas = data.ideas;

// Select 15 representative ideas across categories
const repIds = [
  'idea_1',   // Child safety - body autonomy (hug consent)
  'idea_2',   // Child safety - stranger danger (chocolate)
  'idea_3',   // Road safety - ball chasing
  'idea_5',   // Lost child in crowd
  'idea_6',   // Kitchen safety
  'idea_7',   // Independence - shoes
  'idea_8',   // Screen time transition
  'idea_9',   // Persistence - block tower
  'idea_10',  // Tidying up
  'idea_13',  // Food - broccoli refusal
  'idea_14',  // Sibling transitions
  'idea_15',  // Humor - toddler truths
  'idea_26',  // Transition - blocks to shoes
  'idea_45',  // Diwali outfit comfort
  'idea_54',  // Costume/last minute prep
];

console.log('='.repeat(80));
console.log('BEFORE/AFTER COMPARISON - 15 Representative Ideas');
console.log('='.repeat(80));

for (const id of repIds) {
  const idea = ideas.find(i => i.id === id);
  if (!idea) continue;
  
  const result = offlineEvaluate(idea, ideas);
  
  console.log(`\n${'#'.repeat(70)}`);
  console.log(`ID: ${idea.id} | Category: ${idea.category} | Title: ${idea.title}`);
  console.log(`Verdict: ${result.verdict} | Score: ${result.overallScore}/100`);
  console.log(`${'#'.repeat(70)}`);
  
  console.log(`\nORIGINAL OPENING: ${idea.opening}`);
  console.log(`HOOK SOLUTION: ${result.rewrittenHook}`);
  console.log(`Hook PASS: ${result.rewrittenHook.startsWith('PASS')}`);
  
  console.log(`\nORIGINAL PROBLEM: ${idea.problem}`);
  console.log(`STORY SOLUTION: ${result.storyImprovements}`);
  console.log(`Story PASS: ${result.storyImprovements.startsWith('PASS')}`);
  
  console.log(`\nORIGINAL CAPTION: ${idea.caption}`);
  console.log(`CAPTION SOLUTION: ${result.improvedCaption}`);
  console.log(`Caption PASS: ${result.improvedCaption.startsWith('PASS')}`);
  
  console.log(`\nORIGINAL PINNED: ${idea.pinnedComment}`);
  console.log(`PINNED PROBLEM: ${result.pinned_comment_problem}`);
  console.log(`PINNED SOLUTION: ${result.improvedPinnedComment}`);
  console.log(`Pinned PASS: ${result.improvedPinnedComment.startsWith('PASS')}`);
  
  // Show dimension scores for key dimensions
  const hookDim = result.dimensionScores.find(d => d.id === 'hookStrength');
  const captionDim = result.dimensionScores.find(d => d.id === 'captionCommentPackage');
  console.log(`\nDimension Scores: Hook=${hookDim.score}/10, Caption=${captionDim.score}/10`);
  
  // Show key findings
  const keyFindings = [...result.criticalFindings, ...result.majorFindings, ...result.minorFindings]
    .filter(f => f.title.toLowerCase().includes('hook') || f.title.toLowerCase().includes('caption') || f.title.toLowerCase().includes('pinned') || f.title.toLowerCase().includes('story'));
  if (keyFindings.length > 0) {
    console.log(`\nKey Findings:`);
    keyFindings.forEach(f => console.log(`  - ${f.title}: ${f.explanation}`));
  }
  
  console.log();
}

console.log('='.repeat(80));
console.log('REVIEW COMPLETE');
console.log('='.repeat(80));
