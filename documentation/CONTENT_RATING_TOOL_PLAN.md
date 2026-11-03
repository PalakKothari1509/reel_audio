# Content Rating Tool — Plan

**Status:** Planned — not yet implemented  
**Location:** `documentation/CONTENT_RATING_TOOL_PLAN.md`  
**Relationship to Flutter app:** Completely separate — a standalone browser-based tool

---

## Purpose

A standalone Content Rating Tool accessible through a laptop browser that evaluates built-in content ideas from `content_ideas.json`. It remains separate from the existing Flutter application and must not modify any Flutter code, JSON records, or existing workflows.

## Proposed Architecture

### Browser Frontend
- HTML, CSS, JavaScript — no build step, runs in any modern browser
- Accessed via `localhost` on the developer's laptop
- Import existing `content_ideas.json` from the Flutter project

### Lightweight Local Backend
- Secures Gemini API key (never exposed in browser code)
- Proxies Gemini requests from the frontend
- Handles API key rotation and quota management

### Data Flow
```
content_ideas.json (Flutter project) → Browser Tool Import → Rating → JSON/CSV Export
```

### Strict Separation
The browser tool must **not**:
- Modify Flutter screens or Dart business logic
- Modify the `HookIdea` model or `lib/content_ideas.dart`
- Change existing idea records in `assets/data/content_ideas.json`
- Change JSON migration implementation
- Automatically write scores to Flutter data stores (`hooks.json`, `content_library.json`, etc.)
- Expose Gemini credentials in browser code

JSON and CSV report exports are stored separately from the Flutter app's data directory.

---

## Ten Rating Dimensions

| Dimension | Weight |
|-----------|--------:|
| Hook Strength | 15% |
| Relatability | 15% |
| Story Structure | 12% |
| Age Appropriateness | 10% |
| Hinglish Naturalness | 10% |
| Character Consistency | 8% |
| Visual Feasibility | 8% |
| Sound-Off Readability | 7% |
| Engagement Potential | 8% |
| Brand and Safety | 7% |
| **Total** | **100%** |

## Verdict Thresholds

| Score Range | Verdict |
|-------------|---------|
| 80–100 | Ready to Post |
| 65–79 | Needs Minor Fixes |
| 45–64 | Needs Major Rewrite |
| Below 45 | Reject |

## Critical Hard Rules

A score cap of **59** applies (i.e., maximum possible score is 59/100) when any Critical finding is present. Critical findings include:

1. Unsafe behaviour presented as good
2. Scary or violent toddler content
3. Character appearance contradicting actual character definitions (from `lib/characters.dart`)
4. No clear resolution
5. Preachy or lecture-style moral delivery
6. Child blame or shame in Safety content
7. Actual inappropriate touching shown in Safety content
8. Trusted adult failing to respond calmly
9. Scary or graphic language in Safety content

A short moral end card is allowed and does not trigger a Critical finding.

## Online and Offline Evaluation

### Online Mode
- Gemini evaluation via local backend proxy
- Structured JSON output expected from Gemini
- Response validation against expected schema
- One retry for invalid or malformed responses
- API key protected by the backend (never in browser)

### Offline Mode
- Deterministic rule-based evaluation (no API calls)
- Reuses existing quality-check logic from `lib/quality_check_center.dart` where appropriate
- Offline-generated results clearly identified as such
- Lower confidence scores flagged for online re-evaluation

## Planned Browser Features

1. **Import and browse ideas** — Load `content_ideas.json`, display all 117 built-in ideas
2. **Search and filter** — By ID, category, archived status, collection
3. **Individual idea evaluation** — Rate one idea across all 10 dimensions
4. **Content evaluation** — Hook, story, script, and complete-content evaluation modes
5. **Ten dimension scores** — Weighted scoring with per-dimension breakdown
6. **Findings and explanations** — Critical/Major/Minor/Suggestion findings with explanations
7. **Suggested improvements** — AI-generated suggestions for fixing failing dimensions
8. **Batch evaluation** — Evaluate multiple ideas with concurrency limits
9. **Retry failed evaluations** — Re-run failed Gemini calls
10. **JSON and CSV exports** — Download rating reports

## Testing Requirements

Planned tests (not yet written):

- **JSON import** — Load `content_ideas.json`, verify 117 records parsed correctly
- **Missing and malformed fields** — Handle ideas with missing `archived`, `defaultCast`, `pinnedComment`, etc.
- **Weighted scoring** — Verify dimension weights sum to 100%, scores calculated correctly
- **Verdict thresholds** — Verify score-to-verdict mapping at boundaries (80, 65, 45)
- **Hard-rule caps** — Verify score cap of 59 when Critical findings present
- **Gemini parsing and validation** — Verify JSON response schema validation, retry logic
- **Offline determinism** — Verify same inputs produce same offline scores
- **Character consistency** — Verify character names match `lib/characters.dart` definitions
- **Safety checks** — Verify all 9 Critical hard rules fire correctly
- **Batch evaluation** — Verify concurrency limits respected
- **Export integrity** — Verify JSON/CSV exports contain all rated ideas with correct scores

## Data Integrity

The tool treats `content_ideas.json` as **read-only input**. It does not modify the file. Any ratings, scores, or findings are stored in separate export files only.

## Implementation Notes

- This document is a **plan only** — no implementation has been started
- The browser tool is **not part of** the Flutter application repository's runtime
- It may live in a separate directory or repository
- All Flutter app functionality, tests, and CI workflows remain unchanged