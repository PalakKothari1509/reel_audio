const fs = require('fs');
const path = require('path');

const SPEC_PATH = path.resolve(__dirname, '../../../shared/evaluation/evaluation_rules.json');
const DEPLOY_PATH = path.resolve(__dirname, 'evaluation_rules.json');

function loadSpec(specPath) {
  let raw;
  try {
    raw = fs.readFileSync(specPath, 'utf8');
  } catch (e) {
    throw new Error(`Failed to load shared evaluation spec from ${specPath}: ${e.message}`);
  }

  let spec;
  try {
    spec = JSON.parse(raw);
  } catch (e) {
    throw new Error(`Invalid JSON in shared evaluation spec at ${specPath}: ${e.message}`);
  }

  if (!spec || typeof spec !== 'object' || Array.isArray(spec)) {
    throw new Error(`Invalid shared evaluation spec at ${specPath}: top-level value is not an object`);
  }

  if (!Array.isArray(spec.dimensions)) {
    throw new Error(`Invalid shared evaluation spec at ${specPath}: missing spec.dimensions`);
  }

  const dimensions = spec.dimensions.map(d => ({
    id: d.id,
    name: d.name,
    weight: d.weight,
    minScore: d.minScore,
    maxScore: d.maxScore,
  }));

  const weightTotal = dimensions.reduce((sum, d) => sum + d.weight, 0);
  if (weightTotal !== 100) {
    throw new Error(`Invalid shared evaluation spec at ${specPath}: dimension weights must total 100, got ${weightTotal}`);
  }

  if (!Array.isArray(spec.verdicts) || spec.verdicts.length === 0) {
    throw new Error(`Invalid shared evaluation spec at ${specPath}: missing spec.verdicts`);
  }

  const criticalCap = spec.criticalCap || { enabled: false };
  if (criticalCap.enabled === true) {
    if (typeof criticalCap.capThreshold !== 'number') {
      throw new Error(`Invalid shared evaluation spec at ${specPath}: criticalCap.capThreshold must be a number when criticalCap.enabled is true`);
    }
    if (typeof criticalCap.cappedScore !== 'number') {
      throw new Error(`Invalid shared evaluation spec at ${specPath}: criticalCap.cappedScore must be a number when criticalCap.enabled is true`);
    }
    if (typeof criticalCap.cappedVerdict !== 'string') {
      throw new Error(`Invalid shared evaluation spec at ${specPath}: criticalCap.cappedVerdict must be a string when criticalCap.enabled is true`);
    }
  }

  return {
    specPath,
    dimensions,
    severities: spec.severities.map(s => s.id),
    verdicts: spec.verdicts.map(v => ({
      id: v.id,
      label: v.label,
      minScore: v.minScore,
      maxScore: v.maxScore,
    })),
    criticalCap,
  };
}

let loaded;
try {
  loaded = loadSpec(SPEC_PATH);
} catch (e) {
  try {
    loaded = loadSpec(DEPLOY_PATH);
  } catch (e2) {
    throw new Error(`Failed to load shared evaluation spec. Tried ${SPEC_PATH} and ${DEPLOY_PATH}: ${e2.message}`);
  }
}

const { dimensions, severities, verdicts, criticalCap } = loaded;

const DIMENSIONS = dimensions;
const SEVERITIES = severities;
const VERDICTS = verdicts;
const CRITICAL_CAP = criticalCap;

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

  if (typeof body.ideaId !== 'string' || body.ideaId.trim().length === 0) {
    return { valid: false, error: 'Missing or invalid ideaId' };
  }

  if (!Array.isArray(body.dimensionScores) || body.dimensionScores.length !== DIMENSIONS.length) {
    return { valid: false, error: `dimensionScores must be an array of ${DIMENSIONS.length} items` };
  }
  for (const dim of body.dimensionScores) {
    if (!validateDimension(dim)) {
      return { valid: false, error: 'Invalid dimension score entry' };
    }
  }

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
  for (const v of VERDICTS) {
    if (score >= v.minScore) {
      return v.label;
    }
  }
  return VERDICTS[VERDICTS.length - 1].label;
}

function isCriticalCapEnabled() {
  return CRITICAL_CAP.enabled === true;
}

function getCriticalCapThreshold() {
  return CRITICAL_CAP.capThreshold;
}

function getCriticalCapScore() {
  return CRITICAL_CAP.cappedScore;
}

function getCriticalCapVerdict() {
  return CRITICAL_CAP.cappedVerdict;
}

function getDimensionCount() {
  return DIMENSIONS.length;
}

function getDimensionById(id) {
  return DIMENSIONS.find(d => d.id === id) || null;
}

module.exports = {
  DIMENSIONS,
  SEVERITIES,
  VERDICTS,
  CRITICAL_CAP,
  validateDimensionScore,
  validateDimension,
  validateFinding,
  validateGeminiResponse,
  computeWeightedScore,
  computeVerdict,
  isCriticalCapEnabled,
  getCriticalCapThreshold,
  getCriticalCapScore,
  getCriticalCapVerdict,
  getDimensionCount,
  getDimensionById,
  loadSpec,
  SPEC_PATH,
  DEPLOY_PATH,
};
