const fs = require('fs');
const path = require('path');
const { offlineEvaluate } = require('../tools/content_rating_web/backend/ratingEngine');

const IDEAS_PATH = path.resolve(__dirname, '../assets/data/content_ideas.json');
const OUTPUT_PATH = path.resolve(__dirname, 'calibration_report.csv');

function main() {
  console.log('Loading content ideas...');
  const raw = fs.readFileSync(IDEAS_PATH, 'utf8');
  const data = JSON.parse(raw);
  const ideas = data.ideas;
  console.log(`Loaded ${ideas.length} ideas`);

  console.log('Running evaluations...');
  const results = [];
  const scoreDiffs = [];

  for (let i = 0; i < ideas.length; i++) {
    const idea = ideas[i];
    console.log(`[${i + 1}/${ideas.length}] Evaluating ${idea.id}...`);

    const result1 = offlineEvaluate(idea, ideas);
    const result2 = offlineEvaluate(idea, ideas);

    const diff = Math.abs(result1.overallScore - result2.overallScore);
    scoreDiffs.push({ id: idea.id, diff, score1: result1.overallScore, score2: result2.overallScore });

    if (diff > 5) {
      console.log(`  ⚠️  SCORE DIFF > 5: ${diff} points (${result1.overallScore} vs ${result2.overallScore})`);
    }

    results.push({
      id: idea.id,
      title: idea.title,
      rawScore: result1.rawScore,
      overallScore: result1.overallScore,
      verdict: result1.verdict,
      capsApplied: result1.capsApplied.join('; '),
      confidence: result1.confidence,
      gateFailures: result1.gateResults.filter(g => !g.passed).map(g => g.id).join('; '),
      evaluationMode: result1.evaluationMode,
      evaluationVersion: result1.evaluationVersion,
      diff,
      score1: result1.overallScore,
      score2: result2.overallScore,
    });
  }

  console.log('\nWriting calibration report...');
  const headers = [
    'id', 'title', 'rawScore', 'overallScore', 'verdict', 'capsApplied', 'confidence',
    'gateFailures', 'evaluationMode', 'evaluationVersion', 'diff', 'score1', 'score2'
  ];

  const lines = [headers.join(',')];
  for (const r of results) {
    const row = [
      r.id,
      `"${(r.title || '').replace(/"/g, '""')}"`,
      r.rawScore,
      r.overallScore,
      `"${r.verdict}"`,
      `"${r.capsApplied}"`,
      r.confidence,
      `"${r.gateFailures}"`,
      r.evaluationMode,
      r.evaluationVersion,
      r.diff,
      r.score1,
      r.score2,
    ];
    lines.push(row.join(','));
  }

  fs.writeFileSync(OUTPUT_PATH, lines.join('\n'));
  console.log(`Report written to ${OUTPUT_PATH}`);

  console.log('\n=== CALIBRATION SUMMARY ===');
  const verdictCounts = {};
  for (const r of results) {
    verdictCounts[r.verdict] = (verdictCounts[r.verdict] || 0) + 1;
  }
  console.log('Verdict distribution:');
  for (const [verdict, count] of Object.entries(verdictCounts)) {
    console.log(`  ${verdict}: ${count} (${((count / results.length) * 100).toFixed(1)}%)`);
  }

  const avgScore = results.reduce((sum, r) => sum + r.overallScore, 0) / results.length;
  console.log(`\nAverage overall score: ${avgScore.toFixed(1)}`);

  const cappedCount = results.filter(r => r.capsApplied).length;
  console.log(`Scores capped: ${cappedCount} (${((cappedCount / results.length) * 100).toFixed(1)}%)`);

  const gateFailureCount = results.filter(r => r.gateFailures).length;
  console.log(`Gate failures: ${gateFailureCount} (${((gateFailureCount / results.length) * 100).toFixed(1)}%)`);

  const highDiffCount = scoreDiffs.filter(d => d.diff > 5).length;
  console.log(`\nScore differences > 5 points: ${highDiffCount} ideas`);
  if (highDiffCount > 0) {
    console.log('Flagged ideas:');
    for (const d of scoreDiffs.filter(d => d.diff > 5)) {
      console.log(`  ${d.id}: diff=${d.diff} (${d.score1} vs ${d.score2})`);
    }
  }

  const confidenceCounts = {};
  for (const r of results) {
    confidenceCounts[r.confidence] = (confidenceCounts[r.confidence] || 0) + 1;
  }
  console.log('\nConfidence distribution:');
  for (const [conf, count] of Object.entries(confidenceCounts)) {
    console.log(`  ${conf}: ${count}`);
  }

  console.log('\nDone!');
}

main().catch(e => {
  console.error('Fatal error:', e);
  process.exit(1);
});