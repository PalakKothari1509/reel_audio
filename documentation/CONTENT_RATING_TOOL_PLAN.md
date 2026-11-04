# Content Rating Tool — Documentation

**Status:** Implemented and operational  
**Location:** `tools/content_rating_web/`  
**Relationship to Flutter app:** Completely separate — a standalone browser-based utility that reads `assets/data/content_ideas.json` as read-only input and never modifies any Flutter code, JSON records, or existing workflows.

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Installation & Setup](#installation--setup)
4. [Running the Tool](#running-the-tool)
5. [Using the Tool](#using-the-tool)
6. [Content Rating Framework](#content-rating-framework)
7. [Critical Safety Rules](#critical-safety-rules)
8. [Offline vs Online Evaluation](#offline-vs-online-evaluation)
9. [Exporting Results](#exporting-results)
10. [Troubleshooting](#troubleshooting)
11. [Git & Commit Restrictions](#git--commit-restrictions)

---

## Overview

The Content Rating Tool is a standalone, browser-based application that evaluates the quality of content ideas created for the Instagram brand **Fun Learning With Palak**. It helps assess whether an idea:

- Has a strong hook
- Parents and children can relate to it
- Has an interesting and logically structured story
- Is appropriate for children aged 1–4
- Uses natural Hinglish language
- Uses characters consistently
- Can be converted into an effective vertical Reel
- Works for viewers watching without sound
- Has engagement potential
- Follows brand guidelines and child-safety requirements

The tool provides a score out of 100, detailed explanations, problems, improvement suggestions, and an overall verdict (Ready to Post / Needs Minor Fixes / Needs Major Rewrite / Reject).

**Important:** This is a separate browser-based utility. It is **NOT** a new Flutter application screen or module. No Flutter code, JSON records, or existing workflows are modified.

---

## Architecture

### Repository Structure

```
tools/content_rating_web/
├── server.js                 # Express backend (port 3001)
├── backend/
│   ├── ratingEngine.js       # Offline + online rating engine
│   ├── schemas.js            # Validation schemas + weighted scoring
│   └── storage.js            # File-based result storage
├── frontend/
│   ├── index.html            # Single-page UI
│   ├── css/style.css         # Responsive styles
│   └── js/
│       ├── app.js            # Main controller
│       ├── library.js        # Library view helpers
│       ├── rating.js         # Rating view helpers
│       └── export.js         # Export view helpers
├── data/
│   └── ratings/              # Saved rating results (created at runtime)
├── package.json
├── .env.example              # Copy to .env, add Gemini key
├── .gitignore
├── README.md
└── setup-hosts.ps1           # PowerShell script for hosts file setup
```

### Data Flow

```
assets/data/content_ideas.json (read-only)
    ↓
Browser loads ideas via HTTP/fetch from backend
    ↓
User selects idea → Content Library screen
    ↓
User clicks "Evaluate" → Backend evaluates (offline or online)
    ↓
Result displayed: score, verdict, findings, suggestions
    ↓
User can export results as JSON or CSV
```

---

## Installation & Setup

### Prerequisites

- **Node.js** v18 or higher
- **npm** (comes with Node.js)

### Step 1: Install Dependencies

```powershell
cd tools/content_rating_web
npm install
```

### Step 2: Configure Local Hostname (Recommended)

The tool is accessible at `http://localhost:3001`. For a cleaner URL, you can use `http://contentrating.local:3001` by adding an entry to your Windows hosts file:

1. Open PowerShell as Administrator
2. Run:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
   .\setup-hosts.ps1
   ```
   
   **OR manually:** Open `C:\Windows\System32\drivers\etc\hosts` as Administrator and add:
   ```
   127.0.0.1 contentrating.local
   ```

### Step 3: Configure Gemini API Key (Optional)

The tool works in **offline mode** without any API key. For online Gemini evaluation:

1. Copy `.env.example` to `.env`:
   ```powershell
   cp .env.example .env
   ```
2. Edit `.env` and add your Gemini API key:
   ```
   GEMINI_API_KEY=your_actual_api_key_here
   PORT=3001
   ```
3. The `.env` file is gitignored — your key will never be committed.

---

## Running the Tool

### Start the Backend Server

```powershell
cd tools/content_rating_web
npm start
```

Expected output:
```
Content Rating Tool backend running on http://localhost:3001
Gemini API key: configured   (or: not configured (offline mode only))
```

### Open the Browser

Navigate to:
- **Primary:** `http://localhost:3001`
- **Alternative:** `http://contentrating.local:3001` (after hosts file setup)

The dashboard loads automatically, showing all 117 built-in ideas from `assets/data/content_ideas.json`.

---

## Using the Tool

### Dashboard

The dashboard shows:
- Total ideas imported (117)
- Ideas evaluated vs not evaluated
- Breakdown by verdict (Ready to Post / Needs Minor Fixes / Needs Major Rewrite / Reject)
- A table of all rated ideas with scores and verdicts
- **Export JSON / Export CSV** buttons to download rating reports
- **Clear All Ratings** button to reset — deletes all saved rating records from `data/ratings/`

### Content Library

The Content Library displays all 117 imported ideas with:
- **Search** — Search by title, hook, or ID
- **Filter by Category** — Safety, Ria Chaos, Child Chaos, Funny, Learning Lesson, Navratri, Series, Diwali
- **Filter by Verdict** — Ready to Post / Needs Minor Fixes / Needs Major Rewrite / Reject
- **Filter by Status** — Evaluated / Not Evaluated / Evaluation Failed
- **Sort** by score or alphabetically

Each idea card shows the title, cover, opening hook, category, cast, and archived status.

### Individual Idea Evaluation

1. Click any idea card in the library to open the idea detail modal
2. Review the idea's details (title, cover, opening, problem, lesson, story detail, caption, cast, setting)
3. Click **"Evaluate This Idea"**
4. View the complete evaluation result with:
   - Overall score (0–100) and verdict
   - Ten dimension scores with explanations
   - Critical/Major/Minor/Suggestion findings
   - Suggested improvements (improved hook, caption, story)
5. Click **"Copy Result"** to copy the full evaluation to clipboard

### Batch Evaluation

1. Click **"Evaluate All Ideas"** on the dashboard
2. Or click **"Evaluate Unevaluated"** to only evaluate ideas not yet rated
3. Progress is shown via toast notifications
4. Each idea is evaluated sequentially with a small delay between requests
5. If an individual idea fails to evaluate, it is skipped and the batch continues with the next idea; the batch does not stop on error

### Re-evaluation

After making changes to `assets/data/content_ideas.json`, click **"Re-evaluate All Ideas"** to re-evaluate all ideas and overwrite existing ratings. Each idea is re-evaluated from scratch using the current source data. Existing ratings for each idea are overwritten — no backup or previous version is retained. Ratings for ideas that no longer exist in the source JSON remain in `data/ratings/` but will not appear in the Content Library UI.

---

## Content Rating Framework

### Ten Weighted Dimensions

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

### Score Calculation

Each dimension receives a score from 0 to 10. The overall score is calculated as:

```
Overall Score = Σ((Dimension Score / 10) × Dimension Weight)
```

The final score is rounded to a whole number.

### Verdict Thresholds

| Score Range | Verdict |
|-------------|---------|
| 80–100 | Ready to Post |
| 65–79 | Needs Minor Fixes |
| 45–64 | Needs Major Rewrite |
| 0–44 | Reject |

---

## Critical Safety Rules

If any critical violation is detected:

- A **Critical finding** is created with explanation, evidence, and suggested correction
- The overall score is **capped at 59** (regardless of calculated score)
- **No "Ready to Post" verdict** is allowed

### Critical Findings

1. **Unsafe behaviour presented as good** — Dangerous or unsafe actions depicted positively
2. **Scary or violent toddler content** — Content frightening or violent for ages 1–4
3. **Character appearance contradicting definitions** — Visual descriptions mismatch character library
4. **No clear resolution** — Story lacks a clear ending/resolution
5. **Preachy or lecture-style moral delivery** — Moral is heavy-handed rather than natural
6. **Child blame or shame in Safety content** — Child is blamed or shamed
7. **Actual inappropriate touching in Safety content** — Inappropriate physical contact depicted
8. **Trusted adult failing to respond calmly** — Adult caregiver reacts poorly to child's distress
9. **Graphic or frightening language in Safety content** — Scary language in safety context

A short moral end card is allowed and does **not** trigger a Critical finding.

---

## Offline vs Online Evaluation

### Offline Mode (Default)

- **No API key required**
- Deterministic rule-based evaluation
- Checks for missing fields, empty strings, missing resolution, missing moral, unsafe language, character consistency, visual feasibility, caption presence, etc.
- Results are labeled: `"Heuristic Evaluation — Offline"`
- Same input always produces same result (deterministic)

### Online Mode

- Requires `GEMINI_API_KEY` in `.env` file
- Uses Gemini via local backend proxy (API key never exposed to browser)
- Structured JSON output with validation against expected schema
- One retry for invalid/malformed responses
- Appropriate error handling for missing API key, network errors, rate limits, service errors, timeouts

**Important:** The Gemini API key is **never** exposed in browser code, HTML, local storage, session storage, exported reports, or frontend network configuration. All API calls go through the local backend.

---

## Exporting Results

### JSON Export

Click **"Export JSON"** on the dashboard to download `content_ideas.json` containing:
- All evaluated ideas with full detail
- Dimension scores, weighted scores, verdicts
- Findings and suggestions
- Evaluation metadata (mode, timestamp, version)

### CSV Export

Click **"Export CSV"** on the dashboard to download `content_ratings.csv` containing:
- Idea ID, Title, Category
- Overall Score, Verdict
- All ten dimension scores
- Critical/Major/Minor finding counts
- Evaluation mode, timestamp

### Export Options

- All results
- Selected results (via library filters)
- Results by category
- Results by verdict

**Important:** The original `assets/data/content_ideas.json` is **never modified**. All ratings are stored separately in `tools/content_rating_web/data/ratings/`.

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `contentrating.local` does not resolve | Add `127.0.0.1 contentrating.local` to `C:\Windows\System32\drivers\etc\hosts` as Administrator |
| Server not accessible | Run `npm start` in `tools/content_rating_web/`; check port 3001 isn't blocked by firewall |
| Port 3001 already in use | Change `PORT` in `.env` to a different port (e.g., 3002) |
| Copy Result button not working | Try hard refresh (Ctrl+F5); clipboard API may require HTTPS on some browsers |
| JSON export empty | Evaluate at least one idea first |
| idea_30, 46, 56, 74, 84, 85 capped at 59 | These have Critical safety findings — review the findings in the evaluation popup |

### If Server Won't Start

1. Kill any existing node process on port 3001:
   ```powershell
   netstat -ano | findstr 3001
   ```
   Note the PID from the last column.
2. Verify the process is the Node.js server:
   ```powershell
   Get-Process -Id <PID>
   ```
3. Stop only that process:
   ```powershell
   Stop-Process -Id <PID> -Force
   ```
4. If no process is listening on port 3001, nothing needs to be stopped.

### Server Binding Security

The Express server binds to all network interfaces (`0.0.0.0`), not just `localhost`. This means the tool is accessible from any device on your local network at `http://<your-computer-ip>:3001`. The `contentrating.local` hostname is just a local hostname entry — it does not make the tool publicly accessible on the internet. If you need to restrict access to localhost only, modify `server.js` line 178:
```javascript
app.listen(PORT, '127.0.0.1', () => {
```

## Verification Record

| Item | Value |
|------|-------|
| Tool version | `1.2.0-offline` (offline mode), `1.0.0-online` (online mode) |
| Last documentation update | 2026-11-04 |
| Number of ideas verified | 117 |
| Offline evaluation verification | **Verified** — all 117 ideas loaded and evaluated successfully via `node -e` test against `http://localhost:3001/api/evaluate/idea_1` |
| Gemini online evaluation verification | **Not configured** — no `GEMINI_API_KEY` present in `.env`; online endpoint exists but is untested |
| Server binding | `0.0.0.0:3001` (all network interfaces) |

---

## Git & Commit Restrictions

The following restrictions apply to this tool:

| File/Directory | Restriction |
|---------------|-------------|
| `lib/content_ideas.dart` | **Do not modify** |
| `assets/data/content_ideas.json` | **Read-only — do not modify** |
| `lib/content_library_service.dart` | **Do not modify** |
| `lib/content_axes.dart` | **Do not modify** |
| `lib/characters.dart` | **Do not modify** |
| `lib/models/quick_idea.dart` | **Do not modify** |
| `lib/idea_inbox_store.dart` | **Do not modify** |
| `lib/plan_data.dart` | **Do not modify** |
| `lib/quality_check_center.dart` | **Do not modify** |
| `pubspec.yaml` | **Do not modify** |
| All `lib/*.dart` files | **Do not modify** |
| All `test/*.dart` files | **Do not modify** |
| `tools/content_rating_web/` | **Safe to modify** — this is the standalone tool |

### What Not to Do

- Do **not** add Content Rating screens to Flutter
- Do **not** change Flutter navigation
- Do **not** modify `HookIdea` or any model
- Do **not** change idea IDs, ordering, categories, or archived flags
- Do **not** add dependencies to `pubspec.yaml`
- Do **not** upgrade Flutter or Dart
- Do **not** commit `assets/data/content_ideas.json` changes
- Do **not** expose Gemini API keys in any committed file

### What Can Be Committed

- Files under `tools/content_rating_web/` only
- Documentation updates in `documentation/`
- Nothing in `lib/` or `assets/data/`

---

## Troubleshooting Checklist

- [ ] Server running: `npm start` shows "Content Rating Tool backend running on http://localhost:3001"
- [ ] Health check: `http://localhost:3001/api/health` returns `{"ok":true}`
- [ ] Ideas loading: `http://localhost:3001/api/ideas` returns 117 ideas
- [ ] Evaluation working: Click "Evaluate This Idea" on any idea card
- [ ] Copy working: Click "Copy Result" in evaluation popup; paste into any text editor
- [ ] Export working: Click "Export JSON" or "Export CSV" on dashboard

---

## File Reference

| File | Purpose |
|------|---------|
| `server.js` | Express backend server |
| `backend/ratingEngine.js` | Offline + online rating engine |
| `backend/schemas.js` | Validation schemas + weighted scoring |
| `backend/storage.js` | File-based result storage |
| `frontend/index.html` | Single-page UI |
| `frontend/css/style.css` | Responsive styles |
| `frontend/js/app.js` | Main controller |
| `data/ratings/` | Saved rating results (runtime) |
| `.env` | Local configuration (API key, port) — **do not commit** |
| `.gitignore` | Git ignore rules |
| `package.json` | Node.js dependencies |
| `setup-hosts.ps1` | PowerShell script for hosts file |
| `README.md` | Quick start guide |

---

**The Content Rating Tool is a standalone utility. It reads `assets/data/content_ideas.json` as read-only input, evaluates ideas using offline heuristics or online Gemini, and stores results separately. No Flutter code is modified.**
