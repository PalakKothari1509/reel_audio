#!/usr/bin/env node
'use strict';

/**
 * Legacy rating migration script.
 *
 * Migrates existing JSON rating files from data/ratings/ into the SQLite
 * database. Original files are never modified or deleted.
 *
 * Usage: node migrate.js [ratingsDir] [dbPath]
 *
 *   ratingsDir - directory containing idea_*.json rating files (default:
 *                tools/content_rating_web/data/ratings/)
 *   dbPath     - path to SQLite database (default:
 *                tools/content_rating_web/data/evaluations.db)
 */

const fs = require('fs');
const path = require('path');
const { openDb, closeDb, upsertContentItem, insertEvaluation, upsertApproval, insertEvent, generateId, resetAll } = require('./db');
const { computeHashes } = require('./hash');

const DEFAULT_RATINGS_DIR = path.resolve(__dirname, '..', 'data', 'ratings');
const DEFAULT_DB_PATH = path.resolve(__dirname, '..', 'data', 'evaluations.db');

const EVALUATION_VERSION = '1.2.0-offline';
const EVALUATION_POLICY_VERSION = '1.0.0';
const EVALUATION_MODE = 'offline';
const EVALUATION_ENGINE = 'offline';

function isValidRating(obj) {
  return (
    obj &&
    typeof obj === 'object' &&
    typeof obj.ideaId === 'string' &&
    obj.ideaId.trim().length > 0 &&
    Array.isArray(obj.dimensionScores) &&
    typeof obj.overallScore === 'number' &&
    typeof obj.verdict === 'string'
  );
}

async function migrate({ ratingsDir = DEFAULT_RATINGS_DIR, dbPath = DEFAULT_DB_PATH, dryRun = false, reset = false } = {}) {
  if (!fs.existsSync(ratingsDir)) {
    console.log(`Ratings directory not found: ${ratingsDir}`);
    return { imported: 0, skipped: 0, failed: 0, errors: [] };
  }

  const files = fs.readdirSync(ratingsDir).filter((f) => f.endsWith('.json'));
  console.log(`Found ${files.length} rating files in ${ratingsDir}`);

  let imported = 0;
  let skipped = 0;
  let failed = 0;
  const errors = [];

  if (!dryRun) {
    await openDb(dbPath);
    if (reset) {
      await resetAll();
      console.log('Database reset.');
    }
  }

  for (const file of files) {
    const filePath = path.join(ratingsDir, file);
    let raw;
    try {
      raw = fs.readFileSync(filePath, 'utf8');
    } catch (e) {
      failed++;
      errors.push({ file, error: `Cannot read: ${e.message}` });
      continue;
    }

    let rating;
    try {
      rating = JSON.parse(raw);
    } catch (e) {
      failed++;
      errors.push({ file, error: `Invalid JSON: ${e.message}` });
      continue;
    }

    if (!isValidRating(rating)) {
      skipped++;
      errors.push({ file, error: 'Invalid rating structure' });
      continue;
    }

    // Build a minimal HookIdea-like object from the rating's ideaId
    // We don't have the full content, so we use what's available
    const content = {
      id: rating.ideaId,
      category: rating.category || '',
      title: rating.title || '',
      cover: rating.cover || '',
      opening: rating.opening || '',
      problem: rating.problem || '',
      lesson: rating.lesson || '',
      storyDetail: rating.storyDetail || '',
      endingBeat: rating.endingBeat || '',
      caption: rating.caption || '',
      pinnedComment: rating.pinnedComment || '',
      dialogue: rating.dialogue || '',
      defaultCast: rating.defaultCast || [],
      category: rating.category || '',
      setting: rating.setting || '',
      sceneDetail: rating.sceneDetail || '',
      postFormat: rating.postFormat || 'Reel',
      strategy: rating.strategy || '',
      mess: rating.mess || '',
      innerThought: rating.innerThought || '',
      keepMoralOffScreen: rating.keepMoralOffScreen || false,
      quote: rating.quote || '',
      detail: rating.detail || '',
      punchline: rating.punchline || '',
      readyPrompt: rating.readyPrompt || '',
      forApp: rating.forApp !== undefined ? rating.forApp : true,
    };

    const { contentHash, productionHash, hashVersion } = computeHashes(content);

    if (dryRun) {
      imported++;
      continue;
    }

    try {
      // Create content item
      const { itemId } = await upsertContentItem({
        workspaceId: 'default',
        source: 'built_in',
        ideaId: rating.ideaId,
        contentHash,
        hashVersion,
        productionHash,
      });

      // Insert evaluation
      const evaluationId = await insertEvaluation({
        itemId,
        contentHash,
        hashVersion,
        evaluationVersion: EVALUATION_VERSION,
        evaluationPolicyVersion: EVALUATION_POLICY_VERSION,
        evaluationMode: EVALUATION_MODE,
        overallScore: rating.overallScore,
        rawScore: rating.rawScore || rating.overallScore,
        scoreCapped: rating.scoreCapped ? 1 : 0,
        verdict: rating.verdict,
        dimensionScores: rating.dimensionScores || [],
        criticalFindings: rating.criticalFindings || [],
        majorFindings: rating.majorFindings || [],
        minorFindings: rating.minorFindings || [],
        suggestions: rating.suggestions || [],
        improvedHook: rating.improvedHook || null,
        storyImprovements: rating.storyImprovements || null,
        improvedCaption: rating.improvedCaption || null,
        evaluatedAt: rating.evaluatedAt || new Date().toISOString(),
        evaluationEngine: EVALUATION_ENGINE,
      });

      // Insert event
      await insertEvent({
        eventId: generateId(),
        eventType: 'evaluation_created',
        itemId,
        evaluationId,
        previousState: null,
        newState: { verdict: rating.verdict, overallScore: rating.overallScore },
        changedAt: rating.evaluatedAt || new Date().toISOString(),
        changedBy: 'migration',
      });

      // Mark as evaluated (not approved) - legacy records are NOT auto-approved
      await upsertApproval({
        itemId,
        evaluationId,
        approvalStatus: 'evaluated',
        contentHashAtApproval: contentHash,
        hashVersionAtApproval: hashVersion,
        evaluationPolicyVersionAtApproval: EVALUATION_POLICY_VERSION,
        approvedBy: null,
        reason: 'Migrated from legacy JSON rating',
      });

      imported++;
    } catch (e) {
      failed++;
      errors.push({ file, error: e.message });
    }
  }

  if (!dryRun) {
    await closeDb();
  }

  console.log(`Migration complete: ${imported} imported, ${skipped} skipped, ${failed} failed`);
  if (errors.length > 0) {
    console.log('Errors:');
    for (const err of errors) {
      console.log(`  ${err.file}: ${err.error}`);
    }
  }

  return { imported, skipped, failed, errors };
}

if (require.main === module) {
  const args = process.argv.slice(2);
  let ratingsDir = DEFAULT_RATINGS_DIR;
  let dbPath = DEFAULT_DB_PATH;
  let dryRun = false;
  let reset = false;

  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--dry-run') dryRun = true;
    else if (args[i] === '--reset') reset = true;
    else if (!ratingsDir || args[i - 1] === '--ratings-dir') ratingsDir = args[i];
    else if (!dbPath || args[i - 1] === '--db-path') dbPath = args[i];
  }

  migrate({ ratingsDir, dbPath, dryRun, reset }).catch((e) => {
    console.error('Migration failed:', e);
    process.exit(1);
  });
}

module.exports = { migrate };
