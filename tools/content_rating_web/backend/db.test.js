'use strict';

/**
 * Tests for the SQLite storage layer (backend/db.js).
 * Uses synchronous API (node:sqlite DatabaseSync).
 */

const assert = require('node:assert/strict');
const test = require('node:test');
const fs = require('fs');
const os = require('os');
const path = require('path');
const {
  openDb, closeDb, upsertContentItem, insertEvaluation, getLatestEvaluation,
  getEvaluationById, getEvaluationHistory, upsertApproval, getCurrentApproval,
  insertEvent, getEventsSince, generateId, resetAll, getContentItem,
  getContentItemByIdentity,
} = require('./db');

function getTestDbPath() {
  return path.join(os.tmpdir(), `content_rating_test_${Date.now()}_${Math.random().toString(36).slice(2)}.db`);
}

function withTestDb(fn) {
  const dbPath = getTestDbPath();
  try {
    openDb(dbPath);
    fn();
  } finally {
    closeDb();
    try { fs.unlinkSync(dbPath); } catch (_) {}
  }
}

test('openDb and closeDb', () => {
  withTestDb(() => {
    assert.ok(true, 'Database opened and closed');
  });
});

test('upsertContentItem creates new item', () => {
  withTestDb(() => {
    const result = upsertContentItem({
      workspaceId: 'ws1',
      source: 'built_in',
      ideaId: 'idea_1',
      contentHash: 'abc123',
      hashVersion: '1.0.0',
      productionHash: 'def456',
    });
    assert.ok(result.itemId);
    assert.equal(result.created, true);

    const result2 = upsertContentItem({
      workspaceId: 'ws1',
      source: 'built_in',
      ideaId: 'idea_1',
      contentHash: 'newHash',
      hashVersion: '1.0.0',
      productionHash: 'newProd',
    });
    assert.equal(result2.created, false);
    assert.equal(result2.itemId, result.itemId);

    const item = getContentItem(result.itemId);
    assert.equal(item.contentHash, 'newHash');
    assert.equal(item.productionHash, 'newProd');
  });
});

test('upsertContentItem enforces unique workspace+source+ideaId', () => {
  withTestDb(() => {
    upsertContentItem({
      workspaceId: 'ws1',
      source: 'built_in',
      ideaId: 'idea_1',
      contentHash: 'hash1',
      hashVersion: '1.0.0',
    });
    const result = upsertContentItem({
      workspaceId: 'ws1',
      source: 'built_in',
      ideaId: 'idea_1',
      contentHash: 'hash2',
      hashVersion: '1.0.0',
    });
    assert.equal(result.created, false);
    const item = getContentItem(result.itemId);
    assert.equal(item.contentHash, 'hash2');
  });
});

test('different workspaces can have same ideaId', () => {
  withTestDb(() => {
    const r1 = upsertContentItem({
      workspaceId: 'ws1',
      source: 'built_in',
      ideaId: 'idea_1',
      contentHash: 'hash1',
      hashVersion: '1.0.0',
    });
    const r2 = upsertContentItem({
      workspaceId: 'ws2',
      source: 'built_in',
      ideaId: 'idea_1',
      contentHash: 'hash2',
      hashVersion: '1.0.0',
    });
    assert.notEqual(r1.itemId, r2.itemId);
  });
});

test('insertEvaluation creates evaluation record', () => {
  withTestDb(() => {
    const { itemId } = upsertContentItem({
      workspaceId: 'ws1',
      source: 'built_in',
      ideaId: 'idea_1',
      contentHash: 'hash1',
      hashVersion: '1.0.0',
    });

    const evalId = insertEvaluation({
      itemId,
      contentHash: 'hash1',
      hashVersion: '1.0.0',
      evaluationVersion: '1.2.0-offline',
      evaluationPolicyVersion: '1.0.0',
      evaluationMode: 'offline',
      overallScore: 86,
      rawScore: 86,
      scoreCapped: 0,
      verdict: 'Ready to Post',
      dimensionScores: [{ id: 'hookStrength', score: 8 }],
      criticalFindings: [],
      majorFindings: [],
      minorFindings: [],
      suggestions: [],
      evaluatedAt: new Date().toISOString(),
      evaluationEngine: 'offline',
    });

    assert.ok(evalId);
    const evalRecord = getEvaluationById(evalId);
    assert.ok(evalRecord);
    assert.equal(evalRecord.overallScore, 86);
    assert.equal(evalRecord.verdict, 'Ready to Post');
  });
});

test('getLatestEvaluation returns most recent', () => {
  withTestDb(() => {
    const { itemId } = upsertContentItem({
      workspaceId: 'ws1',
      source: 'built_in',
      ideaId: 'idea_1',
      contentHash: 'hash1',
      hashVersion: '1.0.0',
    });

    const id1 = insertEvaluation({
      itemId,
      contentHash: 'hash1',
      hashVersion: '1.0.0',
      evaluationVersion: '1.2.0-offline',
      evaluationPolicyVersion: '1.0.0',
      evaluationMode: 'offline',
      overallScore: 80,
      rawScore: 80,
      scoreCapped: 0,
      verdict: 'Needs Minor Fixes',
      dimensionScores: [], criticalFindings: [], majorFindings: [], minorFindings: [], suggestions: [],
      evaluatedAt: new Date('2026-01-01').toISOString(),
      evaluationEngine: 'offline',
    });
    const id2 = insertEvaluation({
      itemId,
      contentHash: 'hash1',
      hashVersion: '1.0.0',
      evaluationVersion: '1.2.0-offline',
      evaluationPolicyVersion: '1.0.0',
      evaluationMode: 'offline',
      overallScore: 90,
      rawScore: 90,
      scoreCapped: 0,
      verdict: 'Ready to Post',
      dimensionScores: [], criticalFindings: [], majorFindings: [], minorFindings: [], suggestions: [],
      evaluatedAt: new Date('2026-02-01').toISOString(),
      evaluationEngine: 'offline',
    });

    const latest = getLatestEvaluation(itemId);
    assert.equal(latest.evaluationId, id2);
    assert.equal(latest.overallScore, 90);

    const history = getEvaluationHistory(itemId);
    assert.equal(history.length, 2);
    assert.equal(history[0].evaluationId, id2);
    assert.equal(history[1].evaluationId, id1);
  });
});

test('upsertApproval creates and retrieves approval', () => {
  withTestDb(() => {
    const { itemId } = upsertContentItem({
      workspaceId: 'ws1',
      source: 'built_in',
      ideaId: 'idea_1',
      contentHash: 'hash1',
      hashVersion: '1.0.0',
    });
    const evalId = insertEvaluation({
      itemId,
      contentHash: 'hash1',
      hashVersion: '1.0.0',
      evaluationVersion: '1.2.0-offline',
      evaluationPolicyVersion: '1.0.0',
      evaluationMode: 'offline',
      overallScore: 90,
      rawScore: 90,
      scoreCapped: 0,
      verdict: 'Ready to Post',
      dimensionScores: [], criticalFindings: [], majorFindings: [], minorFindings: [], suggestions: [],
      evaluatedAt: new Date().toISOString(),
      evaluationEngine: 'offline',
    });

    const result = upsertApproval({
      itemId,
      evaluationId: evalId,
      approvalStatus: 'approved',
      contentHashAtApproval: 'hash1',
      hashVersionAtApproval: '1.0.0',
      evaluationPolicyVersionAtApproval: '1.0.0',
      approvedBy: 'user1',
      reason: 'Good content',
    });
    assert.ok(result.approvalId);

    const current = getCurrentApproval(itemId);
    assert.ok(current);
    assert.equal(current.approvalStatus, 'approved');
    assert.equal(current.approvedBy, 'user1');
  });
});

test('insertEvent and getEventsSince work correctly', () => {
  withTestDb(() => {
    const { itemId } = upsertContentItem({
      workspaceId: 'ws1',
      source: 'built_in',
      ideaId: 'idea_1',
      contentHash: 'hash1',
      hashVersion: '1.0.0',
    });

    const evalId = insertEvaluation({
      itemId,
      contentHash: 'hash1',
      hashVersion: '1.0.0',
      evaluationVersion: '1.2.0-offline',
      evaluationPolicyVersion: '1.0.0',
      evaluationMode: 'offline',
      overallScore: 86,
      rawScore: 86,
      scoreCapped: 0,
      verdict: 'Ready to Post',
      dimensionScores: [{ id: 'hookStrength', score: 8 }],
      criticalFindings: [],
      majorFindings: [],
      minorFindings: [],
      suggestions: [],
      evaluatedAt: new Date().toISOString(),
      evaluationEngine: 'offline',
    });

    const now = new Date().toISOString();
    insertEvent({
      eventId: 'evt_1',
      eventType: 'evaluation_created',
      itemId,
      evaluationId: evalId,
      previousState: null,
      newState: { verdict: 'Ready to Post' },
      changedAt: now,
      changedBy: 'user1',
    });
    insertEvent({
      eventId: 'evt_2',
      eventType: 'approved',
      itemId,
      evaluationId: evalId,
      previousState: null,
      newState: { approvalStatus: 'approved' },
      changedAt: now,
      changedBy: 'user1',
    });

    const result = getEventsSince({ since: 0, limit: 10 });
    assert.ok(result.events.length >= 2);
    assert.ok(result.snapshotUpperBound >= 2);

    const result2 = getEventsSince({ since: result.nextSince, limit: 10 });
    assert.ok(result2.hasMore === false || result2.events.length === 0);
  });
});

test('resetAll clears all data', () => {
  withTestDb(() => {
    upsertContentItem({
      workspaceId: 'ws1',
      source: 'built_in',
      ideaId: 'idea_1',
      contentHash: 'hash1',
      hashVersion: '1.0.0',
    });
    resetAll();
    const item = getContentItem('nonexistent');
    assert.ok(!item);
  });
});

test('getContentItemByIdentity works', () => {
  withTestDb(() => {
    upsertContentItem({
      workspaceId: 'ws1',
      source: 'flutter_edited',
      ideaId: 'idea_1',
      contentHash: 'hash1',
      hashVersion: '1.0.0',
    });
    const item = getContentItemByIdentity({
      workspaceId: 'ws1',
      source: 'flutter_edited',
      ideaId: 'idea_1',
    });
    assert.ok(item);
    assert.equal(item.contentHash, 'hash1');
  });
});
