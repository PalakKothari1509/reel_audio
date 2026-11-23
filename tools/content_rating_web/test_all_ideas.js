const fs = require('fs');
const path = require('path');

const { offlineEvaluate } = require('./backend/ratingEngine');
const { runAllChecks } = require('./backend/deterministicChecks');

// Load all ideas
const CONTENT_JSON_PATH = path.resolve(__dirname, '../../assets/data/content_ideas.json');
const raw = fs.readFileSync(CONTENT_JSON_PATH, 'utf8');
const data = JSON.parse(raw);
const ideas = data.ideas;

console.log(`Total ideas: ${ideas.length}`);

// Evaluate all ideas
const results = [];
let passCount = 0;
let improveCount = 0;
let errorCount = 0;
const issues = [];

for (const idea of ideas) {
  try {
    const result = offlineEvaluate(idea, ideas);
    results.push({ idea, result });

    // Check solution validation
    if (result.solutionValidation && !result.solutionValidation.valid) {
      issues.push({
        ideaId: idea.id,
        type: 'solutionValidation',
        issues: result.solutionValidation.issues,
      });
    }

    // Check hook solution is not generic
    const hookSol = result.rewrittenHook || '';
    if (hookSol && !hookSol.startsWith('PASS')) {
      const genericHook = /^(end on|trim|add a|use only|open on|replace|write|avoid|do not|never|keep the|make sure|ensure|consider|try to|think about|focus on|remember to|don't|please|let's|we should|you should)/i.test(hookSol.trim());
      if (genericHook) {
        issues.push({
          ideaId: idea.id,
          type: 'genericHook',
          hook: hookSol.slice(0, 100),
        });
      }
      if (hookSol.length > 200) {
        issues.push({
          ideaId: idea.id,
          type: 'hookTooLong',
          length: hookSol.length,
        });
      }
    }

    // Check story solution is not just advice
    const storySol = result.storyImprovements || '';
    if (storySol && !storySol.startsWith('PASS')) {
      const adviceOnly = /^(parents should|parents must|never|always|avoid|don't|should|encourage|praise|validate|acknowledge|listen|understand|respect|support|help|guide|teach|allow|give|offer|provide|set|create|establish|maintain|ensure|make sure|remember to|try to|think about|focus on|consider|believe|trust|love|care for|spend time with|be patient|be kind|be gentle|be firm|be clear|be consistent|be positive|be proactive|be involved|be present|be available|be attentive|be responsive|be supportive|be understanding|be empathetic|be compassionate|be nurturing|be encouraging|be affirming|be validating|be respectful|be honoring|be celebrating|be appreciative|be grateful|be thankful|be mindful|be aware|be conscious|be intentional|be deliberate|be purposeful|be meaningful|be significant|be impactful|be powerful|be strong|be brave|be confident|be secure|be safe|be healthy|be happy|be joyful|be peaceful|be calm|be relaxed|be comfortable|be content|be satisfied|be fulfilled|be enriched|be empowered|be inspired|be motivated|be energized|be refreshed|be renewed|be restored|be healed|be whole|be complete|be perfect|be excellent|be outstanding|be exceptional|be extraordinary|be amazing|be wonderful|be fantastic|be superb|be terrific|be marvelous|be magnificent|be splendid|be brilliant|be spectacular|be stunning|be breathtaking|be awe-inspiring|be mind-blowing|be life-changing|be transformative|be revolutionary|be groundbreaking|be innovative|be creative|be imaginative|be original|be unique|be special|be precious|be valuable|be worthwhile|be important|be essential|be necessary|be vital|be crucial|be critical|be key|be central|be fundamental|be primary|be principal|be main|be major|be significant|be notable|be remarkable|be memorable|be unforgettable|be legendary|be iconic|be classic|be timeless|be eternal|be forever|be always|be never|be sometimes|be often|be usually|be rarely|be seldom|be occasionally|be frequently|be constantly|be continuously|be perpetually|be endlessly|be infinitely|be boundlessly|be limitlessly|be measurelessly|be immeasurably|be incomprehensibly|be indescribably|be inexplicably|be unexplainably|be unaccountably)/i.test(storySol.trim());
      if (adviceOnly) {
        issues.push({
          ideaId: idea.id,
          type: 'storyIsAdvice',
          story: storySol.slice(0, 100),
        });
      }
      if (!/story|twist|resolution|moral|setting|dialogue|character|scene/i.test(storySol)) {
        issues.push({
          ideaId: idea.id,
          type: 'storyNoNarrative',
          story: storySol.slice(0, 100),
        });
      }
    }

    // Check caption solution
    const capSol = result.improvedCaption || '';
    if (capSol && !capSol.startsWith('PASS')) {
      if (!/#\w/.test(capSol)) {
        issues.push({
          ideaId: idea.id,
          type: 'captionNoHashtags',
          caption: capSol.slice(0, 100),
        });
      }
      if (capSol.length > 300) {
        issues.push({
          ideaId: idea.id,
          type: 'captionTooLong',
          length: capSol.length,
        });
      }
    }

    // Check pinned comment solution
    const pinnedSol = result.improvedPinnedComment || '';
    if (pinnedSol && !pinnedSol.startsWith('PASS')) {
      if (!/\?/.test(pinnedSol)) {
        issues.push({
          ideaId: idea.id,
          type: 'pinnedNoQuestion',
          pinned: pinnedSol.slice(0, 100),
        });
      }
      if (pinnedSol === capSol) {
        issues.push({
          ideaId: idea.id,
          type: 'pinnedDuplicatesCaption',
        });
      }
    }

    // Count PASS vs IMPROVE
    const hookPass = hookSol.startsWith('PASS');
    const storyPass = storySol.startsWith('PASS');
    const captionPass = capSol.startsWith('PASS');
    const pinnedPass = pinnedSol.startsWith('PASS');
    if (hookPass && storyPass && captionPass && pinnedPass) passCount++;
    else improveCount++;

  } catch (e) {
    errorCount++;
    issues.push({
      ideaId: idea.id,
      type: 'error',
      error: e.message,
    });
    console.error(`Error evaluating ${idea.id}:`, e.message);
  }
}

console.log(`\n=== RESULTS ===`);
console.log(`Evaluated: ${results.length}`);
console.log(`Errors: ${errorCount}`);
console.log(`All PASS: ${passCount}`);
console.log(`Needs IMPROVE: ${improveCount}`);

console.log(`\n=== ISSUES (${issues.length}) ===`);
const issueTypes = {};
for (const issue of issues) {
  issueTypes[issue.type] = (issueTypes[issue.type] || 0) + 1;
}
for (const [type, count] of Object.entries(issueTypes)) {
  console.log(`  ${type}: ${count}`);
}

if (issues.length > 0) {
  console.log(`\n=== DETAILS ===`);
  for (const issue of issues.slice(0, 30)) {
    console.log(`  ${issue.ideaId}: ${issue.type} - ${JSON.stringify(issue).slice(0, 200)}`);
  }
}

// Check required fields in result contract
console.log(`\n=== RESULT CONTRACT VALIDATION ===`);
const requiredFields = [
  'ideaId', 'dimensionScores', 'gateResults', 'overallScore', 'rawScore',
  'scoreCapped', 'capsApplied', 'verdict', 'criticalFindings', 'majorFindings',
  'minorFindings', 'suggestions', 'fixesToReach10', 'potentialScore',
  'rewrittenHook', 'storyImprovements', 'improvedCaption', 'improvedPinnedComment',
  'pinned_comment_problem', 'pinned_comment_solution', 'duplicateOf',
  'recommendedFormat', 'seasonTag', 'deterministicChecks', 'confidence',
  'evaluationMode', 'evaluatedAt', 'evaluationVersion', 'solutionValidation',
];
let missingFields = 0;
for (const result of results) {
  for (const field of requiredFields) {
    if (result.result[field] === undefined) {
      missingFields++;
      if (missingFields <= 10) {
        console.log(`  MISSING: ${result.ideaId}.${field}`);
      }
    }
  }
}
console.log(`Missing fields: ${missingFields}`);

// Check dimension scores
console.log(`\n=== DIMENSION SCORES ===`);
const dimIds = ['hookStrength', 'relatabilityAudienceFit', 'payoffRetention', 'hinglishNaturalness', 'visualFeasibility', 'soundOffReadability', 'shareSaveTrigger', 'captionCommentPackage', 'originality', 'audioHook'];
for (const dimId of dimIds) {
  const scores = results.map(r => r.result.dimensionScores.find(d => d.id === dimId)?.score);
  const avg = scores.reduce((a, b) => a + b, 0) / scores.length;
  const min = Math.min(...scores);
  const max = Math.max(...scores);
  console.log(`  ${dimId}: avg=${avg.toFixed(1)}, min=${min}, max=${max}`);
}

// Check verdict distribution
console.log(`\n=== VERDICT DISTRIBUTION ===`);
const verdicts = {};
for (const result of results) {
  verdicts[result.result.verdict] = (verdicts[result.result.verdict] || 0) + 1;
}
for (const [v, c] of Object.entries(verdicts)) {
  console.log(`  ${v}: ${c}`);
}

// Check CSV export consistency (simulate)
console.log(`\n=== CSV EXPORT FIELDS ===`);
const csvHeaders = ['idea_id', 'hook_problem', 'hook_solution', 'story_problem', 'story_solution', 'caption_problem', 'caption_solution', 'pinned_comment_problem', 'pinned_comment_solution'];
console.log(`  Headers: ${csvHeaders.join(', ')}`);
console.log(`  Column count: ${csvHeaders.length}`);

console.log(`\n=== TEST COMPLETE ===`);
