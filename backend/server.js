import 'dotenv/config';
import express from 'express';

const app = express();
const port = Number(process.env.PORT || 8787);
const maxIdeas = 20;

app.use(express.json({ limit: '64kb' }));

app.get('/', (_request, response) => {
  response.json({
    service: 'fun-learning-idea-api',
    status: 'running',
    endpoints: {
      health: 'GET /health',
      ideas: 'POST /v1/ideas',
    },
  });
});

app.get('/health', (_request, response) => {
  response.json({ ok: true, service: 'fun-learning-idea-api' });
});

app.post('/v1/ideas', async (request, response) => {
  try {
    const input = validateInput(request.body);
    const results = [{ provider: 'openai', ideas: await generateIdeas(input) }];
    response.json({
      request: input,
      results,
      generatedAt: new Date().toISOString(),
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Idea generation failed.';
    const status = error instanceof ProviderError ? error.status : 400;
    response.status(status).json({ error: message });
  }
});

function validateInput(body = {}) {
  const provider = body.provider || 'openai';
  if (provider !== 'openai') {
    throw new Error('Only the OpenAI provider is enabled right now.');
  }

  const topic = String(body.topic || '').trim();
  if (!topic) throw new Error('topic is required');

  const count = Math.min(Math.max(Number(body.count || 5), 1), maxIdeas);
  return {
    provider,
    topic: topic.slice(0, 500),
    contentType: String(body.contentType || 'Reel').slice(0, 80),
    goal: String(body.goal || 'Reach new parents').slice(0, 120),
    characters: Array.isArray(body.characters) ? body.characters.map(String).slice(0, 5) : [],
    count,
    brandContext: buildBrandContext(),
  };
}

function buildBrandContext() {
  return `Brand: Fun Learning With Palak
Tagline: Little Stories, Big Lessons
Audience: Parents of preschool children
Style: cute, pastel, storybook, warm, child-friendly, funny and parent-relatable
Ria: Tofani, energetic, mischievous, playful
Rio: Ziddi, stubborn, often says no, sweet underneath
Cuty: peaceful, calm, sleep lover
Avoid: generic moral stories, repeated lessons, overly educational tone, and the formula where a child simply does wrong and a parent explains.`;
}

function promptFor(input) {
  return `You are the Idea Brain for Fun Learning With Palak.

${input.brandContext}

Create ${input.count} original ideas for:
Topic: ${input.topic}
Content type: ${input.contentType}
Goal: ${input.goal}
Characters to consider: ${input.characters.length ? input.characters.join(', ') : 'choose the best fit'}

Do not repeat common ideas already overused by parenting pages. Make each concept specific, visual, emotionally clear, and easy to turn into a reel, carousel, or static post.
Return ONLY valid JSON in this shape:
{"ideas":[{"title":"","hook":"","concept":"","character":"","contentType":"","whyItCouldWork":"","scores":{"hook":0,"relatability":0,"curiosity":0,"entertainment":0,"emotional":0,"originality":0}}]}
Scores must be integers from 1 to 10.`;
}

async function generateIdeas(input) {
  const prompt = promptFor(input);
  return callOpenAI(prompt, input.count);
}

async function callOpenAI(prompt, count) {
  const key = requiredEnv('OPENAI_API_KEY');
  const model = process.env.OPENAI_MODEL || 'gpt-4.1-mini';
  const result = await fetch('https://api.openai.com/v1/responses', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${key}` },
    body: JSON.stringify({ model, input: prompt }),
  });
  const json = await result.json();
  if (!result.ok) {
    throw new ProviderError(
      json.error?.message || 'OpenAI request failed.',
      result.status >= 400 && result.status < 500 ? result.status : 502,
    );
  }
  return parseIdeas(extractOpenAIText(json), count);
}

class ProviderError extends Error {
  constructor(message, status) {
    super(message);
    this.status = status;
  }
}

function extractOpenAIText(json) {
  if (typeof json.output_text === 'string') return json.output_text;
  return (json.output || [])
    .flatMap((item) => item.content || [])
    .map((part) => part.text || '')
    .join('');
}

function parseIdeas(text, count) {
  const cleaned = text.trim().replace(/^```json\s*/i, '').replace(/\s*```$/, '');
  const parsed = JSON.parse(cleaned);
  if (!Array.isArray(parsed.ideas)) throw new Error('AI returned no ideas.');
  return parsed.ideas.slice(0, count).map((idea) => ({
    title: String(idea.title || ''),
    hook: String(idea.hook || ''),
    concept: String(idea.concept || ''),
    character: String(idea.character || ''),
    contentType: String(idea.contentType || ''),
    whyItCouldWork: String(idea.whyItCouldWork || ''),
    scores: idea.scores || {},
  }));
}

function requiredEnv(name) {
  const value = process.env[name];
  if (!value) throw new Error(`${name} is not configured on the backend.`);
  return value;
}

app.listen(port, () => {
  console.log(`Idea API listening on http://localhost:${port}`);
});
