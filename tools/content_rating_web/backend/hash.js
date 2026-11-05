'use strict';

const crypto = require('crypto');

/**
 * Canonical hashing module for HookIdea content.
 *
 * HookIdea has exactly 31 fields. This module computes two hashes:
 *
 * 1. contentHash (22 creative fields) — invalidates creative approval when changed.
 * 2. productionHash (24 fields) — invalidates production eligibility when changed.
 *
 * Excluded from both hashes:
 *   - archived (availability only)
 *   - id, custom, usedOn (identity/metadata)
 *   - score, band, reviewedOn (derived evaluation data)
 *
 * Canonicalization contract:
 *   - Fixed field allowlists
 *   - Alphabetically sorted top-level keys
 *   - Recursively sorted nested object keys
 *   - Omit null, missing and undefined values
 *   - Preserve empty strings
 *   - Preserve array order
 *   - Recursively canonicalize array elements
 *   - Normalize strings to Unicode NFC
 *   - Serialize as compact JSON
 *   - Encode as UTF-8
 *   - SHA-256, lowercase hexadecimal output
 *
 * hashVersion is separate metadata, not part of the hash input.
 */

const HASH_VERSION = '1.0.0';

const CREATIVE_FIELDS = [
  'caption',
  'category',
  'cover',
  'defaultCast',
  'dialogue',
  'endingBeat',
  'keepMoralOffScreen',
  'lesson',
  'mess',
  'opening',
  'pinnedComment',
  'postFormat',
  'problem',
  'punchline',
  'quote',
  'sceneDetail',
  'setting',
  'strategy',
  'storyDetail',
  'title',
  'innerThought',
  'detail',
];

const PRODUCTION_FIELDS = [...CREATIVE_FIELDS, 'forApp', 'readyPrompt'];

/**
 * Recursively canonicalize a value.
 * - Objects: keys sorted alphabetically, values recursively canonicalized
 * - Arrays: order preserved, elements recursively canonicalized
 * - Strings: Unicode NFC normalized
 * - null/undefined: omitted (handled at object level)
 * - Booleans/numbers: JSON native
 */
function canonicalize(value) {
  if (value === null || value === undefined) {
    return value;
  }

  if (Array.isArray(value)) {
    return value.map((item) => canonicalize(item));
  }

  if (typeof value === 'object') {
    const result = {};
    for (const key of Object.keys(value).sort()) {
      const val = value[key];
      if (val === null || val === undefined) {
        continue;
      }
      result[key] = canonicalize(val);
    }
    return result;
  }

  if (typeof value === 'string') {
    return value.normalize('NFC');
  }

  return value;
}

/**
 * Build a canonical object from a HookIdea-like object using a field allowlist.
 * Only fields present in the allowlist and present in the source are included.
 * Null/undefined/missing values are omitted.
 */
function buildCanonicalObject(source, fieldAllowlist) {
  const obj = {};
  for (const field of fieldAllowlist) {
    if (field in source) {
      const val = source[field];
      if (val !== null && val !== undefined) {
        obj[field] = canonicalize(val);
      }
    }
  }
  return obj;
}

/**
 * Compute SHA-256 hash of a canonical object.
 */
function hashCanonicalObject(canonicalObj) {
  const serialized = JSON.stringify(canonicalObj);
  const utf8Bytes = Buffer.from(serialized, 'utf8');
  return crypto.createHash('sha256').update(utf8Bytes).digest('hex');
}

/**
 * Compute the creative approval contentHash from a HookIdea-like object.
 * Returns { contentHash, hashVersion }.
 */
function computeContentHash(hookIdea) {
  const canonicalObj = buildCanonicalObject(hookIdea, CREATIVE_FIELDS);
  return {
    contentHash: hashCanonicalObject(canonicalObj),
    hashVersion: HASH_VERSION,
  };
}

/**
 * Compute the production productionHash from a HookIdea-like object.
 * Returns { productionHash, hashVersion }.
 */
function computeProductionHash(hookIdea) {
  const canonicalObj = buildCanonicalObject(hookIdea, PRODUCTION_FIELDS);
  return {
    productionHash: hashCanonicalObject(canonicalObj),
    hashVersion: HASH_VERSION,
  };
}

/**
 * Compute both hashes from a HookIdea-like object.
 * Returns { contentHash, productionHash, hashVersion }.
 */
function computeHashes(hookIdea) {
  const content = computeContentHash(hookIdea);
  const production = computeProductionHash(hookIdea);
  return {
    contentHash: content.contentHash,
    productionHash: production.productionHash,
    hashVersion: content.hashVersion,
  };
}

/**
 * Get the list of creative hash fields.
 */
function getCreativeHashFields() {
  return [...CREATIVE_FIELDS];
}

/**
 * Get the list of production hash fields.
 */
function getProductionHashFields() {
  return [...PRODUCTION_FIELDS];
}

/**
 * Get the list of fields excluded from both hashes.
 */
function getExcludedFields() {
  return {
    availability: ['archived'],
    identity: ['id', 'custom', 'usedOn'],
    derived: ['score', 'band', 'reviewedOn'],
  };
}

module.exports = {
  HASH_VERSION,
  CREATIVE_FIELDS,
  PRODUCTION_FIELDS,
  computeContentHash,
  computeProductionHash,
  computeHashes,
  getCreativeHashFields,
  getProductionHashFields,
  getExcludedFields,
  buildCanonicalObject,
  canonicalize,
  hashCanonicalObject,
};
