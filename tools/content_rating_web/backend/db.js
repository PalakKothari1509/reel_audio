'use strict';

const path = require('path');
const { DatabaseSync } = require('node:sqlite');

const DB_PATH = path.resolve(process.env.CONTENT_RATING_DB_PATH || path.join(__dirname, '..', 'data', 'evaluations.db'));

let db = null;

/**
 * Open the SQLite database and ensure schema exists.
 * Enables foreign key enforcement and WAL mode for better concurrency.
 */
function openDb(dbPath = DB_PATH) {
  if (db) return db;
  db = new DatabaseSync(dbPath);
  db.exec(`PRAGMA journal_mode = WAL`);
  db.exec(`PRAGMA foreign_keys = ON`);
  createSchema();
  return db;
}

/**
 * Close the database connection.
 */
function closeDb() {
  if (db) {
    db.close();
    db = null;
  }
}

/**
 * Sanitize bound parameters for node:sqlite, which does not accept
 * null or undefined values as bound parameters. Replace with
 * appropriate defaults: empty string for text, 0 for numbers.
 */
function sanitizeParams(...params) {
  return params.map((p) => {
    if (p === null || p === undefined) return '';
    if (typeof p === 'boolean') return p ? 1 : 0;
    return p;
  });
}

/**
 * Execute a statement with parameter binding, sanitizing null/undefined values.
 */
function dbRun(sql, ...params) {
  return db.prepare(sql).run(...sanitizeParams(...params));
}

/**
 * Execute a query returning a single row.
 */
function dbGet(sql, ...params) {
  return db.prepare(sql).get(...sanitizeParams(...params));
}

/**
 * Execute a query returning all rows.
 */
function dbAll(sql, ...params) {
  return db.prepare(sql).all(...sanitizeParams(...params));
}

/**
 * Create all tables if they don't exist.
 */
function createSchema() {
  db.exec(`
    CREATE TABLE IF NOT EXISTS content_items (
      itemId TEXT PRIMARY KEY,
      workspaceId TEXT NOT NULL,
      source TEXT NOT NULL CHECK (source IN ('built_in', 'flutter_edited', 'flutter_custom', 'browser_created')),
      ideaId TEXT NOT NULL,
      contentHash TEXT NOT NULL,
      hashVersion TEXT NOT NULL,
      productionHash TEXT,
      currentEvaluationId TEXT,
      createdAt TEXT NOT NULL DEFAULT (datetime('now')),
      updatedAt TEXT NOT NULL DEFAULT (datetime('now')),
      UNIQUE(workspaceId, source, ideaId)
    );

    CREATE TABLE IF NOT EXISTS evaluations (
      evaluationId TEXT PRIMARY KEY,
      itemId TEXT NOT NULL REFERENCES content_items(itemId),
      contentHash TEXT NOT NULL,
      hashVersion TEXT NOT NULL,
      evaluationVersion TEXT NOT NULL,
      evaluationPolicyVersion TEXT NOT NULL,
      evaluationMode TEXT NOT NULL CHECK (evaluationMode IN ('offline', 'online')),
      overallScore INTEGER NOT NULL,
      rawScore INTEGER NOT NULL,
      scoreCapped INTEGER NOT NULL DEFAULT 0,
      verdict TEXT NOT NULL,
      dimensionScores TEXT NOT NULL,
      criticalFindings TEXT NOT NULL,
      majorFindings TEXT NOT NULL,
      minorFindings TEXT NOT NULL,
      suggestions TEXT NOT NULL,
      improvedHook TEXT,
      storyImprovements TEXT,
      improvedCaption TEXT,
      evaluatedAt TEXT NOT NULL,
      evaluationEngine TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS approvals (
      approvalId TEXT PRIMARY KEY,
      itemId TEXT NOT NULL REFERENCES content_items(itemId),
      evaluationId TEXT NOT NULL REFERENCES evaluations(evaluationId),
      approvalStatus TEXT NOT NULL CHECK (approvalStatus IN ('approved', 'rejected', 'revoked')),
      contentHashAtApproval TEXT NOT NULL,
      hashVersionAtApproval TEXT NOT NULL,
      evaluationPolicyVersionAtApproval TEXT NOT NULL,
      approvedAt TEXT,
      approvedBy TEXT,
      reason TEXT,
      UNIQUE(itemId, evaluationId)
    );

    CREATE TABLE IF NOT EXISTS events (
      changeSequence INTEGER PRIMARY KEY AUTOINCREMENT,
      eventId TEXT UNIQUE NOT NULL,
      eventType TEXT NOT NULL CHECK (eventType IN (
        'content_created', 'content_updated',
        'evaluation_created', 'evaluation_updated',
        'approved', 'rejected', 'revoked',
        'invalidated', 'archived', 'unarchived'
      )),
      itemId TEXT NOT NULL REFERENCES content_items(itemId),
      evaluationId TEXT REFERENCES evaluations(evaluationId),
      previousState TEXT,
      newState TEXT,
      changedAt TEXT NOT NULL,
      changedBy TEXT
    );

    CREATE INDEX IF NOT EXISTS idx_events_item ON events(itemId);
    CREATE INDEX IF NOT EXISTS idx_events_seq ON events(changeSequence);
    CREATE INDEX IF NOT EXISTS idx_evals_item ON evaluations(itemId);
    CREATE INDEX IF NOT EXISTS idx_evals_hash ON evaluations(contentHash);
    CREATE INDEX IF NOT EXISTS idx_approvals_item ON approvals(itemId);
  `);
}

/**
 * Generate a UUID v4.
 */
function generateId() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0;
    const v = c === 'x' ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
}

/**
 * Create or get a content item.
 */
function upsertContentItem({ workspaceId, source, ideaId, contentHash, hashVersion, productionHash }) {
  const existing = dbGet(
    `SELECT * FROM content_items WHERE workspaceId = ? AND source = ? AND ideaId = ?`,
    workspaceId, source, ideaId
  );

  if (existing) {
    dbRun(
      `UPDATE content_items SET contentHash = ?, hashVersion = ?, productionHash = ?, updatedAt = datetime('now') WHERE itemId = ?`,
      contentHash, hashVersion, productionHash, existing.itemId
    );
    return { itemId: existing.itemId, created: false };
  }

  const itemId = generateId();
  dbRun(
    `INSERT INTO content_items (itemId, workspaceId, source, ideaId, contentHash, hashVersion, productionHash)
     VALUES (?, ?, ?, ?, ?, ?, ?)`,
    itemId, workspaceId, source, ideaId, contentHash, hashVersion, productionHash
  );
  return { itemId, created: true };
}

/**
 * Get content item by itemId.
 */
function getContentItem(itemId) {
  return dbGet(`SELECT * FROM content_items WHERE itemId = ?`, itemId);
}

/**
 * Get content item by workspaceId, source, ideaId.
 */
function getContentItemByIdentity({ workspaceId, source, ideaId }) {
  return dbGet(
    `SELECT * FROM content_items WHERE workspaceId = ? AND source = ? AND ideaId = ?`,
    workspaceId, source, ideaId
  );
}

/**
 * Insert an evaluation record.
 */
function insertEvaluation({
  itemId,
  contentHash,
  hashVersion,
  evaluationVersion,
  evaluationPolicyVersion,
  evaluationMode,
  overallScore,
  rawScore,
  scoreCapped,
  verdict,
  dimensionScores,
  criticalFindings,
  majorFindings,
  minorFindings,
  suggestions,
  improvedHook,
  storyImprovements,
  improvedCaption,
  evaluatedAt,
  evaluationEngine,
}) {
  const evaluationId = generateId();
  dbRun(
    `INSERT INTO evaluations (
      evaluationId, itemId, contentHash, hashVersion, evaluationVersion,
      evaluationPolicyVersion, evaluationMode, overallScore, rawScore, scoreCapped,
      verdict, dimensionScores, criticalFindings, majorFindings, minorFindings,
      suggestions, improvedHook, storyImprovements, improvedCaption,
      evaluatedAt, evaluationEngine
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    evaluationId, itemId, contentHash, hashVersion, evaluationVersion,
    evaluationPolicyVersion, evaluationMode, overallScore, rawScore, scoreCapped,
    verdict, JSON.stringify(dimensionScores), JSON.stringify(criticalFindings),
    JSON.stringify(majorFindings), JSON.stringify(minorFindings), JSON.stringify(suggestions),
    improvedHook, storyImprovements, improvedCaption, evaluatedAt, evaluationEngine
  );
  return evaluationId;
}

/**
 * Get latest evaluation for an item.
 */
function getLatestEvaluation(itemId) {
  return dbGet(
    `SELECT * FROM evaluations WHERE itemId = ? ORDER BY evaluatedAt DESC LIMIT 1`,
    itemId
  );
}

/**
 * Get evaluation by ID.
 */
function getEvaluationById(evaluationId) {
  return dbGet(`SELECT * FROM evaluations WHERE evaluationId = ?`, evaluationId);
}

/**
 * Get evaluation history for an item.
 */
function getEvaluationHistory(itemId) {
  return dbAll(
    `SELECT * FROM evaluations WHERE itemId = ? ORDER BY evaluatedAt DESC`,
    itemId
  );
}

/**
 * Insert or update approval for an item + evaluation.
 */
function upsertApproval({
  itemId,
  evaluationId,
  approvalStatus,
  contentHashAtApproval,
  hashVersionAtApproval,
  evaluationPolicyVersionAtApproval,
  approvedBy,
  reason,
}) {
  const existing = dbGet(
    `SELECT * FROM approvals WHERE itemId = ? AND evaluationId = ?`,
    itemId, evaluationId
  );

  const now = new Date().toISOString();

  if (existing) {
    dbRun(
      `UPDATE approvals SET approvalStatus = ?, approvedAt = COALESCE(?, approvedAt),
        approvedBy = COALESCE(?, approvedBy), reason = COALESCE(?, reason)
       WHERE itemId = ? AND evaluationId = ?`,
      approvalStatus, approvalStatus === 'approved' ? now : null, approvedBy, reason, itemId, evaluationId
    );
    return { approvalId: existing.approvalId, created: false };
  }

  const approvalId = generateId();
  dbRun(
    `INSERT INTO approvals (approvalId, itemId, evaluationId, approvalStatus,
      contentHashAtApproval, hashVersionAtApproval, evaluationPolicyVersionAtApproval,
      approvedAt, approvedBy, reason)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    approvalId, itemId, evaluationId, approvalStatus,
    contentHashAtApproval, hashVersionAtApproval, evaluationPolicyVersionAtApproval,
    approvalStatus === 'approved' ? now : null, approvedBy, reason
  );
  return { approvalId, created: true };
}

/**
 * Get current approval for an item.
 */
function getCurrentApproval(itemId) {
  return dbGet(
    `SELECT a.*, e.evaluationVersion, e.evaluationPolicyVersion, e.evaluationMode,
            e.overallScore, e.verdict, e.evaluatedAt
     FROM approvals a
     JOIN evaluations e ON a.evaluationId = e.evaluationId
     WHERE a.itemId = ?
     ORDER BY a.approvedAt DESC NULLS LAST, a.approvalId DESC LIMIT 1`,
    itemId
  );
}

/**
 * Insert an event record.
 */
function insertEvent({
  eventId,
  eventType,
  itemId,
  evaluationId = null,
  previousState = null,
  newState = null,
  changedAt,
  changedBy,
}) {
  dbRun(
    `INSERT INTO events (eventId, eventType, itemId, evaluationId, previousState, newState, changedAt, changedBy)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
    eventId, eventType, itemId, evaluationId,
    previousState ? JSON.stringify(previousState) : null,
    newState ? JSON.stringify(newState) : null,
    changedAt, changedBy
  );
}

/**
 * Get events since a changeSequence (exclusive).
 */
function getEventsSince({ since = 0, limit = 100, itemId = null, eventType = null }) {
  let query = `SELECT * FROM events WHERE changeSequence > ?`;
  const params = [since];

  if (itemId) {
    query += ` AND itemId = ?`;
    params.push(itemId);
  }
  if (eventType) {
    query += ` AND eventType = ?`;
    params.push(eventType);
  }

  query += ` ORDER BY changeSequence ASC LIMIT ?`;
  params.push(limit);

  const rows = dbAll(query, ...params);
  const snapshotRow = dbGet(`SELECT MAX(changeSequence) as maxSeq FROM events`);
  const maxSeq = snapshotRow.maxSeq || 0;

  return {
    events: rows,
    nextSince: rows.length > 0 ? rows[rows.length - 1].changeSequence : since,
    hasMore: rows.length === limit,
    snapshotUpperBound: maxSeq,
  };
}

/**
 * Get all events (for testing only).
 */
function getAllEvents() {
  return dbAll(`SELECT * FROM events ORDER BY changeSequence ASC`);
}

/**
 * Reset all data (for testing only).
 */
function resetAll() {
  db.exec(`DELETE FROM events`);
  db.exec(`DELETE FROM approvals`);
  db.exec(`DELETE FROM evaluations`);
  db.exec(`DELETE FROM content_items`);
  db.exec(`DELETE FROM sqlite_sequence WHERE name = 'events'`);
}

module.exports = {
  openDb,
  closeDb,
  createSchema,
  generateId,
  dbAll,
  dbGet,
  dbRun,
  upsertContentItem,
  getContentItem,
  getContentItemByIdentity,
  insertEvaluation,
  getLatestEvaluation,
  getEvaluationById,
  getEvaluationHistory,
  upsertApproval,
  getCurrentApproval,
  insertEvent,
  getEventsSince,
  getAllEvents,
  resetAll,
};
