'use strict';

const fs = require('fs');
const path = require('path');
const os = require('os');

const ROOT = path.resolve(__dirname, '..');
const DATA_DIR = path.join(ROOT, 'data');
const BACKUP_DIR = path.join(DATA_DIR, 'backups');
const REPAIR_HISTORY_DIR = path.join(DATA_DIR, 'repair_history');
const SOURCE_JSON_PATH = path.resolve(ROOT, '..', '..', 'assets', 'data', 'content_ideas.json');

let writeLock = false;
const writeQueue = [];

function ensureDirs() {
  if (!fs.existsSync(DATA_DIR)) fs.mkdirSync(DATA_DIR, { recursive: true });
  if (!fs.existsSync(BACKUP_DIR)) fs.mkdirSync(BACKUP_DIR, { recursive: true });
  if (!fs.existsSync(REPAIR_HISTORY_DIR)) fs.mkdirSync(REPAIR_HISTORY_DIR, { recursive: true });
}

function acquireLock() {
  return new Promise((resolve) => {
    const check = () => {
      if (!writeLock) {
        writeLock = true;
        resolve();
      } else {
        setTimeout(check, 50);
      }
    };
    check();
  });
}

function releaseLock() {
  writeLock = false;
  if (writeQueue.length > 0) {
    const next = writeQueue.shift();
    next.resolve();
  }
}

function withLock(fn) {
  return acquireLock().then(() => {
    try {
      return Promise.resolve(fn()).then((result) => {
        releaseLock();
        return result;
      }).catch((err) => {
        releaseLock();
        throw err;
      });
    } catch (err) {
      releaseLock();
      throw err;
    }
  });
}

function timestamp() {
  const now = new Date();
  return now.toISOString().replace(/[:.]/g, '-');
}

function createBackup() {
  ensureDirs();
  const raw = fs.readFileSync(SOURCE_JSON_PATH, 'utf8');
  const backupName = `content_ideas.${timestamp()}.bak.json`;
  const backupPath = path.join(BACKUP_DIR, backupName);
  fs.writeFileSync(backupPath, raw, 'utf8');
  return backupPath;
}

function listBackups() {
  ensureDirs();
  const files = fs.readdirSync(BACKUP_DIR).filter(f => f.endsWith('.bak.json')).sort().reverse();
  return files.map(f => {
    const p = path.join(BACKUP_DIR, f);
    const stat = fs.statSync(p);
    return {
      filename: f,
      path: p,
      size: stat.size,
      createdAt: stat.birthtimeMs || stat.mtimeMs,
    };
  });
}

function saveRepairHistory(record) {
  ensureDirs();
  const fileName = `${record.ideaId}_${timestamp()}.json`;
  const filePath = path.join(REPAIR_HISTORY_DIR, fileName);
  fs.writeFileSync(filePath, JSON.stringify(record, null, 2), 'utf8');
  return filePath;
}

function getRepairHistory(ideaId) {
  ensureDirs();
  if (!fs.existsSync(REPAIR_HISTORY_DIR)) return [];
  const files = fs.readdirSync(REPAIR_HISTORY_DIR)
    .filter(f => f.startsWith(`${ideaId}_`) && f.endsWith('.json'))
    .sort()
    .reverse();
  return files.map(f => {
    try {
      return JSON.parse(fs.readFileSync(path.join(REPAIR_HISTORY_DIR, f), 'utf8'));
    } catch (e) {
      return null;
    }
  }).filter(Boolean);
}

function getRepairHistoryFile(ideaId, timestampStr) {
  ensureDirs();
  const fileName = `${ideaId}_${timestampStr}.json`;
  const filePath = path.join(REPAIR_HISTORY_DIR, fileName);
  if (!fs.existsSync(filePath)) return null;
  try {
    return JSON.parse(fs.readFileSync(filePath, 'utf8'));
  } catch (e) {
    return null;
  }
}

function atomicWriteJson(filePath, data) {
  const dir = path.dirname(filePath);
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  const tmpPath = filePath + `.tmp.${process.pid}.${Date.now()}`;
  fs.writeFileSync(tmpPath, JSON.stringify(data, null, 2), 'utf8');
  fs.renameSync(tmpPath, filePath);
}

function saveRepairedIdeaToSource(repairedIdea) {
  const data = JSON.parse(fs.readFileSync(SOURCE_JSON_PATH, 'utf8'));
  const ideaIndex = data.ideas.findIndex(i => i.id === repairedIdea.id);
  if (ideaIndex === -1) {
    throw new Error(`Idea ${repairedIdea.id} not found in source JSON`);
  }

  // Preserve ordering — replace in place at same index
  const updatedIdeas = [...data.ideas];
  updatedIdeas[ideaIndex] = repairedIdea;

  const updatedData = {
    ...data,
    ideas: updatedIdeas,
  };

  // Validate the complete resulting JSON before replacing
  const validation = validateCompleteJson(updatedData);
  if (!validation.valid) {
    throw new Error(`Resulting JSON validation failed: ${validation.error}`);
  }

  atomicWriteJson(SOURCE_JSON_PATH, updatedData);
  return updatedData;
}

function validateCompleteJson(data) {
  if (!data || typeof data !== 'object' || Array.isArray(data)) {
    return { valid: false, error: 'Top-level value is not an object' };
  }
  if (!Array.isArray(data.ideas)) {
    return { valid: false, error: 'Missing ideas array' };
  }
  const ids = new Set();
  for (const idea of data.ideas) {
    if (!idea || typeof idea !== 'object') {
      return { valid: false, error: 'Idea is not an object' };
    }
    if (typeof idea.id !== 'string' || idea.id.trim().length === 0) {
      return { valid: false, error: 'Idea missing valid id' };
    }
    if (ids.has(idea.id)) {
      return { valid: false, error: `Duplicate idea ID: ${idea.id}` };
    }
    ids.add(idea.id);
  }
  return { valid: true };
}

function restoreIdeaFromBackup(backupPath) {
  if (!fs.existsSync(backupPath)) {
    throw new Error(`Backup file not found: ${backupPath}`);
  }
  const raw = fs.readFileSync(backupPath, 'utf8');
  const data = JSON.parse(raw);
  const validation = validateCompleteJson(data);
  if (!validation.valid) {
    throw new Error(`Backup JSON validation failed: ${validation.error}`);
  }
  atomicWriteJson(SOURCE_JSON_PATH, data);
  return data;
}

module.exports = {
  ensureDirs,
  withLock,
  createBackup,
  listBackups,
  saveRepairHistory,
  getRepairHistory,
  getRepairHistoryFile,
  atomicWriteJson,
  saveRepairedIdeaToSource,
  validateCompleteJson,
  restoreIdeaFromBackup,
  SOURCE_JSON_PATH,
  BACKUP_DIR,
  REPAIR_HISTORY_DIR,
};
