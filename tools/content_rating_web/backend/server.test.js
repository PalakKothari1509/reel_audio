'use strict';

/**
 * Integration tests for the Content Rating API server.
 * Starts the server on a test port and makes HTTP requests.
 */

const assert = require('node:assert/strict');
const test = require('node:test');
const http = require('http');
const fs = require('fs');
const path = require('path');
const os = require('os');

const TEST_PORT = 3999;
const TEST_DB_PATH = path.join(os.tmpdir(), `content_rating_api_test_${Date.now()}.db`);
const TEST_RATINGS_DIR = path.join(os.tmpdir(), `content_rating_api_ratings_${Date.now()}`);

process.env.PORT = String(TEST_PORT);
process.env.NODE_ENV = 'development';
process.env.API_ACCESS_TOKEN = 'test_token_123';
process.env.CONTENT_RATING_DB_PATH = TEST_DB_PATH;
process.env.CONTENT_RATING_RATINGS_DIR = TEST_RATINGS_DIR;

fs.mkdirSync(TEST_RATINGS_DIR, { recursive: true });

let server;
let serverUrl;
let serverStarted = false;

async function startServer() {
  if (serverStarted) return;
  // Import server module (starts the server)
  await import('../server.js');
  serverStarted = true;
  return new Promise((resolve) => {
    // Wait a bit for server to start
    setTimeout(resolve, 500);
  });
}

async function stopServer() {
  // Server closes on process exit; for tests we just stop making requests
  serverStarted = false;
}

async function request(method, path, body = {}, token = null) {
  return new Promise((resolve, reject) => {
    const url = new URL(path, serverUrl);
    const options = {
      hostname: url.hostname,
      port: url.port,
      path: url.pathname,
      method,
      headers: {
        'Content-Type': 'application/json',
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
      },
    };

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => {
        try {
          resolve({ status: res.statusCode, body: JSON.parse(data) });
        } catch (e) {
          resolve({ status: res.statusCode, body: data });
        }
      });
    });

    req.setTimeout(5000, () => {
      req.destroy();
      reject(new Error('Request timeout'));
    });

    req.on('error', reject);
    if (body && Object.keys(body).length > 0) {
      req.write(JSON.stringify(body));
    }
    req.end();
  });
}

async function get(path, token = null) {
  return request('GET', path, {}, token);
}

async function post(path, body, token = null) {
  return request('POST', path, body, token);
}

const BASE_IDEA = {
  id: 'test_idea',
  category: 'Safety',
  title: 'Test Idea',
  cover: 'Stay Safe',
  opening: 'Did you know?',
  problem: 'Children run near tools.',
  lesson: 'Always supervise kids.',
  storyDetail: 'A safety story.',
  endingBeat: 'All safe.',
  caption: 'Safety tips!',
  pinnedComment: 'Questions?',
  dialogue: 'Be careful!',
  defaultCast: ['Ria', 'Mumma'],
  setting: 'Garden',
  sceneDetail: 'Rake on grass.',
  postFormat: 'Reel',
  strategy: 'Educational',
  mess: 'Tools out.',
  innerThought: 'Clean up.',
  keepMoralOffScreen: false,
  quote: 'Watch out!',
  detail: 'Red rake.',
  punchline: 'Safe!',
  readyPrompt: 'Prompt.',
  forApp: true,
};

test('health check works', async () => {
  await startServer();
  serverUrl = `http://localhost:${TEST_PORT}`;
  const res = await get('/api/health', 'test_token_123');
  assert.equal(res.status, 200);
  assert.ok(res.body.ok);
});

test('legacy GET /api/ideas works without auth', async () => {
  const res = await get('/api/ideas');
  assert.equal(res.status, 200);
  assert.ok(Array.isArray(res.body.ideas));
  assert.ok(res.body.ideas.length > 0);
});

test('legacy GET /api/ideas/:id works', async () => {
  const res = await get('/api/ideas/idea_1');
  assert.equal(res.status, 200);
  assert.equal(res.body.id, 'idea_1');
});

test('legacy POST /api/evaluate/:id works for built-in', async () => {
  const res = await post('/api/evaluate/idea_1', { mode: 'offline' });
  assert.equal(res.status, 200);
  assert.ok(res.body.overallScore);
  assert.ok(res.body.verdict);
});

test('POST /api/evaluate requires authentication', async () => {
  const res = await post('/api/evaluate', {
    workspaceId: 'ws1',
    source: 'flutter_custom',
    ideaId: 'custom_1',
    content: BASE_IDEA,
  });
  assert.equal(res.status, 401);
});

test('POST /api/evaluate evaluates external content', async () => {
  const res = await post('/api/evaluate', {
    workspaceId: 'ws1',
    source: 'flutter_custom',
    ideaId: 'custom_1',
    content: BASE_IDEA,
    evaluationMode: 'offline',
  }, 'test_token_123');

  assert.equal(res.status, 200);
  assert.ok(res.body.contentHash);
  assert.ok(res.body.productionHash);
  assert.ok(res.body.hashVersion);
  assert.ok(res.body.overallScore);
  assert.ok(res.body.verdict);
  assert.ok(res.body.evaluationId);
  assert.equal(res.body.isNewEval, true);
});

test('POST /api/evaluate rejects invalid source', async () => {
  const res = await post('/api/evaluate', {
    workspaceId: 'ws1',
    source: 'invalid_source',
    ideaId: 'custom_1',
    content: BASE_IDEA,
  }, 'test_token_123');
  assert.equal(res.status, 400);
});

test('POST /api/evaluate missing workspaceId returns 400', async () => {
  const res = await post('/api/evaluate', {
    source: 'flutter_custom',
    ideaId: 'custom_1',
    content: BASE_IDEA,
  }, 'test_token_123');
  assert.equal(res.status, 400);
});

test('GET /api/evaluations/:itemId/history requires auth', async () => {
  const res = await get('/api/evaluations/some_item/history');
  assert.equal(res.status, 401);
});

test('GET /api/evaluations/:itemId/current returns 404 for unknown item', async () => {
  const res = await get('/api/evaluations/nonexistent_item/current', 'test_token_123');
  assert.equal(res.status, 404);
});

test('POST /api/evaluations/:itemId/approve requires evaluationId', async () => {
  const res = await post('/api/evaluations/some_item/approve', {}, 'test_token_123');
  assert.equal(res.status, 400);
});

test('POST /api/evaluations/:itemId/revoke with no active approval returns 409', async () => {
  const res = await post('/api/evaluations/some_item/revoke', {}, 'test_token_123');
  assert.equal(res.status, 409);
});

test('GET /api/content-hash/:itemId returns 404 for unknown item', async () => {
  const res = await get('/api/content-hash/unknown_item', 'test_token_123');
  assert.equal(res.status, 404);
});

test('GET /api/evaluations/batch requires auth', async () => {
  const res = await get('/api/evaluations/batch');
  assert.equal(res.status, 401);
});

test('GET /api/evaluations/batch works with auth', async () => {
  const res = await get('/api/evaluations/batch?since=0&limit=10', 'test_token_123');
  assert.equal(res.status, 200);
  assert.ok(res.body.snapshotUpperBound !== undefined);
  assert.ok(res.body.nextSince !== undefined);
  assert.ok(res.body.hasMore !== undefined);
  assert.ok(Array.isArray(res.body.events));
});

test('same content returns same evaluation (not new)', async () => {
  const first = await post('/api/evaluate', {
    workspaceId: 'ws1',
    source: 'flutter_custom',
    ideaId: 'dedup_test',
    content: BASE_IDEA,
    evaluationMode: 'offline',
  }, 'test_token_123');
  assert.equal(first.status, 200);
  assert.equal(first.body.isNewEval, true);

  const second = await post('/api/evaluate', {
    workspaceId: 'ws1',
    source: 'flutter_custom',
    ideaId: 'dedup_test',
    content: BASE_IDEA,
    evaluationMode: 'offline',
  }, 'test_token_123');
  assert.equal(second.status, 200);
  assert.equal(second.body.isNewEval, false);
  assert.equal(first.body.evaluationId, second.body.evaluationId);
});

test('approve then revoke flow works', async () => {
  const evalRes = await post('/api/evaluate', {
    workspaceId: 'ws1',
    source: 'flutter_custom',
    ideaId: 'approve_test',
    content: BASE_IDEA,
    evaluationMode: 'offline',
  }, 'test_token_123');
  assert.equal(evalRes.status, 200);
  const evaluationId = evalRes.body.evaluationId;
  const itemId = evalRes.body.itemId;

  const approveRes = await post(`/api/evaluations/${itemId}/approve`, {
    evaluationId,
    approvedBy: 'user1',
    reason: 'Good content',
  }, 'test_token_123');
  assert.equal(approveRes.status, 200);
  assert.equal(approveRes.body.approvalStatus, 'approved');

  const statusRes = await get(`/api/evaluations/${itemId}/approval-status`, 'test_token_123');
  assert.equal(statusRes.status, 200);
  assert.equal(statusRes.body.approvalStatus, 'approved');
  assert.equal(statusRes.body.isApprovalValid, true);

  const revokeRes = await post(`/api/evaluations/${itemId}/revoke`, {
    evaluationId,
    revokedBy: 'user1',
    reason: 'Changed mind',
  }, 'test_token_123');
  assert.equal(revokeRes.status, 200);
  assert.equal(revokeRes.body.approvalStatus, 'revoked');

  const statusRes2 = await get(`/api/evaluations/${itemId}/approval-status`, 'test_token_123');
  assert.equal(statusRes2.status, 200);
  assert.equal(statusRes2.body.approvalStatus, 'revoked');
  assert.equal(statusRes2.body.isApprovalValid, false);
});

test('GET /api/export/json still works (legacy)', async () => {
  const res = await get('/api/export/json');
  assert.equal(res.status, 200);
  assert.ok(Array.isArray(res.body));
});

test('GET /api/export/csv still works (legacy)', async () => {
  const res = await get('/api/export/csv');
  assert.equal(res.status, 200);
  assert.ok(res.body.includes('ideaId'));
});
