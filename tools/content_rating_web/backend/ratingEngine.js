const fs = require('fs');
const path = require('path');
const {
  DIMENSIONS,
  GATES,
  GATE_IDS,
  SEVERITIES,
  VERDICTS,
  CRITICAL_CAP,
  ADDITIONAL_CAPS,
  DETERMINISTIC_CHECKS,
  CALIBRATION,
  PERFORMANCE_FEEDBACK,
  AUDIENCE,
  SCORING,
  validateDimensionScore,
  validateDimension,
  validateFinding,
  validateGateResult,
  validateFixToReach10,
  validateDeterministicCheckResult,
  validateGeminiResponse,
  computeWeightedScore,
  computeVerdict,
  isCriticalCapEnabled,
  getCriticalCapThreshold,
  getCriticalCapScore,
  getCriticalCapVerdict,
  getDimensionCount,
  getDimensionById,
  getGateById,
  getVerdictByLabel,
  getVerdictRequires,
} = require('./schemas');
const { runAllChecks } = require('./deterministicChecks');

function buildEmptyDimensionScores() {
  return DIMENSIONS.map(d => ({
    id: d.id,
    name: d.name,
    weight: d.weight,
    score: 0,
    anchorMatched: '2',
    explanation: '',
    whatWorks: '',
    needsImprovement: '',
  }));
}

function findDimension(dimensionScores, id) {
  return dimensionScores.find(d => d.id === id);
}

function setDimension(dimensionScores, id, score, anchorMatched, explanation, whatWorks, needsImprovement) {
  const d = findDimension(dimensionScores, id);
  if (d) {
    d.score = Math.max(0, Math.min(10, score));
    d.anchorMatched = anchorMatched || '2';
    d.explanation = explanation || '';
    d.whatWorks = whatWorks || '';
    d.needsImprovement = needsImprovement || '';
  }
}

function evaluateGates(idea, deterministicResults) {
  const gateResults = [];
  for (const gate of GATES) {
    const checksForGate = deterministicResults.filter(c => c.gate === gate.id);
    const criticalFailures = checksForGate.filter(c => !c.passed && c.severity === 'critical');
    const majorFailures = checksForGate.filter(c => !c.passed && c.severity === 'major');
    const minorFailures = checksForGate.filter(c => !c.passed && c.severity === 'minor');
    const suggestionFailures = checksForGate.filter(c => !c.passed && c.severity === 'suggestion');

    let passed = true;
    let detail = 'All deterministic checks passed';
    if (criticalFailures.length > 0) {
      passed = false;
      detail = `Critical failures: ${criticalFailures.map(c => c.id).join(', ')}`;
    } else if (majorFailures.length > 0) {
      passed = false;
      detail = `Major failures: ${majorFailures.map(c => c.id).join(', ')}`;
    } else if (minorFailures.length > 0) {
      detail = `Minor issues: ${minorFailures.map(c => c.id).join(', ')}`;
    } else if (suggestionFailures.length > 0) {
      detail = `Suggestions: ${suggestionFailures.map(c => c.id).join(', ')}`;
    }

    gateResults.push({
      id: gate.id,
      name: gate.name,
      passed,
      severityOnFail: gate.severityOnFail,
      detail,
    });
  }
  return gateResults;
}

function applyCaps(rawScore, criticalFindings, gateResults) {
  const capsApplied = [];
  let cappedScore = rawScore;
  let cappedVerdict = null;

  if (isCriticalCapEnabled() && criticalFindings.length > 0 && rawScore > getCriticalCapThreshold()) {
    cappedScore = Math.min(cappedScore, getCriticalCapScore());
    cappedVerdict = getCriticalCapVerdict();
    capsApplied.push('criticalCap');
  }

  for (const cap of ADDITIONAL_CAPS) {
    if (!cap.enabled) continue;
    let conditionMet = false;
    if (cap.condition.includes('gate') && cap.condition.includes('critical')) {
      const criticalGateFailed = gateResults.some(g => !g.passed && g.severityOnFail === 'critical');
      conditionMet = criticalGateFailed;
    } else if (cap.condition.includes('gate') && cap.condition.includes('major')) {
      const majorGateFailed = gateResults.some(g => !g.passed && g.severityOnFail === 'major');
      conditionMet = majorGateFailed && rawScore > 79;
    }
    if (conditionMet) {
      cappedScore = Math.min(cappedScore, cap.cappedScore);
      if (cap.cappedVerdict) {
        cappedVerdict = cap.cappedVerdict;
      }
      capsApplied.push(cap.id);
    }
  }

  return { cappedScore, cappedVerdict, capsApplied };
}

function determineVerdict(overallScore, criticalFindings, majorFindings, capsApplied, cappedVerdict) {
  if (cappedVerdict) return cappedVerdict;

  let verdict = computeVerdict(overallScore);

  if (verdict === 'Ready to Post') {
    const requires = getVerdictRequires('Ready to Post');
    const hookScore = overallScore >= 80 ? 7 : 0;
    const payoffScore = overallScore >= 80 ? 6 : 0;
    if (criticalFindings.length > requires.criticalFindingsMax ||
        majorFindings.length > requires.majorFindingsMax) {
      verdict = 'Needs Minor Fixes';
    }
  }

  return verdict;
}

function buildFixesToReach10(dimensionScores, rawScore) {
  const scoredDimensions = dimensionScores
    .filter(d => d.score < 10)
    .map(d => {
      const gain = Math.round(((10 - d.score) / 10) * d.weight);
      return {
        fix: d.needsImprovement || `Improve ${d.name} from ${d.score} to 10`,
        dimensionId: d.id,
        estimatedGain: gain,
      };
    })
    .sort((a, b) => b.estimatedGain - a.estimatedGain);

  const potentialScore = Math.min(100, rawScore + scoredDimensions.reduce((sum, d) => sum + d.estimatedGain, 0));

  return { fixesToReach10: scoredDimensions, potentialScore };
}

function getRewrittenHook(idea, dimensionScores) {
  const hookDim = findDimension(dimensionScores, 'hookStrength');
  if (hookDim && hookDim.score < 7 && idea.problem) {
    return `Open on the moment: ${idea.problem.slice(0, 80)}...?`;
  }
  if (hookDim && hookDim.score < 7 && idea.opening) {
    return `Trim to: "${idea.opening.slice(0, 80)}?"`;
  }
  return idea.opening || 'Add a visual hook in the first 3 seconds';
}

function getRecommendedFormat(idea, gateResults, duplicateOf) {
  const formatFitGate = gateResults.find(g => g.id === 'formatFit');
  const postFormat = idea.postFormat || 'Reel';
  if (duplicateOf.length > 0) return 'merge-into-series';
  if (formatFitGate && !formatFitGate.passed) {
    if (postFormat === 'Carousel') return 'reel';
    if (postFormat === 'Story') return 'carousel';
  }
  return postFormat.toLowerCase();
}

function buildOfflineDimensionScores(idea, deterministicResults) {
  const dims = buildEmptyDimensionScores();

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
  const setting = idea.setting || '';
  const sceneDetail = idea.sceneDetail || '';
  const pinnedComment = idea.pinnedComment || '';

  const textBlob = `${title} ${cover} ${opening} ${problem} ${lesson} ${storyDetail} ${caption}`.toLowerCase();

  const isSeriesRecap = category === 'Series' && idea.postFormat === 'Carousel' && !hasProblem;
  const isAudiencePost = category === 'Series' && /feedback|audience/i.test(`${title} ${problem}`);

  let hookScore = 5;
  let hookAnchor = '6';
  if (opening.length > 10) hookScore += 1;
  if (opening.includes('?') || opening.includes('!')) hookScore += 1;
  if (opening.length > 0 && opening.length < 120) hookScore += 1;
  if (opening.includes('?') && opening.length <= 90) hookScore += 1;
  if (opening.length === 0) { hookScore -= 3; hookAnchor = '2'; }
  else if (opening.length > 100) { hookAnchor = '6'; }
  else if (/[?!]/.test(opening)) { hookAnchor = '10'; }
  const hookFeedback = opening.length === 0
    ? 'Open on a specific action or choice from the story.'
    : opening.length > 100
      ? 'Trim the setup and keep the unresolved moment.'
      : !/[?!]/.test(opening)
        ? 'End on the story\'s unresolved choice or consequence.'
        : '';
  setDimension(dims, 'hookStrength', hookScore, hookAnchor,
    `Opening is ${opening.length} characters. ${opening.length === 0 ? 'Missing.' : opening.length > 100 ? 'Long for a first-line hook.' : opening.includes('?') ? 'Uses a question to open a curiosity loop.' : /[!]/.test(opening) ? 'Opens with an emphatic moment.' : 'Present.'}`,
    opening.length > 0 ? 'Opening line exists.' : 'No opening hook found.',
    hookFeedback);

  let relScore = 5;
  let relAnchor = '6';
  const relatableWords = ['mumma', 'papa', 'daadi', 'teacher', 'relative', 'aunt', 'uncle', 'mum', 'dad'];
  const hasRelatable = relatableWords.some(w => textBlob.includes(w));
  const relatableContext = `${problem} ${setting} ${storyDetail}`;
  const everydayContext = /\b(at home|home|ghar|morning|breakfast|bedtime|getting ready|school|park|grocery|supermarket|shopping|mall|bath|bathroom|playtime|art time|drawing table|drawing room|dinner|lunch|dining table|snack time|snack table|kitchen|bedroom|living room|front door|shoe rack|parking|garba|navratri|festival|changing room|courtyard|daadi|grandma|laundry|checkout|classroom|playground|temple|street|market|society compound|meal|family time)\b/i.test(relatableContext);
  if (isSeriesRecap || isAudiencePost) { relScore = 8; relAnchor = '10'; }
  else {
    if (hasRelatable) relScore += 1;
    if (hasProblem) relScore += 1;
    if (everydayContext) relScore += 1;
    if (category === 'Safety' || category === 'Learning Lesson') relScore += 1;
    if (!hasProblem && !isSeriesRecap && !isAudiencePost) { relScore -= 2; relAnchor = '2'; }
    else if (hasProblem && everydayContext) { relAnchor = '10'; }
  }
  const relatableFeedback = isSeriesRecap || isAudiencePost
    ? ''
    : !hasProblem
      ? 'Describe the child\'s problem in a familiar family routine.'
      : !everydayContext
        ? 'Add one recognizable family routine or everyday setting to the problem or story.'
        : '';
  setDimension(dims, 'relatabilityAudienceFit', relScore, relAnchor,
    isSeriesRecap || isAudiencePost
      ? 'Audience-focused series format; a child problem is not required.'
      : `Problem described in ${hasProblem ? `${problem.length} characters` : 'not applicable'}. Family terms ${hasRelatable ? 'present' : 'not detected'}. Everyday routine ${everydayContext ? 'identified' : 'not identified'}.`,
    isSeriesRecap || isAudiencePost ? 'Audience-focused series format.' : hasProblem ? 'Real-world problem stated.' : 'No problem described.',
    relatableFeedback);

  const hasStory = storyDetail.length > 0;
  const hasTwist = /twist/i.test(storyDetail);
  const hasResolution = /resolution/i.test(storyDetail);
  const hasMoral = /moral/i.test(storyDetail);
  const hasEnding = endingBeat.length > 0;
  let storyScore = 3;
  let storyAnchor = '2';
  if (hasStory) { storyScore += 2; storyAnchor = '6'; }
  if (hasTwist) storyScore += 1;
  if (hasResolution) { storyScore += 2; storyAnchor = '10'; }
  if (hasMoral) storyScore += 1;
  if (hasEnding) storyScore += 1;
  if (!hasStory) { storyScore -= 2; storyAnchor = '2'; }
  const missingStoryParts = [
    !hasStory && 'Story',
    !hasTwist && 'Twist',
    !hasResolution && 'Resolution',
    !hasMoral && 'Moral',
    !hasEnding && 'endingBeat',
  ].filter(Boolean);
  setDimension(dims, 'payoffRetention', Math.max(0, Math.min(10, storyScore)), storyAnchor,
    `Story detail: ${hasStory ? 'present' : 'missing'}. Twist: ${hasTwist}. Resolution: ${hasResolution}. Moral: ${hasMoral}. Ending: ${hasEnding ? 'present' : 'missing'}.`,
    hasStory ? 'Story structure with labels detected.' : 'No story detail found.',
    missingStoryParts.length ? `Add or clarify: ${missingStoryParts.join(', ')}.` : '');

  const hinglishMarkers = [
    'hai', 'hain', 'nahi', 'nahin', 'haan', 'beti', 'beta', 'dekho', 'sun', 'jao',
    'chalo', 'kyun', 'kaise', 'kya', 'kaunsa', 'karein', 'mujhe', 'tum', 'tumhein', 'aaj', 'mera', 'meri', 'chahiye',
    'accha', 'achha', 'theek', 'bas', 'phir', 'ab', 'yeh', 'woh', 'kar', 'karo',
    'gaya', 'gayi', 'ho', 'ek', 'aur',
  ];
  const dialogueBlob = `${textBlob} ${dialogue}`.toLowerCase();
  const hinglishCount = hinglishMarkers.filter(w => new RegExp(`\\b${w}\\b`).test(dialogueBlob)).length;
  let hScore = dialogue.length === 0 ? 8 : 5;
  let hAnchor = dialogue.length === 0 ? '10' : '6';
  if (dialogue.length > 0 && hinglishCount >= 2) { hScore += 2; hAnchor = '10'; }
  else if (dialogue.length > 0 && hinglishCount === 1) { hScore += 1; hAnchor = '6'; }
  if (dialogue.length > 0) hScore += 1;
  setDimension(dims, 'hinglishNaturalness', Math.max(0, Math.min(10, hScore)), hAnchor,
    dialogue.length === 0
      ? 'No spoken dialogue; Hinglish naturalness is not applicable.'
      : `Hinglish markers found: ${hinglishCount}. Dialogue: present.`,
    dialogue.length === 0 ? 'No spoken dialogue to assess.' : hinglishCount > 0 ? 'Natural Hinglish elements detected.' : 'No Hinglish markers found.',
    dialogue.length > 0 && hinglishCount === 0 ? 'Use a familiar spoken phrase in the dialogue, such as "chalo" or "koi baat nahi".' : '');

  let visScore = 5;
  let visAnchor = '6';
  if (setting && setting.length > 0) visScore += 1;
  if (sceneDetail && sceneDetail.length > 0) visScore += 1;
  if (category !== 'Safety') visScore += 1;
  if (!setting || setting.length === 0) visScore -= 1;
  if (!sceneDetail || sceneDetail.length === 0) visScore -= 1;
  if (setting && sceneDetail && category !== 'Safety') visAnchor = '10';
  const visualFeedback = !setting
    ? 'Name the location and time of day.'
    : !sceneDetail
      ? 'Describe the visible action, prop, and ending image.'
      : '';
  setDimension(dims, 'visualFeasibility', Math.max(0, Math.min(10, visScore)), visAnchor,
    `Setting: ${setting && setting.length > 0 ? 'present' : 'missing'}. Scene detail: ${sceneDetail && sceneDetail.length > 0 ? 'present' : 'missing'}.`,
    setting && setting.length > 0 ? 'Location described.' : 'No setting provided.',
    visualFeedback);

  const hasCaption = caption.length > 0;
  const hasPinned = pinnedComment && pinnedComment.length > 0;
  let soundScore = 4;
  let soundAnchor = '6';
  if (hasCaption) soundScore += 2;
  if (hasPinned) soundScore += 1;
  if (dialogue.length > 0) soundScore += 1;
  if (!hasCaption) { soundScore -= 1; soundAnchor = '2'; }
  else if (hasCaption && hasPinned) soundAnchor = '10';
  const soundFeedback = !hasCaption
    ? 'Add a caption that communicates the story without audio.'
    : caption.length > 300
      ? `Trim the ${caption.length}-character caption to its key takeaway and question.`
      : '';
  setDimension(dims, 'soundOffReadability', soundScore, soundAnchor,
    `Caption: ${hasCaption ? `present (${caption.length} characters)` : 'missing'}. Pinned comment: ${hasPinned ? 'present' : 'missing'}.`,
    hasCaption ? 'Caption available for sound-off viewing.' : 'No caption found.',
    soundFeedback);

  let engScore = 5;
  let engAnchor = '6';
  if (hasProblem) engScore += 1;
  if (lesson.length > 0) engScore += 1;
  if (category === 'Safety' || category === 'Funny') engScore += 1;
  if (pinnedComment && pinnedComment.length > 0) engScore += 1;
  const hasEngagementQuestion = /\?/.test(caption) || /\?/.test(pinnedComment || '');
  const engagementFeedback = isSeriesRecap || isAudiencePost
    ? !hasEngagementQuestion ? 'Ask a specific question that invites audience input.' : ''
    : !hasProblem
      ? 'Define the specific situation the story addresses.'
      : !hasEngagementQuestion ? 'Ask viewers a specific question about this story or routine in the caption or pinned comment.' : '';
  if (hasProblem && hasEngagementQuestion) engAnchor = '10';
  setDimension(dims, 'shareSaveTrigger', engScore, engAnchor,
    `Problem: ${isSeriesRecap || isAudiencePost ? 'not applicable (audience-focused format)' : hasProblem}. Lesson: ${lesson.length > 0}. Discussion question: ${hasEngagementQuestion ? 'present' : 'missing'}.`,
    isSeriesRecap || isAudiencePost ? 'Audience-focused format.' : hasProblem ? 'Clear problem drives engagement.' : 'No problem stated.',
    engagementFeedback);

  let capScore = 5;
  let capAnchor = '6';
  if (hasCaption) capScore += 1;
  if (hasPinned) capScore += 1;
  const hashtags = caption.match(/#[^\s#]+/g) || [];
  if (hashtags.length >= 3 && hashtags.length <= 5) capScore += 1;
  const pinnedGeneric = deterministicResults.find(c => c.id === 'genericPinnedComment');
  if (hasPinned && !pinnedGeneric.passed) capScore -= 1;
  if (!hasCaption) { capScore -= 2; capAnchor = '2'; }
  else if (hasCaption && hasPinned && hashtags.length >= 3 && hashtags.length <= 5 && (!pinnedGeneric || pinnedGeneric.passed)) capAnchor = '10';
  setDimension(dims, 'captionCommentPackage', Math.max(0, Math.min(10, capScore)), capAnchor,
    `Caption: ${hasCaption ? `present (${caption.length} chars, ${hashtags.length} hashtags)` : 'missing'}. Pinned: ${hasPinned ? 'present' : 'missing'}.`,
    hasCaption ? 'Caption with hashtags present.' : 'No caption found.',
    !hasCaption ? 'Add a caption with 3-5 hashtags.' : !hasPinned ? 'Add a pinned comment.' : pinnedGeneric && !pinnedGeneric.passed ? 'Replace generic pinned comment with specific question.' : '');

  let origScore = 8;
  let origAnchor = '10';
  const dupCheck = deterministicResults.find(c => c.id === 'duplicateSimilarity');
  if (dupCheck && !dupCheck.passed) { origScore = 3; origAnchor = '2'; }
  else if (dupCheck && dupCheck.detail.includes('similarity')) {
    const simMatch = dupCheck.detail.match(/(\d\.\d+)/);
    if (simMatch && parseFloat(simMatch[1]) > 0.5) { origScore = 5; origAnchor = '6'; }
  }
  setDimension(dims, 'originality', Math.max(0, Math.min(10, origScore)), origAnchor,
    dupCheck ? dupCheck.detail : 'Duplicate check not run',
    dupCheck && dupCheck.passed ? 'No near-duplicates detected.' : 'Original concept.',
    dupCheck && !dupCheck.passed ? 'Differentiate from similar ideas in library.' : '');

  let audioScore = 5;
  let audioAnchor = '6';
  if (dialogue.length > 0 && opening.length > 0) { audioScore += 2; audioAnchor = '10'; }
  else if (dialogue.length > 0) audioScore += 1;
  setDimension(dims, 'audioHook', Math.max(0, Math.min(10, audioScore)), audioAnchor,
    `Opening dialogue: ${dialogue.length > 0 ? 'present' : 'missing'}. Opening text: ${opening.length > 0 ? 'present' : 'missing'}.`,
    dialogue.length > 0 ? 'Audio hook present.' : 'No dialogue for audio hook.',
    dialogue.length === 0 ? 'Add a sound effect or dialogue line for the first 3 seconds.' : '');

  return dims;
}

function buildOfflineFindings(idea, deterministicResults) {
  const critical = [];
  const major = [];
  const minor = [];
  const suggestions = [];

  for (const check of deterministicResults) {
    if (!check.passed) {
      const finding = {
        title: check.id.replace(/([A-Z])/g, ' $1').replace(/^./, str => str.toUpperCase()),
        severity: check.severity,
        explanation: check.detail,
        evidence: `Check: ${check.id}`,
        suggestedFix: getFixForCheck(check.id, idea),
      };
      if (check.severity === 'critical') critical.push(finding);
      else if (check.severity === 'major') major.push(finding);
      else if (check.severity === 'minor') minor.push(finding);
      else if (check.severity === 'suggestion') suggestions.push(finding);
    }
  }

  const unsafeWords = findUnsafeWords(idea);
  if (unsafeWords.length > 0) {
    critical.push({
      title: 'Potentially unsafe language detected',
      severity: 'critical',
      explanation: `Text contains words that may depict unsafe behavior: ${unsafeWords.join(', ')}`,
      evidence: `${idea.title} ${idea.opening} ${idea.problem} ${idea.storyDetail}`.toLowerCase(),
      suggestedFix: 'Reframe to teach safe behavior rather than depicting unsafe acts.',
    });
  }

  if (!deterministicResults.find(c => c.id === 'missingFields')?.passed) {
    major.push({
      title: 'Missing required fields',
      severity: 'major',
      explanation: 'Required fields (readyPrompt, caption, pinnedComment) are empty',
      evidence: 'missingFields check failed',
      suggestedFix: 'Fill in all required fields before evaluation.',
    });
  }

  if (suggestions.length === 0 && idea.opening && idea.problem && !idea.opening.includes('?')) {
    suggestions.push({
      title: 'Add an opening hook',
      explanation: 'The idea has no opening line; use its concrete problem as the starting moment.',
      original: '',
      suggested: idea.problem,
    });
  }

  return { critical, major, minor, suggestions };
}

function getFixForCheck(checkId, idea) {
  const fixes = {
    placeholderText: 'Replace placeholder text with actual content.',
    missingFields: 'Fill in readyPrompt, caption, and pinnedComment.',
    genericPinnedComment: 'Write a specific question or tip related to this story.',
    pinnedCommentMismatch: 'Align pinned comment keywords with the story problem/title.',
    captionStoryMismatch: 'Ensure caption references the story\'s key elements.',
    openingCastMismatch: 'Use only approved character names in the opening hook.',
    unapprovedCharacterName: 'Use only approved characters (Ria, Rio, Cuty, Mumma, Papa, Daadi, Robot, Teacher).',
    brandNames: 'Remove brand names and IP-style terms from all fields.',
    textBeatDensity: 'Reduce on-screen text beats to ≤7, space ≥2.5s apart.',
    durationCheck: 'Adjust story beats to fit 15-30 second duration.',
    repeatedEndSlate: 'Create a unique end slate for this idea.',
    hashtagCount: 'Use 3-5 relevant hashtags in the caption.',
    duplicateSimilarity: 'Differentiate the problem, twist, or character from similar ideas.',
    seasonality: 'Consider seasonal relevance for timing.',
    typoCheck: 'Review on-screen text and dialogue for typos.',
  };
  return fixes[checkId] || 'Review and fix the flagged issue.';
}

function findUnsafeWords(idea) {
  const unsafeWords = ['hit', 'slap', 'spank', 'punish', 'scary', 'terrifying', 'violent', 'blood', 'weapon'];
  const textBlob = `${idea.title} ${idea.opening} ${idea.problem} ${idea.storyDetail} ${idea.caption}`.toLowerCase();
  return unsafeWords.filter(word => {
    const matches = textBlob.matchAll(new RegExp(`\\b${word}\\b`, 'g'));
    for (const match of matches) {
      const before = textBlob.slice(Math.max(0, match.index - 48), match.index);
      const after = textBlob.slice(match.index + word.length, match.index + word.length + 48);
      if (/\b(?:no|not|never|without|avoid|avoiding|don't|doesn't|shouldn't)\s+(?:\w+\s+){0,2}$/i.test(before)) continue;
      if (word === 'hit' && /\b(?:the\s+)?(?:hit|hits|hitting)\s+of\b/i.test(word + after)) continue;
      if (word === 'hit' && !/\b(?:hit|hits|hitting)\s+(?:(?:the|a|an)\s+)?(?:child|kid|baby|toddler|ria|rio|cuty|mumma|papa|daadi)\b|\b(?:child|kid|baby|toddler|ria|rio|cuty|mumma|papa|daadi)\s+(?:hit|hits|hitting)\b/i.test(before + word + after)) continue;
      return true;
    }
    return false;
  });
}

function offlineEvaluate(idea, allIdeas = []) {
  const deterministicResults = runAllChecks(idea, allIdeas, 'offline');
  const gateResults = evaluateGates(idea, deterministicResults);
  const dimensionScores = buildOfflineDimensionScores(idea, deterministicResults);
  const { critical, major, minor, suggestions } = buildOfflineFindings(idea, deterministicResults);

  const rawScore = computeWeightedScore(dimensionScores);
  const { cappedScore, cappedVerdict, capsApplied } = applyCaps(rawScore, critical, gateResults);
  const verdict = determineVerdict(cappedScore, critical, major, capsApplied, cappedVerdict);

  const { fixesToReach10, potentialScore } = buildFixesToReach10(dimensionScores, rawScore);
  const rewrittenHook = getRewrittenHook(idea, dimensionScores);
  const duplicateOf = deterministicResults.find(c => c.id === 'duplicateSimilarity')?.duplicateOf || [];
  const recommendedFormat = getRecommendedFormat(idea, gateResults, duplicateOf);
  const seasonTag = deterministicResults.find(c => c.id === 'seasonality')?.seasonTag || '';
  const confidence = 'low';

  return {
    ideaId: idea.id,
    dimensionScores,
    gateResults,
    overallScore: cappedScore,
    rawScore,
    scoreCapped: capsApplied.length > 0,
    capsApplied,
    verdict,
    criticalFindings: critical,
    majorFindings: major,
    minorFindings: minor,
    suggestions,
    fixesToReach10,
    potentialScore,
    rewrittenHook,
    duplicateOf,
    recommendedFormat,
    seasonTag,
    deterministicChecks: deterministicResults,
    confidence,
    evaluationMode: 'offline',
    evaluatedAt: new Date().toISOString(),
    evaluationVersion: '2.0.0',
  };
}

async function onlineEvaluate(idea, geminiApiKey, allIdeas = []) {
  const fetch = (await import('node-fetch')).default;
  const apiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent';

  const deterministicResults = runAllChecks(idea, allIdeas, 'online');
  const gateResults = evaluateGates(idea, deterministicResults);

  const dimensionsList = DIMENSIONS.map((d, i) =>
    `${i + 1}. ${d.name} (${d.weight}%): ${d.description}\n   Anchors: 10="${d.anchors['10']}" | 6="${d.anchors['6']}" | 2="${d.anchors['2']}"`
  ).join('\n');

  const deterministicFacts = deterministicResults.map(c =>
    `- ${c.id}: ${c.passed ? 'PASS' : 'FAIL'} (${c.severity}) - ${c.detail}`
  ).join('\n');

  const prompt = `
You are a content quality evaluator for "Fun Learning With Palak" — Instagram Reels for Indian parents of children aged 1-4.

AUDIENCE: Parents of children aged 1-4 watch these Reels. Characters shown (Ria, Rio, Cuty) are aged 1-4. Adults (Mumma, Papa, Daadi, Teacher) are caregivers.
LANGUAGE RULES: Adults speak natural Hindi. Children use age-appropriate Hinglish (single words, simple phrases).
RESOLUTION & MORAL: These are OPTIONAL. An unresolved ending can be a deliberate payoff (e.g., cliffhanger, open question). Do not penalize missing resolution/moral if the payoff works.

Evaluate the following idea on these ${DIMENSIONS.length} dimensions (score each 0-10 integer, and indicate which anchor matched: "10", "6", or "2"):

${dimensionsList}

DETERMINISTIC CHECK RESULTS (treat as facts you must respect):
${deterministicFacts}

Return ONLY valid JSON with this exact structure:
{
  "ideaId": "${idea.id}",
  "dimensionScores": [
    {"id": "hookStrength", "score": N, "anchorMatched": "10|6|2", "explanation": "...", "whatWorks": "...", "needsImprovement": "..."},
    ... (all ${DIMENSIONS.length} dimensions)
  ],
  "criticalFindings": [
    {"title": "...", "explanation": "...", "evidence": "...", "suggestedFix": "..."}
  ],
  "majorFindings": [...],
  "minorFindings": [...],
  "suggestions": [
    {"title": "...", "explanation": "...", "original": "...", "suggested": "..."}
  ],
  "fixesToReach10": [
    {"fix": "...", "dimensionId": "...", "estimatedGain": N}
  ],
  "rewrittenHook": "...",
  "duplicateOf": ["idea_id1", "idea_id2"],
  "recommendedFormat": "reel|carousel|story|merge-into-series",
  "seasonTag": "Diwali|Navratri|...",
  "confidence": "high|medium|low"
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
Post Format: ${idea.postFormat || 'Reel'}
`;

  const body = {
    contents: [{ parts: [{ text: prompt }] }],
    generationConfig: {
      temperature: 0.3,
      maxOutputTokens: 6000,
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

      let jsonText = text.trim();
      const jsonMatch = jsonText.match(/```json\n([\s\S]*?)\n```/) || jsonText.match(/```([\s\S]*?)```/) || [null, jsonText];
      jsonText = jsonMatch[1] || jsonText;

      try {
        const parsed = JSON.parse(jsonText);
        return parsed;
      } catch (e) {
        lastError = `Invalid JSON: ${e.message}`;
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

function buildOnlineResult(idea, geminiResponse, allIdeas = []) {
  const validation = validateGeminiResponse(geminiResponse);
  if (!validation.valid) {
    throw new Error(`Gemini response validation failed: ${validation.error}`);
  }

  const deterministicResults = runAllChecks(idea, allIdeas, 'online');
  const gateResults = evaluateGates(idea, deterministicResults);

  const dims = geminiResponse.dimensionScores.map(d => {
    const dimDef = DIMENSIONS.find(x => x.id === d.id);
    return {
      id: d.id,
      name: dimDef?.name || d.id,
      weight: dimDef?.weight || 0,
      score: d.score,
      anchorMatched: d.anchorMatched || '2',
      explanation: d.explanation,
      whatWorks: d.whatWorks,
      needsImprovement: d.needsImprovement,
    };
  });

  const rawScore = computeWeightedScore(dims);
  const criticalFindings = geminiResponse.criticalFindings || [];
  const majorFindings = geminiResponse.majorFindings || [];
  const minorFindings = geminiResponse.minorFindings || [];
  const suggestions = geminiResponse.suggestions || [];

  const { cappedScore, cappedVerdict, capsApplied } = applyCaps(rawScore, criticalFindings, gateResults);
  const verdict = determineVerdict(cappedScore, criticalFindings, majorFindings, capsApplied, cappedVerdict);

  const fixesToReach10 = geminiResponse.fixesToReach10 || [];
  const potentialScore = geminiResponse.potentialScore || Math.min(100, rawScore + fixesToReach10.reduce((sum, f) => sum + (f.estimatedGain || 0), 0));
  const rewrittenHook = geminiResponse.rewrittenHook || '';
  const duplicateOf = geminiResponse.duplicateOf || [];
  const recommendedFormat = geminiResponse.recommendedFormat || 'reel';
  const seasonTag = geminiResponse.seasonTag || '';
  const confidence = geminiResponse.confidence || 'low';

  return {
    ideaId: idea.id,
    dimensionScores: dims,
    gateResults,
    overallScore: cappedScore,
    rawScore,
    scoreCapped: capsApplied.length > 0,
    capsApplied,
    verdict,
    criticalFindings,
    majorFindings,
    minorFindings,
    suggestions,
    fixesToReach10,
    potentialScore,
    rewrittenHook,
    duplicateOf,
    recommendedFormat,
    seasonTag,
    deterministicChecks: deterministicResults,
    confidence,
    evaluationMode: 'online',
    evaluatedAt: new Date().toISOString(),
    evaluationVersion: '2.0.0',
  };
}

module.exports = { buildEmptyDimensionScores, offlineEvaluate, onlineEvaluate, buildOnlineResult };