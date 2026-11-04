const path = require('path');
const fs = require('fs');
require('dotenv').config({ path: path.resolve(__dirname, '.env') });
const express = require('express');
const cors = require('cors');

const { offlineEvaluate, onlineEvaluate, buildOnlineResult } = require('./backend/ratingEngine');
const { validateGeminiResponse } = require('./backend/schemas');
const { listRatings, getRating, saveRating, deleteRating, clearRatings, RATINGS_DIR, ensureDirs } = require('./backend/storage');

ensureDirs();

const app = express();
const PORT = process.env.PORT || 3001;
const GEMINI_API_KEY = process.env.GEMINI_API_KEY || '';

app.use(cors());
app.use(express.json({ limit: '2mb' }));

// ── Root: serve dashboard ────────────────────────────────────────────
app.get('/', (_req, res) => {
  res.sendFile(path.join(__dirname, 'frontend/index.html'));
});

// Serve static frontend
app.use(express.static(path.join(__dirname, 'frontend')));

const CONTENT_JSON_PATH = path.resolve(__dirname, '../../assets/data/content_ideas.json');

// ── API: List all ideas from the source JSON ──────────────────────────
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

// ── API: Get a single idea by ID ─────────────────────────────────────
app.get('/api/ideas/:id', (req, res) => {
  const raw = fs.readFileSync(CONTENT_JSON_PATH, 'utf8');
  const data = JSON.parse(raw);
  const idea = data.ideas.find(i => i.id === req.params.id);
  if (!idea) return res.status(404).json({ error: 'Idea not found' });
  res.json(idea);
});

// ── API: List saved ratings ──────────────────────────────────────────
app.get('/api/ratings', (_req, res) => {
  const ratings = listRatings();
  res.json(ratings);
});

// ── API: Get a saved rating ──────────────────────────────────────────
app.get('/api/ratings/:id', (req, res) => {
  const rating = getRating(req.params.id);
  if (!rating) return res.status(404).json({ error: 'Rating not found' });
  res.json(rating);
});

// ── API: Evaluate a single idea ──────────────────────────────────────
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
      const geminiResponse = await onlineEvaluate(idea, GEMINI_API_KEY);
      const validation = validateGeminiResponse(geminiResponse);
      if (!validation.valid) {
        return res.status(422).json({ error: validation.error, raw: geminiResponse });
      }
      result = buildOnlineResult(idea, geminiResponse);
    } catch (e) {
      return res.status(502).json({ error: `Gemini evaluation failed: ${e.message}` });
    }
  } else {
    result = offlineEvaluate(idea);
  }

  const saved = saveRating(result);
  res.json(saved);
});

// ── API: Delete a rating ─────────────────────────────────────────────
app.delete('/api/ratings/:id', (req, res) => {
  const ok = deleteRating(req.params.id);
  if (!ok) return res.status(404).json({ error: 'Rating not found' });
  res.json({ ok: true });
});

// ── API: Clear all ratings ───────────────────────────────────────────
app.delete('/api/ratings', (_req, res) => {
  const count = clearRatings();
  res.json({ cleared: count });
});

// ── API: Export all ratings as JSON ──────────────────────────────────
app.get('/api/export/json', (_req, res) => {
  const ratings = listRatings();
  res.setHeader('Content-Type', 'application/json');
  res.setHeader('Content-Disposition', 'attachment; filename=content_ratings.json');
  res.send(JSON.stringify(ratings, null, 2));
});

// ── API: Export all ratings as CSV ───────────────────────────────────
app.get('/api/export/csv', (_req, res) => {
  const ratings = listRatings();
  const headers = [
    'ideaId', 'title', 'category', 'overallScore', 'verdict',
    'hookStrength', 'relatability', 'storyStructure', 'ageAppropriateness',
    'hinglishNaturalness', 'characterConsistency', 'visualFeasibility',
    'soundOffReadability', 'engagementPotential', 'brandAndSafety',
    'criticalCount', 'majorCount', 'minorCount', 'evaluationMode', 'evaluatedAt',
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
      `"${r.verdict}"`,
      dims.hookStrength || 0,
      dims.relatability || 0,
      dims.storyStructure || 0,
      dims.ageAppropriateness || 0,
      dims.hinglishNaturalness || 0,
      dims.characterConsistency || 0,
      dims.visualFeasibility || 0,
      dims.soundOffReadability || 0,
      dims.engagementPotential || 0,
      dims.brandAndSafety || 0,
      r.criticalFindings?.length || 0,
      r.majorFindings?.length || 0,
      r.minorFindings?.length || 0,
      r.evaluationMode,
      r.evaluatedAt,
    ];
    lines.push(row.join(','));
  });

  res.setHeader('Content-Type', 'text/csv');
  res.setHeader('Content-Disposition', 'attachment; filename=content_ratings.csv');
  res.send(lines.join('\n'));
});

// ── Health check ─────────────────────────────────────────────────────
app.get('/api/health', (_req, res) => {
  res.json({ ok: true, geminiConfigured: !!GEMINI_API_KEY && GEMINI_API_KEY !== 'your_gemini_api_key_here' });
});

app.listen(PORT, '127.0.0.1', () => {
  console.log(`Content Rating Tool backend running on http://localhost:${PORT}`);
  console.log(`Gemini API key: ${GEMINI_API_KEY ? 'configured' : 'not configured (offline mode only)'}`);
  console.log(`Server bound to loopback interface (127.0.0.1) only.`);
});
