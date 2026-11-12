'use strict';

const path = require('path');
const fs = require('fs');
require('dotenv').config({ path: path.resolve(__dirname, '.env') });
const express = require('express');
const cors = require('cors');

const { offlineEvaluate, onlineEvaluate, buildOnlineResult } = require('./backend/ratingEngine');
const { validateGeminiResponse } = require('./backend/schemas');
const { listRatings, getRating, saveRating, deleteRating, clearRatings, RATINGS_DIR, ensureDirs } = require('./backend/storage');
const { computeHashes, getCreativeHashFields, getProductionHashFields } = require('./backend/hash');
const {
  openDb, closeDb, upsertContentItem, insertEvaluation, getLatestEvaluation,
  getEvaluationById, getEvaluationHistory, upsertApproval, getCurrentApproval,
  insertEvent, getEventsSince, generateId, dbAll, dbGet, getContentItem,
} = require('./backend/db');

ensureDirs();

const app = express();
const PORT = process.env.PORT || 3001;
const GEMINI_API_KEY = process.env.GEMINI_API_KEY || '';
const NODE_ENV = process.env.NODE_ENV || 'development';
const API_BASE_PATH = process.env.API_BASE_PATH || '/api';

function authenticate(req, res, next) {
  const requiredToken = process.env.API_ACCESS_TOKEN || '';
  const isDev = NODE_ENV !== 'production';

  if (isDev && !requiredToken) {
    req.auth = { user: 'dev', workspaceId: 'default', authenticated: true, devMode: true };
    return next();
  }

  const authHeader = req.headers.authorization || '';
  const match = authHeader.match(/^Bearer\s+(.+)$/);
  const token = match ? match[1] : '';

  if (!token) {
    return res.status(401).json({ error: 'Authentication required' });
  }

  if (token === requiredToken) {
    req.auth = {
      user: 'authenticated',
      workspaceId: req.headers['x-workspace-id'] || 'default',
      authenticated: true,
      devMode: false,
    };
    return next();
  }

  return res.status(403).json({ error: 'Invalid token' });
}

function requireRole() {
  return (req, res, next) => {
    if (!req.auth || !req.auth.authenticated) {
      return res.status(401).json({ error: 'Authentication required' });
    }
    next();
  };
}

function asyncHandler(fn) {
  return (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
}

let dbReady = false;
try {
  openDb();
  dbReady = true;
  console.log('SQLite database initialized.');
} catch (e) {
  console.error('Failed to initialize database:', e.message);
}

const CONTENT_JSON_PATH = path.resolve(__dirname, '../../assets/data/content_ideas.json');

app.get('/', (_req, res) => {
  res.sendFile(path.join(__dirname, 'frontend/index.html'));
});

app.use(express.static(path.join(__dirname, 'frontend')));

app.use(cors());
app.use(express.json({ limit: '2mb' }));

app.get('/api/ideas', (_req, res) => {
  let raw;
  try {
    raw = fs.readFileSync(CONTENT_JSON_PATH, 'utf8');
  } catch (e) {
    return res.status(500).json({ error: 'Cannot read content_ideas.json' });
  }
  try {
    const data = JSON.parse(raw);
    res.json(data);
  } catch (e) {
    res.status(500).json({ error: 'Invalid JSON in content_ideas.json' });
  }
});

app.get('/api/ideas/:id', (req, res) => {
  const raw = fs.readFileSync(CONTENT_JSON_PATH, 'utf8');
  const data = JSON.parse(raw);
  const idea = data.ideas.find(i => i.id === req.params.id);
  if (!idea) return res.status(404).json({ error: 'Idea not found' });
  res.json(idea);
});

app.get('/api/ratings', (_req, res) => {
  const ratings = listRatings();
  res.json(ratings);
});

app.get('/api/ratings/:id', (req, res) => {
  const rating = getRating(req.params.id);
  if (!rating) return res.status(404).json({ error: 'Rating not found' });
  res.json(rating);
});

app.post('/api/evaluate/:id', async (req, res) => {
  const { mode = 'offline' } = req.body || {};
  const raw = fs.readFileSync(CONTENT_JSON_PATH, 'utf8');
  const data = JSON.parse(raw);
  const idea = data.ideas.find(i => i.id === req.params.id);
  if (!idea) return res.status(404).json({ error: 'Idea not found' });

  let result;
  if (mode === 'online') {
    if (!GEMINI_API_KEY || GEMINI_API_KEY === 'your_gemini_api_key_here') {
      return res.status(400).json({ error: 'Gemini API key not configured' });
    }
    try {
      const geminiResponse = await onlineEvaluate(idea, GEMINI_API_KEY, data.ideas);
      const validation = validateGeminiResponse(geminiResponse);
      if (!validation.valid) {
        return res.status(422).json({ error: validation.error, raw: geminiResponse });
      }
      result = buildOnlineResult(idea, geminiResponse, data.ideas);
    } catch (e) {
      return res.status(502).json({ error: `Gemini evaluation failed: ${e.message}` });
    }
  } else {
    result = offlineEvaluate(idea, data.ideas);
  }

  const saved = saveRating(result);
  res.json(saved);
});

app.post(`${API_BASE_PATH}/evaluate`, authenticate, requireRole(), asyncHandler(async (req, res) => {
  if (!dbReady) {
    return res.status(503).json({ error: 'Database not ready' });
  }

  const { workspaceId, source, ideaId, content, evaluationMode = 'offline', forceReevaluate = false } = req.body || {};

  if (!workspaceId || typeof workspaceId !== 'string') {
    return res.status(400).json({ error: 'workspaceId is required' });
  }
  if (!source || !['built_in', 'flutter_edited', 'flutter_custom', 'browser_created'].includes(source)) {
    return res.status(400).json({ error: 'source must be one of: built_in, flutter_edited, flutter_custom, browser_created' });
  }
  if (!ideaId || typeof ideaId !== 'string') {
    return res.status(400).json({ error: 'ideaId is required' });
  }
  if (!content || typeof content !== 'object') {
    return res.status(400).json({ error: 'content payload is required' });
  }

  const { contentHash, productionHash, hashVersion } = computeHashes(content);

  const existingItem = upsertContentItem({
    workspaceId,
    source,
    ideaId,
    contentHash,
    hashVersion,
    productionHash,
  });

  const existingEvalRow = dbGet(
    `SELECT * FROM evaluations WHERE itemId = ? AND contentHash = ? AND hashVersion = ? AND evaluationVersion = ? AND evaluationPolicyVersion = ? AND evaluationMode = ? LIMIT 1`,
    existingItem.itemId, contentHash, hashVersion, '2.0.0', '2.0.0', evaluationMode
  );

  let evaluationId;
  let isNewEval = true;

  if (existingEvalRow && !forceReevaluate) {
    evaluationId = existingEvalRow.evaluationId;
    isNewEval = false;
  } else {
    let result;
    if (evaluationMode === 'online') {
      if (!GEMINI_API_KEY || GEMINI_API_KEY === 'your_gemini_api_key_here') {
        return res.status(400).json({ error: 'Gemini API key not configured' });
      }
      try {
        const geminiResponse = await onlineEvaluate(content, GEMINI_API_KEY);
        const validation = validateGeminiResponse(geminiResponse);
        if (!validation.valid) {
          return res.status(422).json({ error: validation.error, raw: geminiResponse });
        }
        result = buildOnlineResult(content, geminiResponse);
      } catch (e) {
        return res.status(502).json({ error: `Gemini evaluation failed: ${e.message}` });
      }
    } else {
      result = await offlineEvaluate(content);
    }

    evaluationId = insertEvaluation({
      itemId: existingItem.itemId,
      contentHash,
      hashVersion,
      evaluationVersion: '2.0.0',
      evaluationPolicyVersion: '2.0.0',
      evaluationMode,
      overallScore: result.overallScore,
      rawScore: result.rawScore,
      scoreCapped: result.scoreCapped ? 1 : 0,
      verdict: result.verdict,
      dimensionScores: result.dimensionScores || [],
      criticalFindings: result.criticalFindings || [],
      majorFindings: result.majorFindings || [],
      minorFindings: result.minorFindings || [],
      suggestions: result.suggestions || [],
      improvedHook: result.improvedHook || null,
      storyImprovements: result.storyImprovements || null,
      improvedCaption: result.improvedCaption || null,
      evaluatedAt: result.evaluatedAt || new Date().toISOString(),
      evaluationEngine: evaluationMode,
    });

    insertEvent({
      eventId: generateId(),
      eventType: 'evaluation_created',
      itemId: existingItem.itemId,
      evaluationId,
      previousState: null,
      newState: { verdict: result.verdict, overallScore: result.overallScore },
      changedAt: result.evaluatedAt || new Date().toISOString(),
      changedBy: req.auth.user,
    });
  }

  const evalRecord = getEvaluationById(evaluationId);

  const currentApproval = getCurrentApproval(existingItem.itemId);
  const isApprovalValid = currentApproval
    && currentApproval.approvalStatus === 'approved'
    && currentApproval.contentHashAtApproval === contentHash
    && currentApproval.hashVersionAtApproval === hashVersion;

  res.json({
    ideaId: content.id || ideaId,
    contentHash,
    productionHash,
    hashVersion,
    evaluationId,
    overallScore: evalRecord.overallScore,
    rawScore: evalRecord.rawScore,
    scoreCapped: evalRecord.scoreCapped === 1,
    verdict: evalRecord.verdict,
    dimensionScores: JSON.parse(evalRecord.dimensionScores),
    criticalFindings: JSON.parse(evalRecord.criticalFindings),
    majorFindings: JSON.parse(evalRecord.majorFindings),
    minorFindings: JSON.parse(evalRecord.minorFindings),
    suggestions: JSON.parse(evalRecord.suggestions),
    improvedHook: evalRecord.improvedHook,
    storyImprovements: evalRecord.storyImprovements,
    improvedCaption: evalRecord.improvedCaption,
    evaluationMode: evalRecord.evaluationMode,
    evaluatedAt: evalRecord.evaluatedAt,
    evaluationVersion: evalRecord.evaluationVersion,
    isNewEval,
    itemId: existingItem.itemId,
    isApprovalValid,
    currentApproval: isApprovalValid ? {
      approvalStatus: currentApproval.approvalStatus,
      approvedAt: currentApproval.approvedAt,
    } : null,
  });
}));

app.get(`${API_BASE_PATH}/evaluations/:itemId/history`, authenticate, requireRole(), (_req, res) => {
  if (!dbReady) return res.status(503).json({ error: 'Database not ready' });
  const { itemId } = req.params;
  const history = getEvaluationHistory(itemId);
  res.json({ itemId, history: history.map((h) => ({
    evaluationId: h.evaluationId,
    contentHash: h.contentHash,
    hashVersion: h.hashVersion,
    evaluationVersion: h.evaluationVersion,
    evaluationPolicyVersion: h.evaluationPolicyVersion,
    evaluationMode: h.evaluationMode,
    overallScore: h.overallScore,
    rawScore: h.rawScore,
    scoreCapped: h.scoreCapped === 1,
    verdict: h.verdict,
    evaluatedAt: h.evaluatedAt,
    evaluationEngine: h.evaluationEngine,
  })) });
});

app.get(`${API_BASE_PATH}/evaluations/:itemId/current`, authenticate, requireRole(), (req, res) => {
  if (!dbReady) return res.status(503).json({ error: 'Database not ready' });
  const { itemId } = req.params;
  const evalRecord = getLatestEvaluation(itemId);
  if (!evalRecord) return res.status(404).json({ error: 'No evaluation found for this item' });

  const contentItem = getContentItem(itemId);
  const currentApproval = getCurrentApproval(itemId);
  const isApprovalValid = currentApproval
    && currentApproval.approvalStatus === 'approved'
    && currentApproval.contentHashAtApproval === evalRecord.contentHash
    && currentApproval.hashVersionAtApproval === evalRecord.hashVersion;

  res.json({
    itemId,
    evaluationId: evalRecord.evaluationId,
    contentHash: evalRecord.contentHash,
    productionHash: contentItem ? contentItem.productionHash : null,
    hashVersion: evalRecord.hashVersion,
    evaluationVersion: evalRecord.evaluationVersion,
    evaluationPolicyVersion: evalRecord.evaluationPolicyVersion,
    evaluationMode: evalRecord.evaluationMode,
    overallScore: evalRecord.overallScore,
    rawScore: evalRecord.rawScore,
    scoreCapped: evalRecord.scoreCapped === 1,
    verdict: evalRecord.verdict,
    dimensionScores: JSON.parse(evalRecord.dimensionScores),
    criticalFindings: JSON.parse(evalRecord.criticalFindings),
    majorFindings: JSON.parse(evalRecord.majorFindings),
    minorFindings: JSON.parse(evalRecord.minorFindings),
    suggestions: JSON.parse(evalRecord.suggestions),
    improvedHook: evalRecord.improvedHook,
    storyImprovements: evalRecord.storyImprovements,
    improvedCaption: evalRecord.improvedCaption,
    evaluatedAt: evalRecord.evaluatedAt,
    evaluationEngine: evalRecord.evaluationEngine,
    approvalStatus: currentApproval ? currentApproval.approvalStatus : 'evaluated',
    isApprovalValid,
    approvedAt: currentApproval ? currentApproval.approvedAt : null,
  });
});

app.post(`${API_BASE_PATH}/evaluations/:itemId/approve`, authenticate, requireRole(), (req, res) => {
  if (!dbReady) return res.status(503).json({ error: 'Database not ready' });
  const { itemId } = req.params;
  const { evaluationId, approvedBy, reason } = req.body || {};

  if (!evaluationId) {
    return res.status(400).json({ error: 'evaluationId is required' });
  }

  const evalRecord = getEvaluationById(evaluationId);
  if (!evalRecord || evalRecord.itemId !== itemId) {
    return res.status(404).json({ error: 'Evaluation not found for this item' });
  }

  const contentItem = getContentItem(itemId);
  if (!contentItem) {
    return res.status(404).json({ error: 'Content item not found' });
  }

  if (evalRecord.contentHash !== contentItem.contentHash) {
    return res.status(409).json({
      error: 'Content hash mismatch. Content has changed since evaluation. Re-evaluate before approving.',
    });
  }

  if (evalRecord.hashVersion !== contentItem.hashVersion) {
    return res.status(409).json({
      error: 'Hash version mismatch. Re-evaluate with current hash version.',
    });
  }

  const result = upsertApproval({
    itemId,
    evaluationId,
    approvalStatus: 'approved',
    contentHashAtApproval: evalRecord.contentHash,
    hashVersionAtApproval: evalRecord.hashVersion,
    evaluationPolicyVersionAtApproval: evalRecord.evaluationPolicyVersion,
    approvedBy: approvedBy || req.auth.user,
    reason: reason || 'Approved via API',
  });

  insertEvent({
    eventId: generateId(),
    eventType: 'approved',
    itemId,
    evaluationId,
    previousState: null,
    newState: { approvalStatus: 'approved' },
    changedAt: new Date().toISOString(),
    changedBy: approvedBy || req.auth.user,
  });

  res.json({
    itemId,
    evaluationId,
    approvalStatus: 'approved',
    approvedAt: new Date().toISOString(),
    approvedBy: approvedBy || req.auth.user,
    isApprovalValid: true,
    overallScore: evalRecord.overallScore,
    verdict: evalRecord.verdict,
  });
});

app.post(`${API_BASE_PATH}/evaluations/:itemId/reject`, authenticate, requireRole(), (req, res) => {
  if (!dbReady) return res.status(503).json({ error: 'Database not ready' });
  const { itemId } = req.params;
  const { evaluationId, rejectedBy, reason } = req.body || {};

  if (!evaluationId) {
    return res.status(400).json({ error: 'evaluationId is required' });
  }

  const evalRecord = getEvaluationById(evaluationId);
  if (!evalRecord || evalRecord.itemId !== itemId) {
    return res.status(404).json({ error: 'Evaluation not found for this item' });
  }

  upsertApproval({
    itemId,
    evaluationId,
    approvalStatus: 'rejected',
    contentHashAtApproval: evalRecord.contentHash,
    hashVersionAtApproval: evalRecord.hashVersion,
    evaluationPolicyVersionAtApproval: evalRecord.evaluationPolicyVersion,
    approvedBy: rejectedBy || req.auth.user,
    reason: reason || 'Rejected via API',
  });

  insertEvent({
    eventId: generateId(),
    eventType: 'rejected',
    itemId,
    evaluationId,
    previousState: null,
    newState: { approvalStatus: 'rejected' },
    changedAt: new Date().toISOString(),
    changedBy: rejectedBy || req.auth.user,
  });

  res.json({
    itemId,
    evaluationId,
    approvalStatus: 'rejected',
    rejectedAt: new Date().toISOString(),
    rejectedBy: rejectedBy || req.auth.user,
    reason: reason || 'Rejected via API',
  });
});

app.post(`${API_BASE_PATH}/evaluations/:itemId/revoke`, authenticate, requireRole(), (req, res) => {
  if (!dbReady) return res.status(503).json({ error: 'Database not ready' });
  const { itemId } = req.params;
  const { evaluationId, revokedBy, reason } = req.body || {};

  const currentApproval = getCurrentApproval(itemId);
  if (!currentApproval || currentApproval.approvalStatus !== 'approved') {
    return res.status(409).json({ error: 'No active approval to revoke' });
  }

  if (evaluationId && currentApproval.evaluationId !== evaluationId) {
    return res.status(409).json({ error: 'Evaluation ID does not match current approval' });
  }

  upsertApproval({
    itemId,
    evaluationId: currentApproval.evaluationId,
    approvalStatus: 'revoked',
    contentHashAtApproval: currentApproval.contentHashAtApproval,
    hashVersionAtApproval: currentApproval.hashVersionAtApproval,
    evaluationPolicyVersionAtApproval: currentApproval.evaluationPolicyVersionAtApproval,
    approvedBy: revokedBy || req.auth.user,
    reason: reason || 'Revoked via API',
  });

  insertEvent({
    eventId: generateId(),
    eventType: 'revoked',
    itemId,
    evaluationId: currentApproval.evaluationId,
    previousState: { approvalStatus: 'approved' },
    newState: { approvalStatus: 'revoked' },
    changedAt: new Date().toISOString(),
    changedBy: revokedBy || req.auth.user,
  });

  res.json({
    itemId,
    evaluationId: currentApproval.evaluationId,
    approvalStatus: 'revoked',
    revokedAt: new Date().toISOString(),
    revokedBy: revokedBy || req.auth.user,
    reason: reason || 'Revoked via API',
  });
});

app.get(`${API_BASE_PATH}/evaluations/:itemId/approval-status`, authenticate, requireRole(), (req, res) => {
  if (!dbReady) return res.status(503).json({ error: 'Database not ready' });
  const { itemId } = req.params;

  const contentItem = getContentItem(itemId);
  if (!contentItem) return res.status(404).json({ error: 'Content item not found' });

  const evalRecord = getLatestEvaluation(itemId);
  const currentApproval = getCurrentApproval(itemId);

  let isApprovalValid = false;
  if (currentApproval && currentApproval.approvalStatus === 'approved') {
    isApprovalValid =
      currentApproval.contentHashAtApproval === contentItem.contentHash
      && currentApproval.hashVersionAtApproval === contentItem.hashVersion;
  }

  res.json({
    itemId,
    approvalStatus: currentApproval ? currentApproval.approvalStatus : 'evaluated',
    isApprovalValid,
    contentHash: contentItem.contentHash,
    hashVersion: contentItem.hashVersion,
    evaluationPolicyVersionAtApproval: currentApproval ? currentApproval.evaluationPolicyVersionAtApproval : null,
    currentEvaluationId: evalRecord ? evalRecord.evaluationId : null,
    currentOverallScore: evalRecord ? evalRecord.overallScore : null,
    currentVerdict: evalRecord ? evalRecord.verdict : null,
    approvedAt: currentApproval ? currentApproval.approvedAt : null,
  });
});

app.get(`${API_BASE_PATH}/content-hash/:itemId`, authenticate, requireRole(), (req, res) => {
  if (!dbReady) return res.status(503).json({ error: 'Database not ready' });
  const { itemId } = req.params;
  const contentItem = getContentItem(itemId);
  if (!contentItem) return res.status(404).json({ error: 'Content item not found' });

  res.json({
    itemId,
    contentHash: contentItem.contentHash,
    hashVersion: contentItem.hashVersion,
    creativeHashFields: getCreativeHashFields(),
  });
});

app.get(`${API_BASE_PATH}/production-hash/:itemId`, authenticate, requireRole(), (req, res) => {
  if (!dbReady) return res.status(503).json({ error: 'Database not ready' });
  const { itemId } = req.params;
  const contentItem = getContentItem(itemId);
  if (!contentItem) return res.status(404).json({ error: 'Content item not found' });

  res.json({
    itemId,
    productionHash: contentItem.productionHash,
    hashVersion: contentItem.hashVersion,
    productionHashFields: getProductionHashFields(),
  });
});

app.get(`${API_BASE_PATH}/evaluations/batch`, authenticate, requireRole(), (_req, res) => {
  if (!dbReady) return res.status(503).json({ error: 'Database not ready' });

  const since = parseInt(_req.query.since || '0', 10);
  const limit = Math.min(parseInt(_req.query.limit || '100', 10), 1000);
  const itemId = _req.query.itemId || null;
  const eventType = _req.query.eventType || null;

  if (isNaN(since) || since < 0) {
    return res.status(400).json({ error: 'Invalid since parameter' });
  }
  if (isNaN(limit) || limit < 1) {
    return res.status(400).json({ error: 'Invalid limit parameter' });
  }

  const result = getEventsSince({ since, limit, itemId, eventType });

  res.json({
    snapshotUpperBound: result.snapshotUpperBound,
    nextSince: result.nextSince,
    hasMore: result.hasMore,
    events: result.events.map((e) => ({
      changeSequence: e.changeSequence,
      eventId: e.eventId,
      eventType: e.eventType,
      itemId: e.itemId,
      evaluationId: e.evaluationId,
      previousState: e.previousState ? JSON.parse(e.previousState) : null,
      newState: e.newState ? JSON.parse(e.newState) : null,
      changedAt: e.changedAt,
      changedBy: e.changedBy,
    })),
  });
});

app.delete('/api/ratings/:id', (req, res) => {
  const ok = deleteRating(req.params.id);
  if (!ok) return res.status(404).json({ error: 'Rating not found' });
  res.json({ ok: true });
});

app.delete('/api/ratings', (_req, res) => {
  const count = clearRatings();
  res.json({ cleared: count });
});

app.get('/api/export/json', (_req, res) => {
  const ratings = listRatings();
  res.setHeader('Content-Type', 'application/json');
  res.setHeader('Content-Disposition', 'attachment; filename=content_ratings.json');
  res.send(JSON.stringify(ratings, null, 2));
});

app.get('/api/export/csv', (_req, res) => {
  const ratings = listRatings();
  const headers = [
    'ideaId', 'title', 'category', 'overallScore', 'rawScore', 'verdict', 'scoreCapped', 'capsApplied', 'evaluationVersion', 'evaluationMode',
    'hookStrength', 'relatabilityAudienceFit', 'payoffRetention', 'hinglishNaturalness',
    'visualFeasibility', 'soundOffReadability', 'shareSaveTrigger', 'captionCommentPackage',
    'originality', 'audioHook',
    'criticalCount', 'majorCount', 'minorCount', 'confidence', 'potentialScore', 'recommendedFormat', 'duplicateOf', 'seasonTag', 'evaluatedAt',
  ];

  let ideasMap = {};
  try {
    const raw = fs.readFileSync(CONTENT_JSON_PATH, 'utf8');
    const data = JSON.parse(raw);
    data.ideas.forEach(i => { ideasMap[i.id] = i; });
  } catch (e) {}

  const lines = [headers.join(',')];
  ratings.forEach(r => {
    const idea = ideasMap[r.ideaId] || {};
    const dims = {};
    r.dimensionScores.forEach(d => { dims[d.id] = d.score; });
    const row = [
      r.ideaId,
      `"${(idea.title || '').replace(/"/g, '""')}"`,
      `"${(idea.category || '').replace(/"/g, '""')}"`,
      r.overallScore,
      r.rawScore,
      `"${r.verdict}"`,
      r.scoreCapped,
      `"${(r.capsApplied || []).join('; ')}"`,
      r.evaluationVersion,
      r.evaluationMode,
      dims.hookStrength || 0,
      dims.relatabilityAudienceFit || dims.relatability || 0,
      dims.payoffRetention || dims.storyStructure || 0,
      dims.hinglishNaturalness || 0,
      dims.visualFeasibility || 0,
      dims.soundOffReadability || 0,
      dims.shareSaveTrigger || dims.engagementPotential || 0,
      dims.captionCommentPackage || 0,
      dims.originality || 0,
      dims.audioHook || 0,
      r.criticalFindings?.length || 0,
      r.majorFindings?.length || 0,
      r.minorFindings?.length || 0,
      r.confidence || '',
      r.potentialScore || '',
      r.recommendedFormat || '',
      `"${(r.duplicateOf || []).join('; ')}"`,
      r.seasonTag || '',
      r.evaluatedAt,
    ];
    lines.push(row.join(','));
  });

  res.setHeader('Content-Type', 'text/csv');
  res.setHeader('Content-Disposition', 'attachment; filename=content_ratings.csv');
  res.send(lines.join('\n'));
});

app.get('/api/health', (_req, res) => {
  res.json({
    ok: true,
    geminiConfigured: !!GEMINI_API_KEY && GEMINI_API_KEY !== 'your_gemini_api_key_here',
    database: dbReady ? 'ready' : 'not ready',
    nodeEnv: NODE_ENV,
  });
});

app.use((err, req, res, _next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({ error: 'Internal server error', message: err.message });
});

process.on('SIGTERM', async () => {
  closeDb();
  process.exit(0);
});
process.on('SIGINT', async () => {
  closeDb();
  process.exit(0);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
});

process.on('uncaughtException', (err) => {
  console.error('Uncaught Exception:', err);
});

const server = app.listen(PORT, '127.0.0.1', () => {
  console.log(`Content Rating Tool backend running on http://localhost:${PORT}`);
  console.log(`Gemini API key: ${GEMINI_API_KEY ? 'configured' : 'not configured (offline mode only)'}`);
  console.log(`Server bound to loopback interface (127.0.0.1) only.`);
  console.log(`API base path: ${API_BASE_PATH}`);
  console.log(`Authentication: ${NODE_ENV === 'production' ? 'required' : 'development mode (optional)'}`);
});

module.exports = { app, server };
