# CI Execution Plan

## Reproducible Workflow
Created .github/workflows/export_content_ideas.yml using:
- ctions/checkout@v4
- subosito/flutter-action@v2 with Flutter 3.24.5 stable
- Isolated Ubuntu runner (no local SDK modification)
- Steps: pub get → dart run scripts/export_content_ideas.dart → node scripts/validate_content_ideas.js → verification → artifact upload

## Execution Instructions
1. Push to GitHub or trigger workflow_dispatch on the repo
2. Workflow will generate ssets/data/content_ideas.json using the existing exporter
3. Download artifact content-ideas-json and place in ssets/data/

## Status
- Workflow prepared
- Local execution blocked by SDK environment issues
- No JSON generated locally
- Phase 1 remains BLOCKED pending CI execution

