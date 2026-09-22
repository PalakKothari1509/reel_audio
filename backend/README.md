# Fun Learning With Palak Idea API

Small backend boundary for the AI Idea Lab. Provider credentials stay on the server and are never sent to the Flutter app.

## Run locally

```powershell
cd backend
npm install
$env:OPENAI_API_KEY = 'your-key'
npm start
```

Health check: `http://localhost:8787/health`

Generate ideas:

```powershell
Invoke-RestMethod -Method Post -Uri http://localhost:8787/v1/ideas -ContentType 'application/json' -Body (@{
  provider = 'openai'
  topic = 'preschool morning problems'
  contentType = 'Reel'
  goal = 'Reach new parents'
  characters = @('Ria', 'Rio')
  count = 5
} | ConvertTo-Json)
```

## Production deployment

Deploy this service to Cloud Run, Fly.io, Render, or another HTTPS service. Set the environment variables in the hosting provider's secret manager. Configure the Flutter app with only the public HTTPS base URL.

Do not commit `.env`, provider keys, or existing local secret files. Rotate any key that has ever been pasted into source, logs, chat, or an APK.

## API

`POST /v1/ideas`

- `provider`: `openai` only for now
- `topic`: required string
- `contentType`: Reel, Static Post, Carousel, Story, Marketing, Character introduction, or Milestone
- `goal`: reach, followers, shares, saves, comments, educational, emotional, or funny
- `characters`: optional array
- `count`: 1-20

The response returns OpenAI ideas in a normalized shape, including title, hook, concept, character, reason, and quality scores. Claude can be added later without changing the Flutter contract.
