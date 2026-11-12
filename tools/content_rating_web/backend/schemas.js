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
    description: d.description,
    anchors: d.anchors,
  }));

  const weightTotal = dimensions.reduce((sum, d) => sum + d.weight, 0);
  const weightsMustSumTo = spec.scoring?.weightsMustSumTo ?? 100;
  if (weightTotal !== weightsMustSumTo) {
    throw new Error(`Invalid shared evaluation spec at ${specPath}: dimension weights must total ${weightsMustSumTo}, got ${weightTotal}`);
  }

  for (const dim of dimensions) {
    if (!dim.anchors || typeof dim.anchors !== 'object') {
      throw new Error(`Invalid shared evaluation spec at ${specPath}: dimension ${dim.id} missing anchors`);
    }
    for (const key of ['10', '6', '2']) {
      if (!dim.anchors[key] || typeof dim.anchors[key] !== 'string') {
        throw new Error(`Invalid shared evaluation spec at ${specPath}: dimension ${dim.id} missing anchor ${key}`);
      }
    }
  }

  if (!Array.isArray(spec.gates) || spec.gates.length === 0) {
    throw new Error(`Invalid shared evaluation spec at ${specPath}: missing spec.gates`);
  }

  const gates = spec.gates.map(g => ({
    id: g.id,
    name: g.name,
    description: g.description,
    severityOnFail: g.severityOnFail,
  }));

  const gateIds = new Set(gates.map(g => g.id));
  for (const gate of gates) {
    if (!['critical', 'major', 'minor', 'suggestion'].includes(gate.severityOnFail)) {
      throw new Error(`Invalid shared evaluation spec at ${specPath}: gate ${gate.id} has invalid severityOnFail: ${gate.severityOnFail}`);
    }
  }

  if (!Array.isArray(spec.verdicts) || spec.verdicts.length === 0) {
    throw new Error(`Invalid shared evaluation spec at ${specPath}: missing spec.verdicts`);
  }

  const verdicts = spec.verdicts.map(v => ({
    id: v.id,
    label: v.label,
    minScore: v.minScore,
    maxScore: v.maxScore,
    description: v.description,
    requires: v.requires || {},
  }));

  verdicts.sort((a, b) => b.minScore - a.minScore);

  let prevMax = 100;
  for (const v of verdicts) {
    if (v.maxScore !== prevMax) {
      throw new Error(`Invalid shared evaluation spec at ${specPath}: verdict ${v.id} maxScore ${v.maxScore} does not connect to previous minScore ${prevMax}`);
    }
    prevMax = v.minScore;
  }
  if (prevMax !== 0) {
    throw new Error(`Invalid shared evaluation spec at ${specPath}: verdict ranges do not cover 0-100 (gap at ${prevMax})`);
  }

  for (let i = 0; i < verdicts.length; i++) {
    for (let j = i + 1; j < verdicts.length; j++) {
      const a = verdicts[i];
      const b = verdicts[j];
      if (a.minScore <= b.maxScore && b.minScore <= a.maxScore) {
        throw new Error(`Invalid shared evaluation spec at ${specPath}: verdict ranges overlap: ${a.id} (${a.minScore}-${a.maxScore}) and ${b.id} (${b.minScore}-${b.maxScore})`);
      }
    }
  }

  const dimensionIds = new Set(dimensions.map(d => d.id));

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
    const capVerdict = verdicts.find(v => v.label === criticalCap.cappedVerdict);
    if (!capVerdict) {
      throw new Error(`Invalid shared evaluation spec at ${specPath}: criticalCap.cappedVerdict "${criticalCap.cappedVerdict}" not found in verdicts`);
    }
  }

  const additionalCaps = spec.additionalCaps || [];
  for (const cap of additionalCaps) {
    if (cap.enabled === true) {
      if (typeof cap.cappedScore !== 'number') {
        throw new Error(`Invalid shared evaluation spec at ${specPath}: additionalCap ${cap.id} cappedScore must be a number when enabled`);
      }
      if (typeof cap.cappedVerdict !== 'string') {
        throw new Error(`Invalid shared evaluation spec at ${specPath}: additionalCap ${cap.id} cappedVerdict must be a string when enabled`);
      }
      const capVerdict = verdicts.find(v => v.label === cap.cappedVerdict);
      if (!capVerdict) {
        throw new Error(`Invalid shared evaluation spec at ${specPath}: additionalCap ${cap.id} cappedVerdict "${cap.cappedVerdict}" not found in verdicts`);
      }
      if (cap.condition?.includes('gate') && cap.condition?.includes('critical')) {
        // condition references gate failure - validated at runtime
      }
    }
  }

  if (spec.deterministicChecks?.checks) {
    for (const check of spec.deterministicChecks.checks) {
      if (check.gate && !gateIds.has(check.gate)) {
        throw new Error(`Invalid shared evaluation spec at ${specPath}: deterministic check ${check.id} references unknown gate ${check.gate}`);
      }
      if (check.dimensionId && !dimensionIds.has(check.dimensionId)) {
        throw new Error(`Invalid shared evaluation spec at ${specPath}: deterministic check ${check.id} references unknown dimension ${check.dimensionId}`);
      }
    }
  }

  return {
    specPath,
    spec,
    dimensions,
    gates,
    gateIds,
    severities: spec.severities.map(s => s.id),
    verdicts,
    criticalCap,
    additionalCaps,
    deterministicChecks: spec.deterministicChecks || { checks: [] },
    calibration: spec.calibration || {},
    performanceFeedback: spec.performanceFeedback || {},
    audience: spec.audience || {},
    scoring: spec.scoring || {},
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

const {
  spec,
  dimensions,
  gates,
  gateIds,
  severities,
  verdicts,
  criticalCap,
  additionalCaps,
  deterministicChecks,
  calibration,
  performanceFeedback,
  audience,
  scoring,
} = loaded;

const DIMENSIONS = dimensions;
const GATES = gates;
const GATE_IDS = gateIds;
const SEVERITIES = severities;
const VERDICTS = verdicts;
const CRITICAL_CAP = criticalCap;
const ADDITIONAL_CAPS = additionalCaps;
const DETERMINISTIC_CHECKS = deterministicChecks;
const CALIBRATION = calibration;
const PERFORMANCE_FEEDBACK = performanceFeedback;
const AUDIENCE = audience;
const SCORING = scoring;

function validateDimensionScore(score) {
  return typeof score === 'number' && Number.isInteger(score) && score >= 0 && score <= 10;
}

function validateDimension(dim) {
  if (!dim || typeof dim !== 'object') return false;
  if (!validateDimensionScore(dim.score)) return false;
  if (typeof dim.explanation !== 'string' || dim.explanation.trim().length === 0) return false;
  if (dim.anchorMatched && !['10', '6', '2'].includes(dim.anchorMatched)) return false;
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

function validateGateResult(g) {
  if (!g || typeof g !== 'object') return false;
  if (typeof g.id !== 'string' || g.id.trim().length === 0) return false;
  if (typeof g.name !== 'string' || g.name.trim().length === 0) return false;
  if (typeof g.passed !== 'boolean') return false;
  if (typeof g.severityOnFail !== 'string') return false;
  if (typeof g.detail !== 'string') return false;
  return true;
}

function validateFixToReach10(f) {
  if (!f || typeof f !== 'object') return false;
  if (typeof f.fix !== 'string' || f.fix.trim().length === 0) return false;
  if (typeof f.dimensionId !== 'string' || f.dimensionId.trim().length === 0) return false;
  if (typeof f.estimatedGain !== 'number') return false;
  return true;
}

function validateDeterministicCheckResult(c) {
  if (!c || typeof c !== 'object') return false;
  if (typeof c.id !== 'string' || c.id.trim().length === 0) return false;
  if (typeof c.passed !== 'boolean') return false;
  if (typeof c.severity !== 'string' || !SEVERITIES.includes(c.severity)) return false;
  if (typeof c.gate !== 'string' || c.gate.trim().length === 0) return false;
  if (typeof c.detail !== 'string') return false;
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

  if (typeof body.fixesToReach10 !== 'undefined' && Array.isArray(body.fixesToReach10)) {
    for (const f of body.fixesToReach10) {
      if (!validateFixToReach10(f)) return { valid: false, error: 'Invalid fixesToReach10 entry' };
    }
  }

  if (typeof body.rewrittenHook !== 'string') return { valid: false, error: 'Missing rewrittenHook' };
  if (typeof body.duplicateOf !== 'undefined' && !Array.isArray(body.duplicateOf)) return { valid: false, error: 'duplicateOf must be array' };
  if (typeof body.recommendedFormat !== 'string') return { valid: false, error: 'Missing recommendedFormat' };
  if (typeof body.seasonTag !== 'undefined' && typeof body.seasonTag !== 'string') return { valid: false, error: 'seasonTag must be string' };
  if (typeof body.confidence !== 'string' || !['high', 'medium', 'low'].includes(body.confidence)) return { valid: false, error: 'confidence must be high/medium/low' };

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

function getGateById(id) {
  return GATES.find(g => g.id === id) || null;
}

function getVerdictByLabel(label) {
  return VERDICTS.find(v => v.label === label) || null;
}

function getVerdictRequires(verdictLabel) {
  const v = getVerdictByLabel(verdictLabel);
  return v?.requires || {};
}

module.exports = {
  DIMENSIONS,
  GATES,
  GATE_IDS,
  SEVERITIES,
  VERDICTS,
  CRITICAL_CAP,
  ADDITIONAL_CAPS,
  DETERMINISTIC_CHECKS,
  CALIBRATION,
  PERFORMANCE_FEEDBACK,
  AUDIENCE,
  SCORING,
  validateDimensionScore,
  validateDimension,
  validateFinding,
  validateGateResult,
  validateFixToReach10,
  validateDeterministicCheckResult,
  validateGeminiResponse,
  computeWeightedScore,
  computeVerdict,
  isCriticalCapEnabled,
  getCriticalCapThreshold,
  getCriticalCapScore,
  getCriticalCapVerdict,
  getDimensionCount,
  getDimensionById,
  getGateById,
  getVerdictByLabel,
  getVerdictRequires,
  loadSpec,
  SPEC_PATH,
  DEPLOY_PATH,
};