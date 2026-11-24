'use strict';

const fs = require('fs');
const path = require('path');
const {
  DIMENSIONS, GATES, SEVERITIES, VERDICTS, validateGeminiResponse,
  computeWeightedScore, computeVerdict, isCriticalCapEnabled,
  getCriticalCapThreshold, getCriticalCapScore, getCriticalCapVerdict,
} = require('./schemas');
const { runAllChecks } = require('./deterministicChecks');
const { evaluateGates } = require('./ratingEngine');

const CONTENT_JSON_PATH = path.resolve(__dirname, '../../../assets/data/content_ideas.json');

// HookIdea schema field allowlist (matches lib/content_ideas.dart HookIdea)
const HOOK_IDEA_FIELDS = [
  'id', 'category', 'title', 'cover', 'opening', 'problem', 'lesson',
  'postFormat', 'strategy', 'caption', 'pinnedComment', 'forApp', 'usedOn',
  'custom', 'archived', 'storyDetail', 'setting', 'sceneDetail', 'dialogue',
  'mess', 'innerThought', 'endingBeat', 'defaultCast', 'keepMoralOffScreen',
  'quote', 'detail', 'punchline', 'readyPrompt', 'score', 'band', 'reviewedOn',
];

const REQUIRED_STRING_FIELDS = [
  'id', 'category', 'cover', 'opening', 'problem', 'lesson',
];

const BOOLEAN_FIELDS = ['forApp', 'custom', 'archived', 'keepMoralOffScreen'];

function loadSourceIdeas() {
  const raw = fs.readFileSync(CONTENT_JSON_PATH, 'utf8');
  const data = JSON.parse(raw);
  return data.ideas || [];
}

function getIdeaById(ideaId) {
  const ideas = loadSourceIdeas();
  return ideas.find(i => i.id === ideaId) || null;
}

function isValidHookIdea(obj) {
  if (!obj || typeof obj !== 'object' || Array.isArray(obj)) {
    return { valid: false, error: 'Repaired idea is not an object' };
  }

  // ID must be a non-empty string
  if (typeof obj.id !== 'string' || obj.id.trim().length === 0) {
    return { valid: false, error: 'Missing or invalid id field' };
  }

  // All required string fields must be present and non-empty
  for (const field of REQUIRED_STRING_FIELDS) {
    if (typeof obj[field] !== 'string' || obj[field].trim().length === 0) {
      return { valid: false, error: `Missing or empty required field: ${field}` };
    }
  }

  // Boolean fields must be booleans
  for (const field of BOOLEAN_FIELDS) {
    if (typeof obj[field] !== 'boolean') {
      return { valid: false, error: `Field ${field} must be a boolean` };
    }
  }

  // defaultCast must be an array of strings if present
  if (obj.defaultCast !== undefined) {
    if (!Array.isArray(obj.defaultCast) || !obj.defaultCast.every(c => typeof c === 'string')) {
      return { valid: false, error: 'defaultCast must be an array of strings' };
    }
  }

  // No unknown top-level fields
  const knownFields = new Set(HOOK_IDEA_FIELDS);
  for (const key of Object.keys(obj)) {
    if (!knownFields.has(key)) {
      return { valid: false, error: `Unknown field in repaired idea: ${key}` };
    }
  }

  return { valid: true };
}

function buildRepairPrompt(idea, evaluation, rulesSpec) {
  const dimensionsList = DIMENSIONS.map((d, i) =>
    `${i + 1}. ${d.name} (${d.weight}%): ${d.description}`
  ).join('\n');

  const gatesList = GATES.map(g =>
    `- ${g.name} (${g.severityOnFail}): ${g.description}`
  ).join('\n');

  const criticalFindings = evaluation.criticalFindings || [];
  const majorFindings = evaluation.majorFindings || [];
  const minorFindings = evaluation.minorFindings || [];
  const suggestions = evaluation.suggestions || [];

  const findingsSummary = [
    ...criticalFindings.map(f => `  [CRITICAL] ${f.title}: ${f.explanation} (Fix: ${f.suggestedFix})`),
    ...majorFindings.map(f => `  [MAJOR] ${f.title}: ${f.explanation} (Fix: ${f.suggestedFix})`),
    ...minorFindings.map(f => `  [MINOR] ${f.title}: ${f.explanation} (Fix: ${f.suggestedFix})`),
    ...suggestions.map(f => `  [SUGGESTION] ${f.title}: ${f.explanation} (Suggested: ${f.suggested || f.original})`),
  ].join('\n');

  const gateResults = evaluation.gateResults || [];
  const gateSummary = gateResults.map(g =>
    `  - ${g.name}: ${g.passed ? 'PASS' : 'FAIL'} (${g.severityOnFail}) - ${g.detail}`
  ).join('\n');

  const approvedCharacters = ['Ria', 'Rio', 'Cuty', 'Mumma', 'Papa', 'Daadi', 'Robot', 'Teacher'];

  return `
You are an expert content editor for "Fun Learning With Palak" — Instagram Reels for Indian parents of children aged 1-4.

TASK: Repair a content idea so that every identified issue is fixed. Return a complete, corrected HookIdea JSON object.

ORIGINAL IDEA (to be repaired, NOT replaced):
ID: ${idea.id}
Title: ${idea.title}
Category: ${idea.category}
Cover: ${idea.cover}
Opening Hook: ${idea.opening}
Problem: ${idea.problem}
Lesson: ${idea.lesson}
Post Format: ${idea.postFormat || 'Reel'}
Strategy: ${idea.strategy}
Caption: ${idea.caption}
Pinned Comment: ${idea.pinnedComment}
For App: ${idea.forApp}
Used On: ${idea.usedOn}
Custom: ${idea.custom}
Archived: ${idea.archived}
Story Detail: ${idea.storyDetail}
Setting: ${idea.setting}
Scene Detail: ${idea.sceneDetail}
Dialogue: ${idea.dialogue}
Mess: ${idea.mess}
Inner Thought: ${idea.innerThought}
Ending Beat: ${idea.endingBeat}
Default Cast: ${JSON.stringify(idea.defaultCast)}
Keep Moral Off Screen: ${idea.keepMoralOffScreen}
Quote: ${idea.quote}
Detail: ${idea.detail}
Punchline: ${idea.punchline}
Ready Prompt: ${idea.readyPrompt}
Score: ${idea.score}
Band: ${idea.band}
Reviewed On: ${idea.reviewedOn}

CURRENT EVALUATION SCORE: ${evaluation.overallScore}/100
CURRENT VERDICT: ${evaluation.verdict}

CRITICAL ISSUES (must all be fixed):
${criticalFindings.length > 0 ? findingsSummary : '  None'}

MAJOR ISSUES (must all be fixed):
${majorFindings.length > 0 ? findingsSummary : '  None'}

MINOR ISSUES (fix where applicable):
${minorFindings.length > 0 ? findingsSummary : '  None'}

SUGGESTIONS (implement relevant ones):
${suggestions.length > 0 ? findingsSummary : '  None'}

GATE RESULTS:
${gateSummary}

APPROVED CHARACTERS (use only these, with correct pronouns):
${approvedCharacters.join(', ')}
- Ria (she), Rio (he), Cuty (she), Mumma (she), Papa (he), Daadi (she), Robot (it), Teacher (any)

BRAND AND SAFETY RULES:
- No brand names (Britannia, Parle-G, Amul, Maggi, Cadbury, etc.) in readyPrompt, caption, pinnedComment, storyDetail
- No IP-style terms (Pixar, Disney, Peppa Pig, Cocomelon, Chhota Bheem, Paw Patrol, Bluey, Marvel) in any field
- No unsafe language depicting harm to children as positive
- Content must be appropriate for children aged 1-4

EVALUATION DIMENSIONS (improve all scores):
${dimensionsList}

REPAIR REQUIREMENTS:
1. Fix every Critical issue completely.
2. Fix every Major issue completely.
3. Fix every Minor issue where applicable.
4. Implement relevant improvement suggestions.
5. Improve the opening hook and retention.
6. Improve story structure, payoff, and emotional connection.
7. Improve natural Hinglish dialogue (adults speak natural Hindi, children use age-appropriate Hinglish).
8. Ensure content is appropriate for children aged 1-4.
9. Maintain consistency with all eight approved characters.
10. Follow the declared post format (${idea.postFormat || 'Reel'}).
11. Improve visual storytelling and sound-off readability.
12. Improve caption and pinned comment where necessary.
13. Follow all brand and child-safety requirements.

PRESERVATION RULES (critical):
- Preserve the original idea ID exactly: ${idea.id}
- Preserve the original category exactly: ${idea.category}
- Preserve the original concept, educational message, intended audience, and creative identity.
- Do NOT replace the idea with an unrelated idea.
- Do NOT remove fields simply because you consider them unnecessary.
- Do NOT rename JSON properties.
- Do NOT generate duplicate IDs.
- Keep all fields that are already good — only change what needs fixing.
- The readyPrompt must use "3D Pixar animation style" (not "3D animated style" or other variants).
- Preserve archived status: ${idea.archived}
- Preserve custom status: ${idea.custom}

OUTPUT FORMAT:
Return ONLY valid JSON with this exact structure (all HookIdea fields, no extras):

{
  "id": "${idea.id}",
  "category": "${idea.category}",
  "title": "...",
  "cover": "...",
  "opening": "...",
  "problem": "...",
  "lesson": "...",
  "postFormat": "${idea.postFormat || 'Reel'}",
  "strategy": "...",
  "caption": "...",
  "pinnedComment": "...",
  "forApp": ${idea.forApp},
  "usedOn": "${idea.usedOn}",
  "custom": ${idea.custom},
  "archived": ${idea.archived},
  "storyDetail": "...",
  "setting": "...",
  "sceneDetail": "...",
  "dialogue": "...",
  "mess": "...",
  "innerThought": "...",
  "endingBeat": "...",
  "defaultCast": ["Ria", "Rio", "Cuty"],
  "keepMoralOffScreen": ${idea.keepMoralOffScreen},
  "quote": "...",
  "detail": "...",
  "punchline": "...",
  "readyPrompt": "...",
  "score": 0,
  "band": "",
  "reviewedOn": ""
}

The score, band, and reviewedOn fields should be preserved from the original or reset to defaults (0, "", "") — they are evaluation metadata, not creative content.
`;
}

function extractJsonFromResponse(text) {
  let jsonText = text.trim();
  const jsonMatch = jsonText.match(/```json\n([\s\S]*?)\n```/) || jsonText.match(/```([\s\S]*?)```/) || [null, jsonText];
  jsonText = jsonMatch[1] || jsonText;
  return jsonText;
}

async function repairIdeaWithGemini(idea, evaluation, geminiApiKey, rulesSpec) {
  const fetch = (await import('node-fetch')).default;
  const apiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent';

  const prompt = buildRepairPrompt(idea, evaluation, rulesSpec);

  const body = {
    contents: [{ parts: [{ text: prompt }] }],
    generationConfig: {
      temperature: 0.4,
      maxOutputTokens: 8000,
    },
  };

  let lastError = null;
  for (let attempt = 0; attempt < 3; attempt++) {
    try {
      const resp = await fetch(`${apiUrl}?key=${geminiApiKey}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
      });

      if (!resp.ok) {
        const text = await resp.text();
        lastError = `HTTP ${resp.status}: ${text}`;
        if (resp.status === 429 || resp.status === 503 || resp.status === 500) {
          await new Promise(r => setTimeout(r, 2000 * (attempt + 1)));
          continue;
        }
        throw new Error(lastError);
      }

      const data = await resp.json();
      const text = data.candidates?.[0]?.content?.parts?.[0]?.text || '';

      let jsonText;
      try {
        jsonText = extractJsonFromResponse(text);
        const parsed = JSON.parse(jsonText);
        return { repairedIdea: parsed, rawResponse: text };
      } catch (e) {
        lastError = `Invalid JSON from Gemini: ${e.message}`;
        if (attempt < 2) continue;
        throw new Error(lastError);
      }
    } catch (e) {
      lastError = e.message;
      if (attempt < 2) {
        await new Promise(r => setTimeout(r, 2000));
        continue;
      }
      throw e;
    }
  }
  throw new Error(lastError || 'Unknown Gemini error');
}

function compareIdeas(original, repaired) {
  const changedFields = [];
  const unchangedFields = [];

  const allKeys = new Set([...Object.keys(original), ...Object.keys(repaired)]);

  for (const key of allKeys) {
    const origVal = original[key];
    const repVal = repaired[key];

    if (key === 'defaultCast') {
      const origStr = JSON.stringify(origVal);
      const repStr = JSON.stringify(repVal);
      if (origStr !== repStr) {
        changedFields.push(key);
      } else {
        unchangedFields.push(key);
      }
    } else if (String(origVal) !== String(repVal)) {
      changedFields.push(key);
    } else {
      unchangedFields.push(key);
    }
  }

  return { changedFields, unchangedFields };
}

module.exports = {
  loadSourceIdeas,
  getIdeaById,
  isValidHookIdea,
  buildRepairPrompt,
  extractJsonFromResponse,
  repairIdeaWithGemini,
  compareIdeas,
  HOOK_IDEA_FIELDS,
  CONTENT_JSON_PATH,
};
