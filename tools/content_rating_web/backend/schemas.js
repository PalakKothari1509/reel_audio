const DIMENSIONS = [
  { id: 'hookStrength', name: 'Hook Strength', weight: 15 },
  { id: 'relatability', name: 'Relatability', weight: 15 },
  { id: 'storyStructure', name: 'Story Structure', weight: 12 },
  { id: 'ageAppropriateness', name: 'Age Appropriateness', weight: 10 },
  { id: 'hinglishNaturalness', name: 'Hinglish Naturalness', weight: 10 },
  { id: 'characterConsistency', name: 'Character Consistency', weight: 8 },
  { id: 'visualFeasibility', name: 'Visual Feasibility', weight: 8 },
  { id: 'soundOffReadability', name: 'Sound-Off Readability', weight: 7 },
  { id: 'engagementPotential', name: 'Engagement Potential', weight: 8 },
  { id: 'brandAndSafety', name: 'Brand and Safety', weight: 7 },
];

const SEVERITIES = ['critical', 'major', 'minor', 'suggestion'];

function validateDimensionScore(score) {
  return typeof score === 'number' && Number.isInteger(score) && score >= 0 && score <= 10;
}

function validateDimension(dim) {
  if (!dim || typeof dim !== 'object') return false;
  if (!validateDimensionScore(dim.score)) return false;
  if (typeof dim.explanation !== 'string' || dim.explanation.trim().length === 0) return false;
  return true;
}

function validateFinding(f) {
  if (!f || typeof f !== 'object') return false;
  if (typeof f.title !== 'string' || f.title.trim().length === 0) return false;
  if (!SEVERITIES.includes(f.severity)) return false;
  if (typeof f.explanation !== 'string' || f.explanation.trim().length === 0) return false;
  if (typeof f.evidence !== 'string' || f.evidence.trim().length === 0) return false;
  if (typeof f.suggestedFix !== 'string' || f.suggestedFix.trim().length === 0) return false;
  return true;
}

function validateGeminiResponse(body) {
  if (!body || typeof body !== 'object') return { valid: false, error: 'Response is not an object' };

  // ideaId
  if (typeof body.ideaId !== 'string' || body.ideaId.trim().length === 0) {
    return { valid: false, error: 'Missing or invalid ideaId' };
  }

  // dimensionScores — array of 10
  if (!Array.isArray(body.dimensionScores) || body.dimensionScores.length !== DIMENSIONS.length) {
    return { valid: false, error: `dimensionScores must be an array of ${DIMENSIONS.length} items` };
  }
  for (const dim of body.dimensionScores) {
    if (!validateDimension(dim)) {
      return { valid: false, error: 'Invalid dimension score entry' };
    }
  }

  // findings — array
  if (!Array.isArray(body.criticalFindings)) {
    return { valid: false, error: 'Missing criticalFindings array' };
  }
  for (const f of body.criticalFindings) {
    if (!validateFinding(f)) return { valid: false, error: 'Invalid critical finding' };
  }
  if (!Array.isArray(body.majorFindings)) {
    return { valid: false, error: 'Missing majorFindings array' };
  }
  for (const f of body.majorFindings) {
    if (!validateFinding(f)) return { valid: false, error: 'Invalid major finding' };
  }
  if (!Array.isArray(body.minorFindings)) {
    return { valid: false, error: 'Missing minorFindings array' };
  }
  for (const f of body.minorFindings) {
    if (!validateFinding(f)) return { valid: false, error: 'Invalid minor finding' };
  }
  if (!Array.isArray(body.suggestions)) {
    return { valid: false, error: 'Missing suggestions array' };
  }

  // improvedHook, storyImprovements, improvedCaption
  if (typeof body.improvedHook !== 'string') return { valid: false, error: 'Missing improvedHook' };
  if (typeof body.storyImprovements !== 'string') return { valid: false, error: 'Missing storyImprovements' };

  return { valid: true };
}

function computeWeightedScore(dimensionScores) {
  let total = 0;
  for (const dim of DIMENSIONS) {
    const entry = dimensionScores.find(d => d.id === dim.id);
    const score = entry ? entry.score : 0;
    total += (score / 10) * dim.weight;
  }
  return Math.round(total);
}

function computeVerdict(score) {
  if (score >= 80) return 'Ready to Post';
  if (score >= 65) return 'Needs Minor Fixes';
  if (score >= 45) return 'Needs Major Rewrite';
  return 'Reject';
}

module.exports = { DIMENSIONS, SEVERITIES, validateGeminiResponse, computeWeightedScore, computeVerdict };
