# Content Rating Tool — Standalone Browser Utility

This tool evaluates content ideas from `assets/data/content_ideas.json` and
produces ratings, findings, and improvement suggestions. It is completely
separate from the Flutter application — no Flutter files are modified.

## Structure

```
tools/content_rating_web/
├── server.js           # Express backend
├── ratingEngine.js     # Offline + online rating logic
├── schemas.js          # Response validation schemas
├── storage.js          # File-based result storage
├── package.json
├── .env.example        # Copy to .env and add your Gemini key
├── .gitignore
├── README.md
├── setup-hosts.ps1     # PowerShell script to add contentrating.local to hosts
├── frontend/
│   ├── index.html
│   ├── css/style.css
│   └── js/*.js
└── data/ratings/       # Saved rating results (created at runtime)
```

## Getting Started

### 1. Install dependencies

```
cd tools/content_rating_web
npm install
```

### 2. Configure the local hostname (`contentrating.local`)

The tool is designed to be accessed at `http://contentrating.local:3001` instead of `http://localhost:3001`. This requires adding an entry to your Windows hosts file.

**Option A — Run the setup script as Administrator:**

Right-click **PowerShell** and select **"Run as Administrator"**, then run:

```
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
.\tools\content_rating_web\setup-hosts.ps1
```

**Option B — Manual hosts file edit:**

1. Open Notepad as Administrator (right-click → "Run as Administrator")
2. Open `C:\Windows\System32\drivers\etc\hosts`
3. Add this line at the end:
   ```
   127.0.0.1 contentrating.local
   ```
4. Save and close the file

The hosts file entry persists across reboots, so `contentrating.local` will continue to work after restarting your laptop and server.

### 3. Configure the Gemini API key (optional — offline mode works without it)

```
cp .env.example .env
# Edit .env and add your GEMINI_API_KEY
```

### 4. Start the backend

```
npm start
```

### 5. Open the browser

Navigate to:

```
http://contentrating.local:3001
```

## Architecture

- **Frontend**: Vanilla HTML/CSS/JS — no build step, runs in any modern browser
- **Backend**: Express.js — serves the frontend, handles Gemini proxy, storage
- **Storage**: JSON files in `data/ratings/` — original `content_ideas.json` is read-only
- **API key**: Stored in `.env` (gitignored), never exposed to the browser

## Evaluation Modes

- **Online**: Gemini evaluation with structured JSON output, validation, retry
- **Offline**: Deterministic heuristic rules, no API key required

## Deployment

The backend loads its evaluation rules from `shared/evaluation/evaluation_rules.json`
in the repository root during development. For standalone deployment (outside the
monorepo), a generated copy must be placed in the backend directory.

### Authoritative Source vs Generated Copy

| File | Role | Maintained? |
|---|---|---|
| `shared/evaluation/evaluation_rules.json` | Authoritative source of truth | Yes — edit this file |
| `tools/content_rating_web/backend/evaluation_rules.json` | Generated deployment copy | No — produced by `prepare:deployment` |

Never edit `backend/evaluation_rules.json` directly. Always update the authoritative
source at `shared/evaluation/evaluation_rules.json` and regenerate the copy.

### Deployment Preparation

Before deploying the backend standalone, run:

```
cd tools/content_rating_web
npm run prepare:deployment
```

This invokes `deploy.js`, which:
1. Reads the authoritative spec from `shared/evaluation/evaluation_rules.json`
2. Validates it (JSON syntax, required `dimensions`, weight total = 100)
3. Copies it to `tools/content_rating_web/backend/evaluation_rules.json`

### Generated Artifact Location

```
tools/content_rating_web/backend/evaluation_rules.json
```

### Standalone Deployment Requirements

When deploying the backend outside the monorepo:
1. Copy the entire `tools/content_rating_web/` directory to the deployment target.
2. Run `npm run prepare:deployment` before deployment (or ensure
   `backend/evaluation_rules.json` is included in the deployment artifact).
3. Run `npm install` on the target to install dependencies.
4. Configure `.env` with `GEMINI_API_KEY` (optional — offline mode works without it).
5. Start with `npm start`.

The backend (`schemas.js`) resolves the evaluation spec in this order:
1. `shared/evaluation/evaluation_rules.json` (repo-relative — development only)
2. `backend/evaluation_rules.json` (deploy-time copy — standalone deployment)

If neither path is available, the backend fails to start with an actionable error.

### CI/CD

There is no dedicated CI/CD workflow for the browser tool. The deployment
preparation command (`npm run prepare:deployment`) must be run manually or added
to your deployment pipeline before pushing the backend artifact.

## Isolation

This tool does not modify any Flutter application files. It only reads
`assets/data/content_ideas.json` as read-only input.

## Troubleshooting

### `contentrating.local` does not resolve

1. Verify the hosts file entry exists:
   ```
   Get-Content C:\Windows\System32\drivers\etc\hosts | Select-String contentrating.local
   ```
   You should see: `127.0.0.1 contentrating.local`

2. If missing, add it manually (see step 2 above) or re-run the setup script as Administrator.

3. Flush the DNS cache:
   ```
   ipconfig /flushdns
   ```

### Server not accessible

1. Verify the server is running: `npm start` should show "Content Rating Tool backend running on http://localhost:3001"
2. Verify port 3001 is not blocked by Windows Firewall
3. Try `http://localhost:3001` first to confirm the server works, then switch to `http://contentrating.local:3001`

### Port 3001 already in use

If port 3001 is already in use, change the port in `.env`:
```
PORT=3002
```
Then restart the server.

### Removing the hostname configuration

To remove `contentrating.local`:
1. Open Notepad as Administrator
2. Open `C:\Windows\System32\drivers\etc\hosts`
3. Delete the line containing `contentrating.local`
4. Save and close

## API Routes

All API routes work under both hostnames:

- `GET /api/health` — Health check
- `GET /api/ideas` — List all 117 ideas
- `GET /api/ideas/:id` — Single idea
- `GET /api/ratings` — Saved ratings
- `POST /api/evaluate/:id` — Evaluate an idea
- `DELETE /api/ratings/:id` — Delete a rating
- `DELETE /api/ratings` — Clear all ratings
- `GET /api/export/json` — JSON export
- `GET /api/export/csv` — CSV export
