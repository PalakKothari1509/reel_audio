# Workflow Review

## Checklist
1. Flutter SDK version explicitly pinned: YES (flutter-version: '3.24.5', channel: 'stable')
2. Dependencies installed reproducibly: YES (flutter pub get with cache)
3. Exporter executes: YES (dart run scripts/export_content_ideas.dart)
4. JSON generated from actual Dart source: YES (uses existing exporter which imports lib/content_ideas.dart and uses kDefaultHooks/toJson)
5. Independent field-by-field validation: PARTIAL - validate_content_ideas.js checks structure/counts/fields/IDs but does NOT do deep field-by-field comparison against original Dart objects; it only validates the generated JSON. Needs enhancement for true independent comparison.
6. Archived records and all 117 unique IDs checked: The exporter enforces 117 records/unique IDs; validator checks count and uniqueness and specific IDs. Archived records are included by exporter (all kDefaultHooks). ✓
7. CI fails on validation failure: YES - default behavior of shell steps (non-zero exit fails job). Both dart run and node scripts will fail on errors. ✓
8. JSON uploaded as artifact: YES (actions/upload-artifact@v4) ✓
9. Logs distinguish export vs validation failure: YES - separate steps 'Run exporter' and 'Validate JSON' with clear names ✓

## Weaknesses
- **No independent comparison**: Validator doesn't compare against original Dart source representation - it's self-validating. Need to enhance validator to load original data independently or have exporter write a comparison report.
- **No explicit field-by-field check**: Validator checks field presence (31 fields) but doesn't verify values match originals
- **No test execution**: Doesn't run relevant tests (category_guard_test etc.)
- **Version pinning**: Flutter 3.24.5 pinned but might need compatibility verification with pubspec constraints
- **No verification of 34 constructor params vs serialized fields**: Gap in validation

## Exact Steps to Execute
1. Commit and push .github/workflows/export_content_ideas.yml to repo
2. Go to Actions tab in GitHub
3. Select 'Export Content Ideas JSON' workflow
4. Click 'Run workflow' (workflow_dispatch) or push changes to trigger
5. Monitor logs for export vs validation steps
6. Download artifact 'content-ideas-json' from completed run
7. Verify JSON exists with 117 records

**Status:** Workflow prepared but needs enhancement for true independent validation. Cannot claim PASS without successful run.

