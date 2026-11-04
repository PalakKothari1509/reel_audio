const fs = require('fs');
const path = require('path');
const { DIMENSIONS, SEVERITIES, computeWeightedScore, computeVerdict } = require('./schemas');

const CHARACTERS = ['Ria', 'Rio', 'Cuty', 'Mumma', 'Papa', 'Daadi', 'Robot', 'Teacher'];

function buildEmptyDimensionScores() {
  return DIMENSIONS.map(d => ({
    id: d.id,
    name: d.name,
    weight: d.weight,
    score: 0,
    explanation: '',
    whatWorks: '',
    needsImprovement: '',
  }));
}

function findDimension(dimensionScores, id) {
  return dimensionScores.find(d => d.id === id);
}

function setDimension(dimensionScores, id, score, explanation, whatWorks, needsImprovement) {
  const d = findDimension(dimensionScores, id);
  if (d) {
    d.score = Math.max(0, Math.min(10, score));
    d.explanation = explanation || '';
    d.whatWorks = whatWorks || '';
    d.needsImprovement = needsImprovement || '';
  }
}

function findUnsafeWords(text) {
  const unsafeWords = ['hit', 'slap', 'spank', 'punish', 'scary', 'terrifying', 'violent', 'blood', 'weapon'];
  return unsafeWords.filter(word => {
    const matches = text.matchAll(new RegExp(`\\b${word}\\b`, 'g'));
    for (const match of matches) {
      const before = text.slice(Math.max(0, match.index - 48), match.index);
      const after = text.slice(match.index + match[0].length, match.index + match[0].length + 48);
      if (/\b(?:no|not|never|without|avoid|avoiding|don't|doesn't|shouldn't)\s+(?:\w+\s+){0,2}$/i.test(before)) continue;
      if (word === 'hit' && /\b(?:the\s+)?(?:hit|hits|hitting)\s+of\b/i.test(match[0] + after)) continue;
      if (word === 'hit' && !/\b(?:hit|hits|hitting)\s+(?:(?:the|a|an)\s+)?(?:child|kid|baby|toddler|me|him|her|them|ria|rio|cuty|mumma|papa|daadi)\b|\b(?:child|kid|baby|toddler|ria|rio|cuty|mumma|papa|daadi)\s+(?:hit|hits|hitting)\b/i.test(before + match[0] + after)) continue;
      return true;
    }
    return false;
  });
}

// ── Offline heuristic engine ──────────────────────────────────────────

function offlineEvaluate(idea) {
  const dims = buildEmptyDimensionScores();
  const critical = [];
  const major = [];
  const minor = [];
  const suggestions = [];

  const title = idea.title || '';
  const cover = idea.cover || '';
  const opening = idea.opening || '';
  const problem = idea.problem || '';
  const hasProblem = problem.trim().length > 0 && !/^(?:n\/?a|none|not applicable)\b/i.test(problem.trim());
  const lesson = idea.lesson || '';
  const storyDetail = idea.storyDetail || '';
  const endingBeat = idea.endingBeat || '';
  const caption = idea.caption || '';
  const defaultCast = Array.isArray(idea.defaultCast) ? idea.defaultCast : [];
  const category = idea.category || '';
  const dialogue = idea.dialogue || '';

  const textBlob = `${title} ${cover} ${opening} ${problem} ${lesson} ${storyDetail} ${caption}`.toLowerCase();

  // ── Hook Strength ──
  let hookScore = 5;
  if (opening.length > 10) hookScore += 1;
  if (opening.includes('?') || opening.includes('!')) hookScore += 1;
  if (opening.length > 0 && opening.length < 120) hookScore += 1;
  if (opening.includes('?') && opening.length <= 90) hookScore += 1;
  if (opening.length === 0) hookScore -= 3;
  const hookFeedback = opening.length === 0
    ? 'Open on a specific action or choice from the story.'
    : opening.length > 100
      ? 'Trim the setup and keep the unresolved moment.'
      : !/[?!]/.test(opening)
        ? 'End on the story’s unresolved choice or consequence.'
        : '';
  setDimension(dims, 'hookStrength', hookScore,
    `Opening is ${opening.length} characters. ${opening.length === 0 ? 'Missing.' : opening.length > 100 ? 'Long for a first-line hook.' : opening.includes('?') ? 'Uses a question to open a curiosity loop.' : /[!]/.test(opening) ? 'Opens with an emphatic moment.' : 'Present.'}`,
    opening.length > 0 ? 'Opening line exists.' : 'No opening hook found.',
    hookFeedback);

  // ── Relatability ──
  let relScore = 5;
  const relatableWords = ['mumma', 'papa', 'daadi', 'teacher', 'relative', 'aunt', 'uncle', 'mum', 'dad'];
  const hasRelatable = relatableWords.some(w => textBlob.includes(w));
  const relatableContext = `${problem} ${idea.setting || ''} ${storyDetail}`;
  const everydayContext = /\b(at home|home|ghar|morning|breakfast|bedtime|getting ready|school|park|grocery|supermarket|shopping|mall|bath|bathroom|playtime|art time|drawing table|drawing room|dinner|lunch|dining table|snack time|snack table|kitchen|bedroom|living room|front door|shoe rack|parking|garba|navratri|festival|changing room|courtyard|daadi|grandma|laundry|checkout|classroom|playground|temple|street|market|society compound|meal|family time)\b/i.test(relatableContext);
  const isSeriesRecap = category === 'Series' && idea.postFormat === 'Carousel' && !hasProblem;
  const isAudiencePost = category === 'Series' && /feedback|audience/i.test(`${title} ${problem}`);
  if (hasRelatable) relScore += 1;
  if (hasProblem) relScore += 1;
  if (everydayContext) relScore += 1;
  if (category === 'Safety' || category === 'Learning Lesson') relScore += 1;
  if (!hasProblem && !isSeriesRecap && !isAudiencePost) relScore -= 2;
  const relatableFeedback = isSeriesRecap || isAudiencePost
    ? ''
    : !hasProblem
    ? 'Describe the child’s problem in a familiar family routine.'
    : !everydayContext
      ? 'Add one recognizable family routine or everyday setting to the problem or story.'
      : '';
  setDimension(dims, 'relatability', relScore,
    isSeriesRecap || isAudiencePost
      ? 'Audience-focused series format; a child problem is not required.'
      : `Problem described in ${hasProblem ? `${problem.length} characters` : 'not applicable'}. Family terms ${hasRelatable ? 'present' : 'not detected'}. Everyday routine ${everydayContext ? 'identified' : 'not identified'}.`,
    isSeriesRecap || isAudiencePost ? 'Audience-focused series format.' : hasProblem ? 'Real-world problem stated.' : 'No problem described.',
    relatableFeedback);

  // ── Story Structure ──
  const hasStory = storyDetail.length > 0;
  const hasTwist = /twist/i.test(storyDetail);
  const hasResolution = /resolution/i.test(storyDetail);
  const hasMoral = /moral/i.test(storyDetail);
  const hasEnding = endingBeat.length > 0;
  let storyScore = 3;
  if (hasStory) storyScore += 2;
  if (hasTwist) storyScore += 1;
  if (hasResolution) storyScore += 2;
  if (hasMoral) storyScore += 1;
  if (hasEnding) storyScore += 1;
  if (!hasStory) storyScore -= 2;
  const missingStoryParts = [
    !hasStory && 'Story',
    !hasTwist && 'Twist',
    !hasResolution && 'Resolution',
    !hasMoral && 'Moral',
    !hasEnding && 'endingBeat',
  ].filter(Boolean);
  setDimension(dims, 'storyStructure', Math.max(0, Math.min(10, storyScore)),
    `Story detail: ${hasStory ? 'present' : 'missing'}. Twist: ${hasTwist}. Resolution: ${hasResolution}. Moral: ${hasMoral}. Ending: ${hasEnding ? 'present' : 'missing'}.`,
    hasStory ? 'Story structure with labels detected.' : 'No story detail found.',
    missingStoryParts.length ? `Add or clarify: ${missingStoryParts.join(', ')}.` : '');

  // ── Age Appropriateness ──
  let ageScore = 6;
  const babyWords = ['ball', 'hug', 'chocolate', 'park', 'mumma', 'papa', 'daadi', 'teacher'];
  const hasBabyContent = babyWords.some(w => textBlob.includes(w));
  if (hasBabyContent) ageScore += 1;
  if (lesson.length > 0) ageScore += 1;
  if (category === 'Safety') ageScore += 1;
  if (lesson.length === 0) ageScore -= 1;
  const ageFeedback = lesson.length === 0
    ? 'Add one short, concrete action a toddler can understand.'
    : '';
  setDimension(dims, 'ageAppropriateness', ageScore,
    `Lesson: ${lesson.length > 0 ? 'present' : 'missing'}. Toddler-relevant terms: ${hasBabyContent ? 'present' : 'not detected'}.`,
    lesson.length > 0 ? 'A lesson is stated; the offline check does not judge its developmental fit.' : 'No lesson provided.',
    ageFeedback);

  // ── Hinglish Naturalness ──
  const hinglishMarkers = [
    'hai', 'hain', 'nahi', 'nahin', 'haan', 'beti', 'beta', 'dekho', 'sun', 'jao',
    'chalo', 'kyun', 'kaise', 'kya', 'kaunsa', 'karein', 'mujhe', 'tum', 'tumhein', 'aaj', 'mera', 'meri', 'chahiye',
    'accha', 'achha', 'theek', 'bas', 'phir', 'ab', 'yeh', 'woh', 'kar', 'karo',
    'gaya', 'gayi', 'ho', 'ek', 'aur',
  ];
  const dialogueBlob = `${textBlob} ${dialogue}`.toLowerCase();
  const hinglishCount = hinglishMarkers.filter(w => new RegExp(`\\b${w}\\b`).test(dialogueBlob)).length;
  let hScore = dialogue.length === 0 ? 8 : 5;
  if (dialogue.length > 0 && hinglishCount >= 2) hScore += 2;
  if (dialogue.length > 0 && hinglishCount === 1) hScore += 1;
  if (dialogue.length > 0) hScore += 1;
  setDimension(dims, 'hinglishNaturalness', Math.max(0, Math.min(10, hScore)),
    dialogue.length === 0
      ? 'No spoken dialogue; Hinglish naturalness is not applicable.'
      : `Hinglish markers found: ${hinglishCount}. Dialogue: present.`,
    dialogue.length === 0 ? 'No spoken dialogue to assess.' : hinglishCount > 0 ? 'Natural Hinglish elements detected.' : 'No Hinglish markers found.',
    dialogue.length > 0 && hinglishCount === 0 ? 'Use a familiar spoken phrase in the dialogue, such as “chalo” or “koi baat nahi.”' : '');

  // ── Character Consistency ──
  const castValid = defaultCast.length > 0 && defaultCast.every(c => CHARACTERS.includes(c));
  const unknownCast = defaultCast.filter(c => !CHARACTERS.includes(c));
  const characterText = [title, opening, problem, storyDetail, endingBeat, dialogue].join(' ').toLowerCase();
  const mentionedCharacters = CHARACTERS.filter(c => new RegExp(`\\b${c.toLowerCase()}\\b`).test(characterText));
  const missingCast = idea.archived ? [] : mentionedCharacters.filter(c => !defaultCast.includes(c));
  const charScore = defaultCast.length === 0 ? 3 : !castValid ? 4 : missingCast.length > 0 ? 6 : 9;
  setDimension(dims, 'characterConsistency', Math.max(0, Math.min(10, charScore)),
    `Cast: ${defaultCast.join(', ') || 'none'}. Valid characters: ${castValid ? 'yes' : 'no'}. Characters named in content: ${mentionedCharacters.join(', ') || 'none'}. Missing from cast: ${missingCast.join(', ') || 'none'}.`,
    !castValid ? 'Some cast names are not from the approved character list.' : missingCast.length === 0 ? 'All named characters are included in the approved cast.' : `Cast is missing: ${missingCast.join(', ')}.`,
    !castValid ? 'Use only defined characters: Ria, Rio, Cuty, Mumma, Papa, Daadi, Robot, Teacher.' : missingCast.length > 0 ? `Add ${missingCast.join(', ')} to defaultCast.` : '');

  // ── Visual Feasibility ──
  let visScore = 5;
  if (idea.setting && idea.setting.length > 0) visScore += 1;
  if (idea.sceneDetail && idea.sceneDetail.length > 0) visScore += 1;
  if (category !== 'Safety') visScore += 1; // safety can be harder to visualize gently
  if (!idea.setting || idea.setting.length === 0) visScore -= 1;
  if (!idea.sceneDetail || idea.sceneDetail.length === 0) visScore -= 1;
  const visualFeedback = !idea.setting
    ? 'Name the location and time of day.'
    : !idea.sceneDetail
      ? 'Describe the visible action, prop, and ending image.'
      : '';
  setDimension(dims, 'visualFeasibility', Math.max(0, Math.min(10, visScore)),
    `Setting: ${idea.setting && idea.setting.length > 0 ? 'present' : 'missing'}. Scene detail: ${idea.sceneDetail && idea.sceneDetail.length > 0 ? 'present' : 'missing'}.`,
    idea.setting && idea.setting.length > 0 ? 'Location described.' : 'No setting provided.',
    visualFeedback);

  // ── Sound-Off Readability ──
  const hasCaption = caption.length > 0;
  const hasPinned = idea.pinnedComment && idea.pinnedComment.length > 0;
  let soundScore = 4;
  if (hasCaption) soundScore += 2;
  if (hasPinned) soundScore += 1;
  if (dialogue.length > 0) soundScore += 1;
  if (!hasCaption) soundScore -= 1;
  const soundFeedback = !hasCaption
    ? 'Add a caption that communicates the story without audio.'
    : caption.length > 300
      ? `Trim the ${caption.length}-character caption to its key takeaway and question.`
      : '';
  setDimension(dims, 'soundOffReadability', soundScore,
    `Caption: ${hasCaption ? `present (${caption.length} characters)` : 'missing'}. Pinned comment: ${hasPinned ? 'present' : 'missing'}.`,
    hasCaption ? 'Caption available for sound-off viewing.' : 'No caption found.',
    soundFeedback);

  // ── Engagement Potential ──
  let engScore = 5;
  if (hasProblem) engScore += 1;
  if (lesson.length > 0) engScore += 1;
  if (category === 'Safety' || category === 'Funny') engScore += 1;
  if (idea.pinnedComment && idea.pinnedComment.length > 0) engScore += 1;
  const hasEngagementQuestion = /\?/.test(caption) || /\?/.test(idea.pinnedComment || '');
  const engagementFeedback = isSeriesRecap || isAudiencePost
    ? !hasEngagementQuestion ? 'Ask a specific question that invites audience input.' : ''
    : !hasProblem
      ? 'Define the specific situation the story addresses.'
      : !hasEngagementQuestion ? 'Ask viewers a specific question about this story or routine in the caption or pinned comment.' : '';
  setDimension(dims, 'engagementPotential', engScore,
    `Problem: ${isSeriesRecap || isAudiencePost ? 'not applicable (audience-focused format)' : hasProblem}. Lesson: ${lesson.length > 0}. Discussion question: ${hasEngagementQuestion ? 'present' : 'missing'}.`,
    isSeriesRecap || isAudiencePost ? 'Audience-focused format.' : hasProblem ? 'Clear problem drives engagement.' : 'No problem stated.',
    engagementFeedback);

  // ── Brand and Safety ──
  let brandScore = 7;
  const detectedUnsafeWords = findUnsafeWords(textBlob);
  const hasUnsafe = detectedUnsafeWords.length > 0;
  if (hasUnsafe) brandScore -= 3;
  if (category === 'Safety') brandScore += 1;
  if (lesson.length > 0 && lesson.toLowerCase().includes('respect')) brandScore += 1;
  if (lesson.length === 0) brandScore -= 1;
  setDimension(dims, 'brandAndSafety', Math.max(0, Math.min(10, brandScore)),
    `Unsafe language: ${hasUnsafe ? 'detected' : 'none'}. Lesson: ${lesson.length > 0 ? 'present' : 'missing'}.`,
    !hasUnsafe ? 'No unsafe behavior detected.' : 'Potentially unsafe language found.',
    hasUnsafe ? `Review the context around: ${detectedUnsafeWords.join(', ')}.` : lesson.length === 0 ? 'Add a positive, respectful lesson.' : '');

  // ── Critical findings ──
  if (hasUnsafe) {
    critical.push({
      title: 'Potentially unsafe language detected',
      severity: 'critical',
      explanation: `Text contains words that may depict unsafe behavior: ${detectedUnsafeWords.join(', ')}`,
      evidence: textBlob,
      suggestedFix: 'Reframe to teach safe behavior rather than depicting unsafe acts.',
    });
  }
  if (!hasStory && category === 'Safety') {
    critical.push({
      title: 'Safety idea missing story structure',
      severity: 'critical',
      explanation: 'Safety content requires a clear Story/Twist/Resolution/Moral structure to model correct behavior.',
      evidence: 'storyDetail is empty',
      suggestedFix: 'Add a complete story with labels showing the safe behavior and adult response.',
    });
  }

  // ── Major findings ──
  if (!hasStory) {
    major.push({
      title: 'Missing story structure',
      severity: 'major',
      explanation: 'No Story/Twist/Resolution/Moral labels found in storyDetail.',
      evidence: 'storyDetail is empty',
      suggestedFix: 'Add labeled story sections so the narrative arc is clear.',
    });
  }
  if (!hasEnding) {
    major.push({
      title: 'Missing ending beat',
      severity: 'major',
      explanation: 'No endingBeat defined — the story lacks a closing visual.',
      evidence: 'endingBeat is empty',
      suggestedFix: 'Add a final image or action that resolves the scene.',
    });
  }
  if (defaultCast.length === 0) {
    major.push({
      title: 'No character cast defined',
      severity: 'major',
      explanation: 'defaultCast is empty, making character consistency impossible to verify.',
      evidence: 'defaultCast is an empty array',
      suggestedFix: 'Add 1-3 characters from the approved cast (Ria, Rio, Cuty, Mumma, Papa, Daadi, Robot, Teacher).',
    });
  }

  // ── Minor findings ──
  if (!hasCaption) {
    minor.push({
      title: 'Missing caption',
      severity: 'minor',
      explanation: 'No Instagram caption provided.',
      evidence: 'caption is empty',
      suggestedFix: 'Write a caption with relevant hashtags for the post.',
    });
  }
  if (!hasPinned) {
    minor.push({
      title: 'Missing pinned comment',
      severity: 'minor',
      explanation: 'No pinned comment to drive engagement.',
      evidence: 'pinnedComment is empty',
      suggestedFix: 'Add a question or tip as a pinned comment.',
    });
  }
  if (opening.length > 0 && opening.length > 100) {
    minor.push({
      title: 'Opening hook may be too long',
      severity: 'minor',
      explanation: `Opening is ${opening.length} characters — may lose attention in the first 3 seconds.`,
      evidence: `opening length: ${opening.length}`,
      suggestedFix: 'Shorten the opening to under 100 characters for impact.',
    });
  }

  // Suggestions are emitted only when the evaluator can offer a concrete replacement.
  if (!opening && problem) {
    suggestions.push({
      title: 'Add an opening hook',
      explanation: 'The idea has no opening line; use its concrete problem as the starting moment.',
      original: '',
      suggested: problem,
    });
  }
  if (!lesson && endingBeat) {
    suggestions.push({
      title: 'Add a lesson',
      explanation: 'The story has an ending but no stated takeaway.',
      original: '',
      suggested: `After ${endingBeat.charAt(0).toLowerCase()}${endingBeat.slice(1)}`,
    });
  }

  const overallScore = computeWeightedScore(dims);
  const verdict = computeVerdict(overallScore);
  const capped = critical.length > 0 && overallScore > 59;
  const finalScore = capped ? 59 : overallScore;
  const finalVerdict = capped ? 'Needs Major Rewrite' : verdict;

  return {
    ideaId: idea.id,
    dimensionScores: dims,
    overallScore: finalScore,
    rawScore: overallScore,
    scoreCapped: capped,
    verdict: finalVerdict,
    criticalFindings: critical,
    majorFindings: major,
    minorFindings: minor,
    suggestions,
    evaluationMode: 'offline',
    evaluatedAt: new Date().toISOString(),
    evaluationVersion: '1.2.0-offline',
  };
}

// ── Online (Gemini) evaluation ────────────────────────────────────────

async function onlineEvaluate(idea, geminiApiKey) {
  const fetch = (await import('node-fetch')).default;
  const apiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent';

  const prompt = `
You are a content quality evaluator for "Fun Learning With Palak" — Instagram Reels for Indian parents of children aged 1-4.

Evaluate the following idea on these 10 dimensions (score each 0-10):
1. Hook Strength (15%)
2. Relatability (15%)
3. Story Structure (12%)
4. Age Appropriateness (10%)
5. Hinglish Naturalness (10%)
6. Character Consistency (8%)
7. Visual Feasibility (8%)
8. Sound-Off Readability (7%)
9. Engagement Potential (8%)
10. Brand and Safety (7%)

Also identify:
- Critical findings (safety violations, unsafe behavior as good, scary content, character contradictions, no resolution, preachy delivery, child blame/shame, inappropriate touching, uncalm adult response, scary language in safety content)
- Major findings
- Minor findings
- Suggestions (improved hook, story improvements, improved ending, improved moral, caption suggestions)

Return ONLY valid JSON with this exact structure:
{
  "ideaId": "${idea.id}",
  "dimensionScores": [
    {"id": "hookStrength", "score": N, "explanation": "...", "whatWorks": "...", "needsImprovement": "..."},
    ... (all 10 dimensions)
  ],
  "criticalFindings": [
    {"title": "...", "explanation": "...", "evidence": "...", "suggestedFix": "..."}
  ],
  "majorFindings": [...],
  "minorFindings": [...],
  "suggestions": [
    {"title": "...", "explanation": "...", "original": "...", "suggested": "..."}
  ],
  "improvedHook": "...",
  "storyImprovements": "...",
  "improvedCaption": "..."
}

Idea to evaluate:
ID: ${idea.id}
Title: ${idea.title}
Category: ${idea.category}
Cover: ${idea.cover}
Opening: ${idea.opening}
Problem: ${idea.problem}
Lesson: ${idea.lesson}
Story Detail: ${idea.storyDetail}
Ending Beat: ${idea.endingBeat}
Caption: ${idea.caption}
Pinned Comment: ${idea.pinnedComment}
Dialogue: ${idea.dialogue}
Default Cast: ${JSON.stringify(idea.defaultCast)}
Setting: ${idea.setting}
Scene Detail: ${idea.sceneDetail}
`;

  const body = {
    contents: [{ parts: [{ text: prompt }] }],
    generationConfig: {
      temperature: 0.3,
      maxOutputTokens: 4000,
    },
  };

  let lastError = null;
  for (let attempt = 0; attempt < 2; attempt++) {
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

      // Extract JSON from markdown code blocks if present
      let jsonText = text.trim();
      const jsonMatch = jsonText.match(/```json\n([\s\S]*?)\n```/) || jsonText.match(/```([\s\S]*?)```/) || [null, jsonText];
      jsonText = jsonMatch[1] || jsonText;

      try {
        const parsed = JSON.parse(jsonText);
        return parsed;
      } catch (e) {
        lastError = `Invalid JSON: ${e.message}`;
        if (attempt === 0) continue;
        throw new Error(lastError);
      }
    } catch (e) {
      lastError = e.message;
      if (attempt === 0) {
        await new Promise(r => setTimeout(r, 2000));
        continue;
      }
      throw e;
    }
  }
  throw new Error(lastError || 'Unknown Gemini error');
}

function buildOnlineResult(idea, geminiResponse) {
  const { validateGeminiResponse, computeWeightedScore, computeVerdict } = require('./schemas');
  const validation = validateGeminiResponse(geminiResponse);
  if (!validation.valid) {
    throw new Error(`Gemini response validation failed: ${validation.error}`);
  }

  const dims = geminiResponse.dimensionScores.map(d => ({
    id: d.id,
    name: DIMENSIONS.find(x => x.id === d.id)?.name || d.id,
    weight: DIMENSIONS.find(x => x.id === d.id)?.weight || 0,
    score: d.score,
    explanation: d.explanation,
    whatWorks: d.whatWorks,
    needsImprovement: d.needsImprovement,
  }));

  const overallScore = computeWeightedScore(dims);
  const verdict = computeVerdict(overallScore);
  const criticalCount = geminiResponse.criticalFindings?.length || 0;
  const capped = criticalCount > 0 && overallScore > 59;
  const finalScore = capped ? 59 : overallScore;
  const finalVerdict = capped ? 'Needs Major Rewrite' : verdict;

  return {
    ideaId: idea.id,
    dimensionScores: dims,
    overallScore: finalScore,
    rawScore: overallScore,
    scoreCapped: capped,
    verdict: finalVerdict,
    criticalFindings: geminiResponse.criticalFindings || [],
    majorFindings: geminiResponse.majorFindings || [],
    minorFindings: geminiResponse.minorFindings || [],
    suggestions: geminiResponse.suggestions || [],
    improvedHook: geminiResponse.improvedHook || '',
    storyImprovements: geminiResponse.storyImprovements || '',
    improvedCaption: geminiResponse.improvedCaption || '',
    evaluationMode: 'online',
    evaluatedAt: new Date().toISOString(),
    evaluationVersion: '1.0.0-online',
  };
}

module.exports = { buildEmptyDimensionScores, offlineEvaluate, onlineEvaluate, buildOnlineResult, CHARACTERS };
