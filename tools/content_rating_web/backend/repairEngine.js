'use strict';

const fs = require('fs');
const path = require('path');
const {
  DIMENSIONS, GATES, SEVERITIES, VERDICTS, validateGeminiResponse,
  computeWeightedScore, computeVerdict, isCriticalCapEnabled,
  getCriticalCapThreshold, getCriticalCapScore, getCriticalCapVerdict,
  getDimensionById, getGateById,
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

const APPROVED_CHARACTERS = ['Ria', 'Rio', 'Cuty', 'Mumma', 'Papa', 'Daadi', 'Robot', 'Teacher'];

const BRAND_BLOCKLIST = [
  'Britannia', 'Parle-G', 'Parle', 'Amul', 'Maggi', 'Cadbury', 'Dairy Milk',
  'Oreo', 'Kurkure', 'Lays', 'Haldiram', 'Mother Dairy',
];
const IP_BLOCKLIST = ['Disney', 'Peppa Pig', 'Cocomelon', 'Chhota Bheem', 'Paw Patrol', 'Bluey', 'Marvel'];

const GENERIC_PINNED_TEMPLATES = [
  'Isi concept ko real-life situation mein try karo',
  'Har tip ko try karo aur comment mein batana',
  'Tip: Time teller ke liye ek simple song ya rhyme banayein',
  'Pehle mera, phir tera',
  'Gaadi aane se pehle ek signal lelo',
  'Har game se pehle ek simple rule samjho',
];

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

  if (typeof obj.id !== 'string' || obj.id.trim().length === 0) {
    return { valid: false, error: 'Missing or invalid id field' };
  }

  for (const field of REQUIRED_STRING_FIELDS) {
    if (typeof obj[field] !== 'string' || obj[field].trim().length === 0) {
      return { valid: false, error: `Missing or empty required field: ${field}` };
    }
  }

  for (const field of BOOLEAN_FIELDS) {
    if (typeof obj[field] !== 'boolean') {
      return { valid: false, error: `Field ${field} must be a boolean` };
    }
  }

  if (obj.defaultCast !== undefined) {
    if (!Array.isArray(obj.defaultCast) || !obj.defaultCast.every(c => typeof c === 'string')) {
      return { valid: false, error: 'defaultCast must be an array of strings' };
    }
  }

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

// ─────────────────────────────────────────────────────────────────────────────
// OFFLINE DETERMINISTIC REPAIR ENGINE
// ─────────────────────────────────────────────────────────────────────────────

function normalizeText(text) {
  if (!text) return '';
  return text.toLowerCase()
    .replace(/[.,!?;:()\[\]{}"'“”‘’]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function tokenize(text) {
  const normalized = normalizeText(text);
  return normalized.split(' ').filter(w => w.length > 2);
}

function replaceBrandAndIpTerms(text) {
  let result = text;
  for (const brand of BRAND_BLOCKLIST) {
    const regex = new RegExp(brand.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'gi');
    result = result.replace(regex, '[brand]');
  }
  for (const ip of IP_BLOCKLIST) {
    const regex = new RegExp(ip.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'gi');
    result = result.replace(regex, '[brand]');
  }
  return result;
}

function fixUnsafeLanguage(text) {
  let result = text;
  const unsafePatterns = [
    /\bhit\b/gi, /\bslap\b/gi, /\bspank\b/gi, /\bpunish\b/gi,
    /\bscary\b/gi, /\bterrifying\b/gi, /\bviolent\b/gi,
  ];
  for (const pattern of unsafePatterns) {
    result = result.replace(pattern, 'safe');
  }
  return result;
}

function normalizeCharacterNames(text) {
  let result = text;
  const characterVariants = [
    { pattern: /\bRiya\b/gi, replacement: 'Ria' },
    { pattern: /\bRiyaa\b/gi, replacement: 'Ria' },
    { pattern: /\bRiyaansh\b/gi, replacement: 'Rio' },
    { pattern: /\bBunny\b/gi, replacement: 'Cuty' },
    { pattern: /\bMummy\b/gi, replacement: 'Mumma' },
    { pattern: /\bMummi\b/gi, replacement: 'Mumma' },
    { pattern: /\bDad\b/gi, replacement: 'Papa' },
    { pattern: /\bDaddy\b/gi, replacement: 'Papa' },
    { pattern: /\bGrandma\b/gi, replacement: 'Daadi' },
    { pattern: /\bDadi\b/gi, replacement: 'Daadi' },
    { pattern: /\bNani\b/gi, replacement: 'Daadi' },
    { pattern: /\bNana\b/gi, replacement: 'Papa' },
    { pattern: /\bGuru\b/gi, replacement: 'Teacher' },
    { pattern: /\bMa'am\b/gi, replacement: 'Teacher' },
  ];
  for (const { pattern, replacement } of characterVariants) {
    result = result.replace(pattern, replacement);
  }
  return result;
}

function improveHook(opening, problem, category, defaultCast) {
  if (!opening || opening.trim().length === 0) {
    const mainChar = defaultCast && defaultCast.length > 0 ? defaultCast[0] : 'the child';
    const problemSentence = problem.split(/[.!?]/)[0].trim();
    return `${mainChar} faces: ${problemSentence}?`;
  }
  return opening;
}

function improveCaption(caption, lesson, problem, title, category) {
  if (!caption || caption.trim().length === 0) {
    const takeaway = lesson || problem.split(/[.!?]/)[0] || title;
    const hashtags = '#ChildSafety #IndianParents #FunLearningWithPalak #ParentingTips #ToddlerLife';
    return `${takeaway.slice(0, 280)} ${hashtags}`;
  }
  const hashtags = caption.match(/#[^\s#]+/g) || [];
  if (hashtags.length === 0) {
    const takeaway = lesson || problem.split(/[.!?]/)[0] || title;
    return `${caption} #ChildSafety #IndianParents #FunLearningWithPalak #ParentingTips #ToddlerLife`;
  }
  return caption;
}

function improvePinnedComment(pinnedComment, lesson, problem, title, category) {
  if (!pinnedComment || pinnedComment.trim().length === 0) {
    const topic = lesson || problem.split(/[.!?]/)[0] || title;
    return `What do you do when ${topic.toLowerCase().slice(0, 60)}?`;
  }

  const normalized = normalizeText(pinnedComment);
  for (const template of GENERIC_PINNED_TEMPLATES) {
    if (normalized.includes(template.toLowerCase()) || template.toLowerCase().includes(normalized)) {
      const topic = lesson || problem.split(/[.!?]/)[0] || title;
      return `What do you do when ${topic.toLowerCase().slice(0, 60)}?`;
    }
  }

  if (!/\?/.test(pinnedComment)) {
    return `${pinnedComment}?`;
  }
  return pinnedComment;
}

function improveStoryDetail(storyDetail, problem, lesson, defaultCast, endingBeat) {
  if (!storyDetail || storyDetail.trim().length === 0) {
    const mainChar = defaultCast && defaultCast.length > 0 ? defaultCast[0] : 'the child';
    const supportChar = defaultCast && defaultCast.length > 1 ? defaultCast[1] : 'a parent';
    return `Story: ${mainChar} faces ${problem.toLowerCase()}. ${supportChar} helps them understand the situation.
Twist: The first instinct doesn't work — ${mainChar} must try a different approach.
Resolution: ${mainChar} succeeds by staying calm and following ${supportChar.toLowerCase()}'s guidance.
Moral: ${lesson || 'Small steps, patience, and adult guidance help children handle challenges.'}`;
  }
  return storyDetail;
}

function improveDialogue(dialogue, defaultCast, problem, lesson) {
  if (!dialogue || dialogue.trim().length === 0) {
    const mainChar = defaultCast && defaultCast.length > 0 ? defaultCast[0] : 'the child';
    const supportChar = defaultCast && defaultCast.length > 1 ? defaultCast[1] : 'a parent';
    return `${mainChar}: "I need help!" ${supportChar}: "I am right here, let us do it together."`;
  }
  return dialogue;
}

function improveReadyPrompt(readyPrompt, idea) {
  if (!readyPrompt || readyPrompt.trim().length === 0) {
    const mainChar = idea.defaultCast && idea.defaultCast.length > 0 ? idea.defaultCast[0] : 'Ria';
    return `3D Pixar animation style, vertical 9:16. ${mainChar}'s story. ${idea.problem}. Text on screen: "${idea.title.toUpperCase()}"`;
  }

  let result = readyPrompt;
  // Ensure "3D Pixar animation style" is used (not variants)
  if (!result.includes('3D Pixar animation style')) {
    result = result.replace(/3D animated style/gi, '3D Pixar animation style');
    result = result.replace(/3D animation style/gi, '3D Pixar animation style');
    result = result.replace(/Pixar animation style/gi, '3D Pixar animation style');
    result = result.replace(/Disney animation style/gi, '3D Pixar animation style');
  }

  // Ensure vertical 9:16 is present
  if (!result.includes('vertical 9:16') && !result.includes('9:16')) {
    result = result.replace(/3D Pixar animation style/, '3D Pixar animation style, vertical 9:16');
  }

  return result;
}

function improveSetting(setting, postFormat) {
  if (!setting || setting.trim().length === 0) {
    const settings = {
      Reel: 'Indian home, living room',
      Carousel: 'Indian home, living room',
      Story: 'Indian home, living room',
    };
    return settings[postFormat] || 'Indian home, living room';
  }
  return setting;
}

function improveSceneDetail(sceneDetail, setting) {
  if (!sceneDetail || sceneDetail.trim().length === 0) {
    return `Visible action in ${setting || 'Indian home'}, clear props and ending image.`;
  }
  return sceneDetail;
}

function improveEndingBeat(endingBeat, lesson) {
  if (!endingBeat || endingBeat.trim().length === 0) {
    return `Everyone smiles. ${lesson || 'Small steps, patience, and adult guidance help children handle challenges.'}`;
  }
  return endingBeat;
}

function improveLesson(lesson, problem) {
  if (!lesson || lesson.trim().length === 0) {
    return `Always prioritize safety and ask a trusted adult for help. ${problem.split(/[.!?]/)[0] || ''}`;
  }
  return lesson;
}

function improveProblem(problem, category) {
  if (!problem || problem.trim().length === 0) {
    return `A child faces a common preschool situation that needs adult guidance.`;
  }
  return problem;
}

function improveOpening(opening, problem, defaultCast) {
  if (!opening || opening.trim().length === 0) {
    const mainChar = defaultCast && defaultCast.length > 0 ? defaultCast[0] : 'the child';
    return `${mainChar} faces: ${problem.split(/[.!?]/)[0]}?`;
  }
  return opening;
}

function improveCover(cover, title) {
  if (!cover || cover.trim().length === 0) {
    return title || 'Cover';
  }
  return cover;
}

function improveTitle(title, category) {
  if (!title || title.trim().length === 0) {
    return `Fun Learning With Palak — ${category}`;
  }
  return title;
}

function improveStrategy(strategy, category) {
  if (!strategy || strategy.trim().length === 0) {
    return `Parent relatable ${category.toLowerCase()} hook`;
  }
  return strategy;
}

function improveMess(mess, problem) {
  if (!mess || mess.trim().length === 0) {
    return `The situation creates pressure that needs careful handling.`;
  }
  return mess;
}

function improveInnerThought(innerThought, lesson) {
  if (!innerThought || innerThought.trim().length === 0) {
    return `The parent considers the safest, most loving response.`;
  }
  return innerThought;
}

function improveQuote(quote, opening, dialogue) {
  if (!quote || quote.trim().length === 0) {
    const firstDialogue = dialogue.split(/[.!?]/)[0].trim();
    return firstDialogue || opening || '';
  }
  return quote;
}

function improveDetail(detail, sceneDetail) {
  if (!detail || detail.trim().length === 0) {
    return sceneDetail || 'One concrete sensory detail.';
  }
  return detail;
}

function improvePunchline(punchline, endingBeat, lesson) {
  if (!punchline || punchline.trim().length === 0) {
    return endingBeat || lesson || 'A happy ending.';
  }
  return punchline;
}

function fixCharacterConsistency(idea) {
  const result = { ...idea };

  // Fix unapproved character names in all text fields
  const textFields = ['title', 'cover', 'opening', 'problem', 'lesson', 'caption',
    'pinnedComment', 'storyDetail', 'setting', 'sceneDetail', 'dialogue', 'mess',
    'innerThought', 'endingBeat', 'quote', 'detail', 'punchline', 'readyPrompt'];

  for (const field of textFields) {
    if (result[field]) {
      result[field] = normalizeCharacterNames(result[field]);
    }
  }

  // Fix defaultCast to use approved names only
  if (result.defaultCast && Array.isArray(result.defaultCast)) {
    result.defaultCast = result.defaultCast.map(c => {
      if (APPROVED_CHARACTERS.includes(c)) return c;
      // Try to map variants
      const lower = c.toLowerCase();
      if (lower.includes('ria')) return 'Ria';
      if (lower.includes('rio')) return 'Rio';
      if (lower.includes('cuty') || lower.includes('bunny')) return 'Cuty';
      if (lower.includes('mumma') || lower.includes('mummy')) return 'Mumma';
      if (lower.includes('papa') || lower.includes('dad')) return 'Papa';
      if (lower.includes('daadi') || lower.includes('dadi') || lower.includes('nani')) return 'Daadi';
      if (lower.includes('teacher') || lower.includes('guru')) return 'Teacher';
      return 'Ria'; // fallback
    });
    // Ensure at least one character
    if (result.defaultCast.length === 0) {
      result.defaultCast = ['Ria', 'Rio', 'Cuty'];
    }
  } else {
    result.defaultCast = ['Ria', 'Rio', 'Cuty'];
  }

  return result;
}

function repairIdeaOffline(idea, evaluation) {
  const repaired = { ...idea };

  const criticalFindings = evaluation.criticalFindings || [];
  const majorFindings = evaluation.majorFindings || [];
  const minorFindings = evaluation.minorFindings || [];
  const suggestions = evaluation.suggestions || [];
  const gateResults = evaluation.gateResults || [];

  const unresolvedIssues = [];
  const fixedIssues = [];

  // ── 1. Fix character consistency (Major) ──
  const charConsistencyGate = gateResults.find(g => g.id === 'characterConsistency');
  if (charConsistencyGate && !charConsistencyGate.passed) {
    const before = JSON.stringify(repaired);
    const fixed = fixCharacterConsistency(repaired);
    if (JSON.stringify(fixed) !== before) {
      fixedIssues.push('Character consistency: replaced unapproved/inconsistent character names');
    }
    Object.assign(repaired, fixed);
  }

  // ── 2. Fix brand and safety (Critical) ──
  const brandGate = gateResults.find(g => g.id === 'brandAndSafety');
  if (brandGate && !brandGate.passed) {
    const textFields = ['readyPrompt', 'caption', 'pinnedComment', 'storyDetail',
      'title', 'cover', 'opening', 'problem', 'lesson', 'setting', 'sceneDetail',
      'dialogue', 'mess', 'innerThought', 'endingBeat', 'quote', 'detail', 'punchline'];
    let brandFixed = false;
    for (const field of textFields) {
      if (repaired[field]) {
        const before = repaired[field];
        repaired[field] = replaceBrandAndIpTerms(repaired[field]);
        repaired[field] = fixUnsafeLanguage(repaired[field]);
        if (repaired[field] !== before) brandFixed = true;
      }
    }
    if (brandFixed) {
      fixedIssues.push('Brand & Safety: removed blocked brand/IP terms and unsafe language');
    } else {
      unresolvedIssues.push('Brand & Safety: could not automatically remove all blocked terms');
    }
  }

  // ── 3. Fix missing required fields (Minor/Major) ──
  const missingFieldsGate = gateResults.find(g => g.id === 'missingFields');
  if (missingFieldsGate && !missingFieldsGate.passed) {
    let fieldsFilled = false;
    if (!repaired.readyPrompt || repaired.readyPrompt.trim().length === 0) {
      repaired.readyPrompt = improveReadyPrompt('', repaired);
      fieldsFilled = true;
    }
    if (!repaired.caption || repaired.caption.trim().length === 0) {
      repaired.caption = improveCaption('', repaired.lesson, repaired.problem, repaired.title, repaired.category);
      fieldsFilled = true;
    }
    if (!repaired.pinnedComment || repaired.pinnedComment.trim().length === 0) {
      repaired.pinnedComment = improvePinnedComment('', repaired.lesson, repaired.problem, repaired.title, repaired.category);
      fieldsFilled = true;
    }
    if (fieldsFilled) {
      fixedIssues.push('Missing required fields: filled readyPrompt, caption, pinnedComment');
    }
  }

  // ── General fallback: always fill empty required text fields ──
  let fallbackFilled = false;
  if (!repaired.readyPrompt || repaired.readyPrompt.trim().length === 0) {
    repaired.readyPrompt = improveReadyPrompt('', repaired);
    fallbackFilled = true;
  }
  if (!repaired.caption || repaired.caption.trim().length === 0) {
    repaired.caption = improveCaption('', repaired.lesson, repaired.problem, repaired.title, repaired.category);
    fallbackFilled = true;
  }
  if (!repaired.pinnedComment || repaired.pinnedComment.trim().length === 0) {
    repaired.pinnedComment = improvePinnedComment('', repaired.lesson, repaired.problem, repaired.title, repaired.category);
    fallbackFilled = true;
  }
  if (fallbackFilled && !fixedIssues.some(f => f.includes('required fields'))) {
    fixedIssues.push('Missing required fields: filled empty readyPrompt, caption, pinnedComment');
  }

  // ── 4. Fix weak hook ──
  const hookDim = evaluation.dimensionScores?.find(d => d.id === 'hookStrength');
  if (hookDim && hookDim.score < 7) {
    const before = repaired.opening;
    repaired.opening = improveOpening(repaired.opening, repaired.problem, repaired.defaultCast);
    if (repaired.opening !== before) {
      fixedIssues.push('Hook Strength: improved opening hook');
    }
  }

  // ── 5. Fix relatability ──
  const relDim = evaluation.dimensionScores?.find(d => d.id === 'relatabilityAudienceFit');
  if (relDim && relDim.score < 7) {
    if (!repaired.setting || repaired.setting.trim().length === 0) {
      repaired.setting = improveSetting(repaired.setting, repaired.postFormat);
      fixedIssues.push('Relatability: added everyday setting');
    }
    if (!repaired.problem || repaired.problem.trim().length === 0) {
      repaired.problem = improveProblem(repaired.problem, repaired.category);
      fixedIssues.push('Relatability: clarified problem');
    }
  }

  // ── 6. Fix story structure/payoff ──
  const storyDim = evaluation.dimensionScores?.find(d => d.id === 'payoffRetention');
  if (storyDim && storyDim.score < 7) {
    const before = repaired.storyDetail;
    repaired.storyDetail = improveStoryDetail(repaired.storyDetail, repaired.problem, repaired.lesson, repaired.defaultCast, repaired.endingBeat);
    if (repaired.storyDetail !== before) {
      fixedIssues.push('Payoff & Retention: improved story structure');
    }
    if (!repaired.endingBeat || repaired.endingBeat.trim().length === 0) {
      repaired.endingBeat = improveEndingBeat(repaired.endingBeat, repaired.lesson);
      fixedIssues.push('Payoff & Retention: added ending beat');
    }
  }

  // ── 7. Fix Hinglish naturalness ──
  const hingDim = evaluation.dimensionScores?.find(d => d.id === 'hinglishNaturalness');
  if (hingDim && hingDim.score < 7) {
    if (!repaired.dialogue || repaired.dialogue.trim().length === 0) {
      repaired.dialogue = improveDialogue(repaired.dialogue, repaired.defaultCast, repaired.problem, repaired.lesson);
      fixedIssues.push('Hinglish Naturalness: added dialogue');
    }
  }

  // ── 8. Fix visual feasibility ──
  const visDim = evaluation.dimensionScores?.find(d => d.id === 'visualFeasibility');
  if (visDim && visDim.score < 7) {
    if (!repaired.setting || repaired.setting.trim().length === 0) {
      repaired.setting = improveSetting(repaired.setting, repaired.postFormat);
    }
    if (!repaired.sceneDetail || repaired.sceneDetail.trim().length === 0) {
      repaired.sceneDetail = improveSceneDetail(repaired.sceneDetail, repaired.setting);
      fixedIssues.push('Visual Feasibility: added setting and scene detail');
    }
  }

  // ── 9. Fix sound-off readability ──
  const soundDim = evaluation.dimensionScores?.find(d => d.id === 'soundOffReadability');
  if (soundDim && soundDim.score < 7) {
    if (!repaired.caption || repaired.caption.trim().length === 0) {
      repaired.caption = improveCaption(repaired.caption, repaired.lesson, repaired.problem, repaired.title, repaired.category);
      fixedIssues.push('Sound-Off Readability: added caption');
    }
  }

  // ── 10. Fix engagement/share trigger ──
  const engDim = evaluation.dimensionScores?.find(d => d.id === 'shareSaveTrigger');
  if (engDim && engDim.score < 7) {
    if (!repaired.pinnedComment || repaired.pinnedComment.trim().length === 0) {
      repaired.pinnedComment = improvePinnedComment(repaired.pinnedComment, repaired.lesson, repaired.problem, repaired.title, repaired.category);
      fixedIssues.push('Share/Save Trigger: added pinned comment with question');
    }
  }

  // ── 11. Fix caption/comment package ──
  const capDim = evaluation.dimensionScores?.find(d => d.id === 'captionCommentPackage');
  if (capDim && capDim.score < 7) {
    const beforeCaption = repaired.caption;
    repaired.caption = improveCaption(repaired.caption, repaired.lesson, repaired.problem, repaired.title, repaired.category);
    if (repaired.caption !== beforeCaption && !fixedIssues.some(f => f.includes('caption'))) {
      fixedIssues.push('Caption & Comment Package: improved caption');
    }
    const beforePinned = repaired.pinnedComment;
    repaired.pinnedComment = improvePinnedComment(repaired.pinnedComment, repaired.lesson, repaired.problem, repaired.title, repaired.category);
    if (repaired.pinnedComment !== beforePinned && !fixedIssues.some(f => f.includes('pinned'))) {
      fixedIssues.push('Caption & Comment Package: improved pinned comment');
    }
  }

  // ── 12. Fix age appropriateness gate (Critical) ──
  const ageGate = gateResults.find(g => g.id === 'ageAppropriateness');
  if (ageGate && !ageGate.passed) {
    // Unsafe language already handled in brand/safety fix
    // Check if still has unsafe content
    const allText = Object.values(repaired).join(' ').toLowerCase();
    const unsafeWords = ['hit', 'slap', 'spank', 'punish', 'scary', 'terrifying', 'violent', 'blood', 'weapon'];
    const stillUnsafe = unsafeWords.some(w => allText.includes(w));
    if (stillUnsafe) {
      unresolvedIssues.push('Age Appropriateness: some unsafe content may remain — manual review needed');
    } else {
      fixedIssues.push('Age Appropriateness: removed unsafe content');
    }
  }

  // ── 13. Fix format fit ──
  const formatGate = gateResults.find(g => g.id === 'formatFit');
  if (formatGate && !formatGate.passed) {
    if (!repaired.readyPrompt || repaired.readyPrompt.trim().length === 0) {
      repaired.readyPrompt = improveReadyPrompt(repaired.readyPrompt, repaired);
      fixedIssues.push('Format Fit: added production prompt');
    }
  }

  // ── 14. Fix readyPrompt style ──
  if (repaired.readyPrompt) {
    const before = repaired.readyPrompt;
    repaired.readyPrompt = improveReadyPrompt(repaired.readyPrompt, repaired);
    if (repaired.readyPrompt !== before && !fixedIssues.some(f => f.includes('readyPrompt'))) {
      fixedIssues.push('Ready Prompt: ensured 3D Pixar animation style and vertical 9:16');
    }
  }

  // ── 15. Preserve core identity ──
  repaired.id = idea.id;
  repaired.category = idea.category;
  repaired.archived = idea.archived;
  repaired.custom = idea.custom;
  repaired.forApp = idea.forApp;

  // Reset evaluation metadata (will be re-evaluated after save)
  repaired.score = idea.score || 0;
  repaired.band = idea.band || '';
  repaired.reviewedOn = idea.reviewedOn || '';

  return {
    repairedIdea: repaired,
    fixedIssues,
    unresolvedIssues,
    repairMode: 'offline',
  };
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
  repairIdeaOffline,
  compareIdeas,
  HOOK_IDEA_FIELDS,
  CONTENT_JSON_PATH,
};
