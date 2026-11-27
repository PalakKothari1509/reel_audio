'use strict';

const CONTENT_FIELDS = [
  'title', 'category', 'opening', 'problem', 'lesson', 'caption',
  'pinnedComment', 'storyDetail', 'setting', 'sceneDetail', 'dialogue',
  'mess', 'innerThought', 'endingBeat', 'defaultCast', 'readyPrompt',
  'strategy', 'cover', 'postFormat', 'forApp', 'usedOn', 'custom',
  'archived', 'keepMoralOffScreen', 'quote', 'detail', 'punchline',
];

const EVALUATION_METADATA_FIELDS = [
  'score', 'band', 'reviewedOn', 'overallScore', 'rawScore', 'scoreCapped',
  'verdict', 'criticalFindings', 'majorFindings', 'minorFindings',
  'suggestions', 'gateResults', 'dimensionScores', 'confidence',
  'evaluationMode', 'contentHash', 'productionHash', 'hashVersion',
  'evaluationId', 'isNewEval', 'evaluationVersion', 'evaluatedAt',
  'fixesToReach10', 'potentialScore', 'rewrittenHook', 'storyImprovements',
  'improvedCaption', 'improvedPinnedComment', 'pinned_comment_problem',
  'pinned_comment_solution', 'duplicateOf', 'recommendedFormat', 'seasonTag',
  'deterministicChecks', 'solutionValidation', 'repairHistory',
  'diagnosticFindings', 'evaluationSummary',
  'repairTimestamp', 'repairMode', 'fixedIssues', 'unresolvedIssues',
  'changedFields', 'unchangedFields', 'backupPath', 'originalScore',
  'repairedScore', 'originalVerdict', 'repairedVerdict',
];

const LEGACY_STRATEGY_MARKER = 'EVALUATION SUMMARY';
const ORIGINAL_STRATEGY_MARKERS = [
  'ORIGINAL PRODUCTION RECOMMENDATIONS:',
  'RATING-BASED PRODUCTION UPDATE:',
];

function hasEvaluationMetadata(text) {
  if (typeof text !== 'string') return false;
  const lower = text.toLowerCase();
  const markers = [
    'overall score:',
    'dimension scores:',
    'gate results:',
    'critical findings:',
    'major findings:',
    'minor findings:',
    'fixes to reach 100:',
    'deterministic checks:',
  ];
  return lower.includes(LEGACY_STRATEGY_MARKER.toLowerCase())
    || markers.filter(marker => lower.includes(marker)).length >= 3;
}

function extractContentStrategy(strategy) {
  if (typeof strategy !== 'string' || !hasEvaluationMetadata(strategy)) {
    return strategy;
  }

  const summaryIndex = strategy.toLowerCase().indexOf(LEGACY_STRATEGY_MARKER.toLowerCase());
  if (summaryIndex > 0) {
    return strategy.slice(0, summaryIndex).trim();
  }

  for (const marker of ORIGINAL_STRATEGY_MARKERS) {
    const markerIndex = strategy.toLowerCase().lastIndexOf(marker.toLowerCase());
    if (markerIndex !== -1) {
      return strategy.slice(markerIndex + marker.length).trim();
    }
  }

  return '';
}

module.exports = {
  CONTENT_FIELDS,
  EVALUATION_METADATA_FIELDS,
  hasEvaluationMetadata,
  extractContentStrategy,
};
