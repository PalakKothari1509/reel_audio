# Browser Rating Tool Overview — Content Rating Tool

## What the tool does

The **Content Rating Tool** is a standalone, browser-based application that evaluates the quality of content ideas created for the Instagram brand **Fun Learning With Palak**. It assesses whether an idea:

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

**Completely separate from the Flutter application** — no Flutter files are modified. It only reads `assets/data/content_ideas.json` as read-only input.

---

## Structure

```
tools/content_rating_web/
├── server.js              # Express backend
├── ratingEngine.js        # Offline + online rating logic
├── schemas.js             # Response validation schemas
├── storage.js             # File-based result storage
├── deploy.js              # Deployment preparation script
├── batch_evaluate.js      # Batch evaluation script
├── package.json
├── .env.example           # Copy to .env and add your Gemini key
├── .gitignore
├── setup-hosts.ps1        # PowerShell script to add contentrating.local to hosts
├── backend/
│   ├── server.js
│   ├── ratingEngine.js
│   ├── schemas.js
│   ├── storage.js
│   ├── db.js
│   ├── hash.js
│   ├── migrate.js
│   ├── deterministicChecks.js
│   ├── evaluation_rules.json       # Generated deployment copy
│   ├── config/
│   └── *.test.js
├── frontend/
│   ├── index.html
│   ├── css/style.css
│   └── js/*.js
└── data/ratings/          # Saved rating results (created at runtime)
```

---

## Getting started

### 1. Install dependencies

```bash
cd tools/content_rating_web
npm install
```

### 2. Configure the local hostname (`contentrating.local`)

The tool is designed to be accessed at `http://contentrating.local:3001` instead of `http://localhost:3001`. This requires adding an entry to your Windows hosts file.

**Option A — Run the setup script as Administrator:**

Right-click PowerShell and select "Run as Administrator", then run:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
.\tools\content_rating_web\setup-hosts.ps1
```

**Option B — Manual hosts file edit:**

1. Open Notepad as Administrator
2. Open `C:\Windows\System32\drivers\etc\hosts`
3. Add this line at the end:
   ```
   127.0.0.1 contentrating.local
   ```
4. Save and close

### 3. Configure the Gemini API key (optional — offline mode works without it)

```bash
cp .env.example .env
# Edit .env and add your GEMINI_API_KEY
```

### 4. Start the backend

```bash
npm start
```

### 5. Open the browser

Navigate to:

```
http://contentrating.local:3001
```

---

## Architecture

| Layer | Technology | Details |
|-------|-----------|---------|
| Frontend | Vanilla HTML/CSS/JS | No build step, runs in any modern browser |
| Backend | Express.js | Serves frontend, handles Gemini proxy, storage |
| Storage | JSON files | `data/ratings/` — original `content_ideas.json` is read-only |
| API key | `.env` | Stored locally, gitignored, never exposed to the browser |

---

## Evaluation modes

### Online
Gemini evaluation with structured JSON output, validation, and retry. Requires `GEMINI_API_KEY` in `.env`.

### Offline
Deterministic heuristic rules, no API key required. Always available.

---

## Rating framework

Ideas are rated on 10 dimensions, each with a weight. Weights total 100:

| Dimension | Weight |
|-----------|--------|
| Hook Strength | 15 |
| Relatability & Audience Fit | 15 |
| Payoff & Retention | 14 |
| Hinglish Naturalness | 10 |
| Visual Feasibility | 10 |
| Sound-Off Readability | 8 |
| Share/Save Trigger | 8 |
| Caption/Comment Package | 8 |
| Originality | 5 |
| Audio Hook | 7 |

### Critical safety rules (hard gates)
- **Age Appropriateness** — content must be suitable for children aged 1–4
- **Character Consistency** — characters must match their defined appearances
- **Brand & Safety** — no blocked brand/IP terms, no unsafe content
- **Format Fit** — idea must fit its declared post format (Reel/Carousel/Image)

Gate failures produce severity-level findings (Critical, Major, Minor).

### Verdicts

| Verdict | Meaning |
|---------|---------|
| Ready to Post | Score high, all critical gates passed |
| Needs Minor Fixes | Minor issues, easy to correct |
| Needs Major Rewrite | Significant structural problems |
| Reject | Critical failures or unsafe content |

---

## Offline vs Online evaluation

| Aspect | Offline | Online |
|--------|---------|--------|
| API key required | No | Yes (Gemini) |
| Deterministic | Yes | No |
| Structured JSON output | Heuristic rules | Gemini with validation |
| Retry logic | N/A | Yes, on failure |
| Speed | Fast | Slower (network) |

The backend falls back gracefully between modes.

---

## Authoritative evaluation spec

The backend loads its evaluation rules from `shared/evaluation/evaluation_rules.json` in the repository root during development. For standalone deployment, a generated copy must be placed in the backend directory.

| File | Role | Maintained? |
|------|------|-------------|
| `shared/evaluation/evaluation_rules.json` | Authoritative source of truth | Yes — edit this file |
| `tools/content_rating_web/backend/evaluation_rules.json` | Generated deployment copy | No — produced by `prepare:deployment` |

Never edit `backend/evaluation_rules.json` directly. Always update the authoritative source and regenerate the copy.

### Deployment preparation

Before deploying the backend standalone:

```bash
cd tools/content_rating_web
npm run prepare:deployment
```

This runs `deploy.js`, which:
1. Reads the authoritative spec from `shared/evaluation/evaluation_rules.json`
2. Validates it (JSON syntax, required `dimensions`, weight total = 100)
3. Copies it to `tools/content_rating_web/backend/evaluation_rules.json`

### Standalone deployment requirements

1. Copy the entire `tools/content_rating_web/` directory to the deployment target
2. Run `npm run prepare:deployment` (or ensure `backend/evaluation_rules.json` is included)
3. Run `npm install` on the target
4. Configure `.env` with `GEMINI_API_KEY` (optional — offline mode works without it)
5. Start with `npm start`

The backend (`schemas.js`) resolves the evaluation spec in this order:
1. `shared/evaluation/evaluation_rules.json` (repo-relative — development only)
2. `backend/evaluation_rules.json` (deploy-time copy — standalone deployment)

If neither path is available, the backend fails to start with an actionable error.

---

## API routes

All API routes work under both hostnames (`localhost:3001` and `contentrating.local:3001`):

| Route | Method | Description |
|-------|--------|-------------|
| `/api/health` | GET | Health check |
| `/api/ideas` | GET | List all ideas |
| `/api/ideas/:id` | GET | Single idea |
| `/api/ratings` | GET | Saved ratings |
| `/api/evaluate/:id` | POST | Evaluate an idea |
| `/api/ratings/:id` | DELETE | Delete a rating |
| `/api/ratings` | DELETE | Clear all ratings |
| `/api/export/json` | GET | JSON export |
| `/api/export/csv` | GET | CSV export |

---

## Isolation

This tool does not modify any Flutter application files. It only reads `assets/data/content_ideas.json` as read-only input.

---

## Troubleshooting

### `contentrating.local` does not resolve

1. Verify the hosts file entry:
   ```
   Get-Content C:\Windows\System32\drivers\etc\hosts | Select-String contentrating.local
   ```
   You should see: `127.0.0.1 contentrating.local`

2. If missing, add it manually or re-run the setup script as Administrator.

3. Flush the DNS cache:
   ```
   ipconfig /flushdns
   ```

### Server not accessible

1. Verify the server is running: `npm start` should show "Content Rating Tool backend running on http://localhost:3001"
2. Verify port 3001 is not blocked by Windows Firewall
3. Try `http://localhost:3001` first, then switch to `http://contentrating.local:3001`

### Port 3001 already in use

Change the port in `.env`:
```
PORT=3002
```
Then restart the server.

### Removing the hostname configuration

1. Open Notepad as Administrator
2. Open `C:\Windows\System32\drivers\etc\hosts`
3. Delete the line containing `contentrating.local`
4. Save and close
