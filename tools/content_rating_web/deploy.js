#!/usr/bin/env node
/**
 * deploy.js — Deployment packaging for the content rating web backend.
 *
 * Copies the single source-of-truth shared evaluation spec from the repository
 * root into the backend directory so it is available when the backend is
 * deployed standalone (outside the monorepo).
 *
 * The shared file at shared/evaluation/evaluation_rules.json remains the only
 * maintained copy. This script produces a build-time artifact copy at
 * tools/content_rating_web/backend/evaluation_rules.json which schemas.js
 * resolves to when the repo-relative path is unavailable.
 */

const fs = require('fs');
const path = require('path');

const REPO_ROOT = path.resolve(__dirname, '../..');
const SHARED_SPEC = path.join(REPO_ROOT, 'shared/evaluation/evaluation_rules.json');
const BACKEND_DIR = path.resolve(__dirname, 'backend');
const DEPLOY_SPEC = path.join(BACKEND_DIR, 'evaluation_rules.json');

function main() {
  if (!fs.existsSync(SHARED_SPEC)) {
    console.error(`ERROR: Shared evaluation spec not found at ${SHARED_SPEC}`);
    process.exit(1);
  }

  // Verify the shared spec is valid JSON before copying
  let spec;
  try {
    const raw = fs.readFileSync(SHARED_SPEC, 'utf8');
    spec = JSON.parse(raw);
  } catch (e) {
    console.error(`ERROR: Shared evaluation spec is invalid JSON: ${e.message}`);
    process.exit(1);
  }

  if (!spec || !Array.isArray(spec.dimensions)) {
    console.error('ERROR: Shared evaluation spec is missing spec.dimensions');
    process.exit(1);
  }

  fs.copyFileSync(SHARED_SPEC, DEPLOY_SPEC);
  console.log(`Deploy: copied ${SHARED_SPEC} -> ${DEPLOY_SPEC}`);
  console.log(`Deploy: ${spec.dimensions.length} dimensions, weights total ${spec.dimensions.reduce((s, d) => s + d.weight, 0)}`);
}

main();
