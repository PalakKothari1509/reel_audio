const fs = require('fs');
const path = require('path');

const CONFIG_DIR = path.resolve(__dirname, 'config');

const approvedCharacters = JSON.parse(fs.readFileSync(path.join(CONFIG_DIR, 'approvedCharacters.json'), 'utf8'));
const brandAndIpBlocklist = JSON.parse(fs.readFileSync(path.join(CONFIG_DIR, 'brandAndIpBlocklist.json'), 'utf8'));
const genericPinnedComments = JSON.parse(fs.readFileSync(path.join(CONFIG_DIR, 'genericPinnedComments.json'), 'utf8'));
const festivalCalendar = JSON.parse(fs.readFileSync(path.join(CONFIG_DIR, 'festivalCalendar.json'), 'utf8'));

const APPROVED_NAMES = new Set(approvedCharacters.names);
const PRONOUNS = approvedCharacters.pronouns;
const BRAND_BLOCKLIST = new Set(brandAndIpBlocklist.brands.map(b => b.toLowerCase()));
const IP_BLOCKLIST = new Set(brandAndIpBlocklist.ipStyleTerms.map(t => t.toLowerCase()));
const GENERIC_TEMPLATES = genericPinnedComments.templates.map(t => normalizeText(t));
const FESTIVALS = festivalCalendar.festivals;

const STOPWORDS = new Set([
  'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with', 'by', 'from', 'as', 'is', 'was', 'were', 'be', 'been', 'being', 'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'could', 'should', 'may', 'might', 'must', 'can', 'this', 'that', 'these', 'those', 'i', 'you', 'he', 'she', 'it', 'we', 'they', 'me', 'him', 'her', 'us', 'them', 'my', 'your', 'his', 'its', 'our', 'their', 'mine', 'yours', 'hers', 'ours', 'theirs',
  'hai', 'hain', 'nahi', 'nahin', 'haan', 'beti', 'beta', 'dekho', 'sun', 'jao', 'chalo', 'kyun', 'kaise', 'kya', 'kaunsa', 'karein', 'mujhe', 'tum', 'tumhein', 'aaj', 'mera', 'meri', 'chahiye', 'accha', 'achha', 'theek', 'bas', 'phir', 'ab', 'yeh', 'woh', 'kar', 'karo', 'gaya', 'gayi', 'ho', 'ek', 'aur', 'ko', 'ke', 'ki', 'ka', 'se', 'mein', 'par', 'pe', 'ne', 'ko', 'ka', 'ke', 'ki', 'to', 'bhi', 'bhi', 'hi', 'hi', 'to', 'to', 'ya', 'ya', 'na', 'na', 'kya', 'kya', 'kaun', 'kaun', 'kahan', 'kahan', 'kab', 'kab', 'kyun', 'kyun', 'kaise', 'kaise'
]);

function normalizeText(text) {
  if (!text) return '';
  return text.toLowerCase()
    .replace(/[.,!?;:()\[\]{}"'“”‘’]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function tokenize(text) {
  const normalized = normalizeText(text);
  return normalized.split(' ').filter(w => w.length > 2 && !STOPWORDS.has(w));
}

function jaccardSimilarity(setA, setB) {
  if (setA.size === 0 && setB.size === 0) return 1;
  if (setA.size === 0 || setB.size === 0) return 0;
  const intersection = new Set([...setA].filter(x => setB.has(x)));
  const union = new Set([...setA, ...setB]);
  return intersection.size / union.size;
}

function cosineSimilarity(vecA, vecB) {
  const allKeys = new Set([...Object.keys(vecA), ...Object.keys(vecB)]);
  let dotProduct = 0;
  let normA = 0;
  let normB = 0;
  for (const key of allKeys) {
    const a = vecA[key] || 0;
    const b = vecB[key] || 0;
    dotProduct += a * b;
    normA += a * a;
    normB += b * b;
  }
  if (normA === 0 || normB === 0) return 0;
  return dotProduct / (Math.sqrt(normA) * Math.sqrt(normB));
}

function termFrequency(text) {
  const tokens = tokenize(text);
  const freq = {};
  for (const token of tokens) {
    freq[token] = (freq[token] || 0) + 1;
  }
  return freq;
}

function checkPlaceholderText(idea) {
  const fields = ['readyPrompt', 'caption', 'pinnedComment', 'storyDetail'];
  const placeholderRegex = /(X{4,}|TODO|lorem|Archived)/i;
  const found = [];
  for (const field of fields) {
    const value = idea[field] || '';
    if (placeholderRegex.test(value)) {
      found.push({ field, value: value.slice(0, 100) });
    }
  }
  return {
    id: 'placeholderText',
    passed: found.length === 0,
    severity: 'major',
    gate: 'characterConsistency',
    detail: found.length > 0
      ? `Placeholder text detected in: ${found.map(f => f.field).join(', ')}`
      : 'No placeholder text found',
  };
}

function checkMissingFields(idea) {
  const required = ['readyPrompt', 'caption', 'pinnedComment'];
  const missing = required.filter(f => !idea[f] || idea[f].trim().length === 0);
  return {
    id: 'missingFields',
    passed: missing.length === 0,
    severity: 'minor',
    gate: 'formatFit',
    detail: missing.length > 0
      ? `Missing required fields: ${missing.join(', ')}`
      : 'All required fields present',
  };
}

function checkGenericPinnedComment(idea) {
  const pinned = idea.pinnedComment || '';
  if (!pinned) {
    return {
      id: 'genericPinnedComment',
      passed: true,
      severity: 'minor',
      gate: 'captionCommentPackage',
      detail: 'No pinned comment to check',
    };
  }
  const normalized = normalizeText(pinned);
  for (const template of GENERIC_TEMPLATES) {
    if (normalized.includes(template) || template.includes(normalized)) {
      return {
        id: 'genericPinnedComment',
        passed: false,
        severity: 'minor',
        gate: 'captionCommentPackage',
        detail: `Pinned comment matches generic template: "${template.slice(0, 50)}..."`,
      };
    }
    const jaccard = jaccardSimilarity(new Set(tokenize(pinned)), new Set(tokenize(template)));
    if (jaccard > 0.7) {
      return {
        id: 'genericPinnedComment',
        passed: false,
        severity: 'minor',
        gate: 'captionCommentPackage',
        detail: `Pinned comment highly similar to generic template (Jaccard: ${jaccard.toFixed(2)})`,
      };
    }
  }
  return {
    id: 'genericPinnedComment',
    passed: true,
    severity: 'minor',
    gate: 'captionCommentPackage',
    detail: 'Pinned comment is not generic',
  };
}

function checkPinnedCommentMismatch(idea) {
  const pinned = idea.pinnedComment || '';
  if (!pinned) {
    return {
      id: 'pinnedCommentMismatch',
      passed: true,
      severity: 'minor',
      gate: 'captionCommentPackage',
      detail: 'No pinned comment to check',
    };
  }
  const storyText = `${idea.title || ''} ${idea.problem || ''} ${idea.storyDetail || ''}`;
  const pinnedTokens = new Set(tokenize(pinned));
  const storyTokens = new Set(tokenize(storyText));
  const overlap = [...pinnedTokens].filter(t => storyTokens.has(t)).length;
  const threshold = 1;
  return {
    id: 'pinnedCommentMismatch',
    passed: overlap >= threshold,
    severity: 'minor',
    gate: 'captionCommentPackage',
    detail: overlap >= threshold
      ? `Pinned comment shares ${overlap} meaningful keyword(s) with story`
      : `Pinned comment shares only ${overlap} meaningful keyword(s) with story (threshold: ${threshold})`,
  };
}

function checkCaptionStoryMismatch(idea) {
  const caption = idea.caption || '';
  if (!caption) {
    return {
      id: 'captionStoryMismatch',
      passed: true,
      severity: 'minor',
      gate: 'captionCommentPackage',
      detail: 'No caption to check',
    };
  }
  const storyText = `${idea.title || ''} ${idea.problem || ''} ${idea.storyDetail || ''}`;
  const captionTokens = new Set(tokenize(caption));
  const storyTokens = new Set(tokenize(storyText));
  const overlap = [...captionTokens].filter(t => storyTokens.has(t)).length;
  const threshold = Math.max(3, Math.ceil(storyTokens.size * 0.10));
  return {
    id: 'captionStoryMismatch',
    passed: overlap >= threshold,
    severity: 'minor',
    gate: 'captionCommentPackage',
    detail: overlap >= threshold
      ? `Caption shares ${overlap} meaningful keyword(s) with story (threshold: ${threshold})`
      : `Caption shares only ${overlap} meaningful keyword(s) with story (threshold: ${threshold})`,
  };
}

function checkOpeningCastMismatch(idea) {
  const opening = idea.opening || '';
  if (!opening) {
    return {
      id: 'openingCastMismatch',
      passed: true,
      severity: 'major',
      gate: 'characterConsistency',
      detail: 'No opening to check',
    };
  }
  const defaultCast = new Set((idea.defaultCast || []).map(c => c.toLowerCase()));
  const storyDetail = (idea.storyDetail || '').toLowerCase();
  const words = opening.match(/\b[A-Z][a-z]+\b/g) || [];
  const relationshipWords = ['Uncle', 'Aunty', 'Dada', 'Dadi', 'Nana', 'Nani', 'Chacha', 'Chachi', 'Mama', 'Mami', 'Bhaiya', 'Didi'];
  const hindiInterjections = ['Arre', 'Are', 'Achha', 'Accha', 'Theek', 'Bas', 'Chalo', 'Ji', 'Haan', 'Ha', 'Nahi', 'Nahin', 'Oye', 'Hey', 'Wah', 'Vah', 'Oho', 'Arey', 'Arre', 'Bapre', 'Hai', 'Kya', 'Kaise', 'Kahan', 'Kab', 'Kyun', 'Kaun', 'Chal', 'Chalo', 'Ruko', 'Suno', 'Dekho', 'Chal', 'Ja', 'Aa', 'Chalna', 'Rukna', 'Sunna', 'Dekhna'];
  const found = [];
  for (const word of words) {
    const lower = word.toLowerCase();
    if (relationshipWords.some(r => r.toLowerCase() === lower)) {
      if (!defaultCast.has(lower) && !storyDetail.includes(lower)) {
        found.push(word);
      }
    } else if (hindiInterjections.some(h => h.toLowerCase() === lower)) {
      continue; // Skip common Hindi interjections
    } else if (!defaultCast.has(lower) && !storyDetail.includes(lower)) {
      found.push(word);
    }
  }
  return {
    id: 'openingCastMismatch',
    passed: found.length === 0,
    severity: 'major',
    gate: 'characterConsistency',
    detail: found.length > 0
      ? `Opening mentions character/relationship not in cast or story: ${found.join(', ')}`
      : 'Opening cast matches approved cast and story',
  };
}

function checkUnapprovedCharacterName(idea) {
  const fields = ['title', 'opening', 'problem', 'storyDetail', 'endingBeat', 'dialogue', 'caption', 'pinnedComment'];
  const text = fields.map(f => idea[f] || '').join(' ');
  const lowerText = text.toLowerCase();
  const found = [];

  for (const name of APPROVED_NAMES) {
    const lower = name.toLowerCase();
    if (lowerText.includes(lower)) {
      const expectedPronoun = PRONOUNS[name];
      if (expectedPronoun !== 'any') {
        const pronounRegex = new RegExp(`\\b${lower}\\s+(?:said|asked|replied|answered|thought|felt|knew|decided|chose|grabbed|took|held|dropped|threw|caught|pushed|pulled|touched|tapped|patted|hugged|kissed|hit|slapped|punched|kicked|bit|scratched|pinched|looked|glanced|stared|gazed|watched|observed|noticed|saw|heard|listened)\\b.*\\b(he|she|it|his|her|its)\\b`, 'gi');
        const matches = text.matchAll(pronounRegex);
        for (const match of matches) {
          const pronoun = match[1].toLowerCase();
          if (pronoun !== expectedPronoun && expectedPronoun !== 'any') {
            found.push(`Pronoun mismatch for ${name}: expected "${expectedPronoun}", found "${pronoun}"`);
          }
        }
      }
    }
  }

  const dialogueText = idea.dialogue || '';
  const namePattern = /\b([A-Z][a-z]{2,})\b(?=\s+(?:said|asked|replied|answered|called|shouted|whispered|screamed|yelled|murmured|muttered|cried|laughed|smiled|nodded|shook|looked|glanced|stared|gazed|watched|observed|noticed|saw|heard|listened|thought|wondered|felt|knew|remembered|forgot|decided|chose|picked|selected|grabbed|took|held|dropped|threw|caught|pushed|pulled|touched|tapped|patted|hugged|kissed|hit|slapped|punched|kicked|bit|scratched|pinched))/gi;
  const namesInDialogue = [...dialogueText.matchAll(namePattern)].map(m => m[1]);
  for (const name of namesInDialogue) {
    if (!APPROVED_NAMES.has(name)) {
      found.push(`Unapproved character name in dialogue: ${name}`);
    }
  }

  return {
    id: 'unapprovedCharacterName',
    passed: found.length === 0,
    severity: 'major',
    gate: 'characterConsistency',
    detail: found.length > 0
      ? found.join('; ')
      : 'All character names approved and pronouns consistent',
  };
}

function checkBrandNames(idea) {
  const fields = ['readyPrompt', 'caption', 'pinnedComment', 'storyDetail'];
  const text = fields.map(f => idea[f] || '').join(' ').toLowerCase();
  const found = [];
  for (const brand of BRAND_BLOCKLIST) {
    if (text.includes(brand)) {
      found.push(brand);
    }
  }
  for (const ip of IP_BLOCKLIST) {
    if (text.includes(ip)) {
      found.push(ip);
    }
  }
  return {
    id: 'brandNames',
    passed: found.length === 0,
    severity: 'critical',
    gate: 'brandAndSafety',
    detail: found.length > 0
      ? `Blocked brand/IP term detected: ${found.join(', ')}`
      : 'No blocked brand or IP terms found',
  };
}

function checkTextBeatDensity(idea) {
  const readyPrompt = idea.readyPrompt || '';
  const textLines = readyPrompt.split('\n');
  const onScreenTextLines = textLines.filter(l => l.trim().startsWith('On-Screen Text:'));
  const beats = [];
  for (const line of onScreenTextLines) {
    const timestampMatches = line.match(/\[(\d+(?:\.\d+)?)\s*-\s*(\d+(?:\.\d+)?)\s*s?\]/g);
    if (timestampMatches) {
      for (const match of timestampMatches) {
        const [, start, end] = match.match(/\[(\d+(?:\.\d+)?)\s*-\s*(\d+(?:\.\d+)?)\s*s?\]/);
        beats.push({ start: parseFloat(start), end: parseFloat(end), text: line });
      }
    }
  }
  const issues = [];
  if (beats.length > 7) {
    issues.push(`${beats.length} text beats (max 7)`);
  }
  for (let i = 0; i < beats.length - 1; i++) {
    const gap = beats[i + 1].start - beats[i].start;
    if (gap < 2.5) {
      issues.push(`Beat ${i + 1} to ${i + 2} gap only ${gap}s (min 2.5s)`);
    }
  }
  return {
    id: 'textBeatDensity',
    passed: issues.length === 0,
    severity: 'minor',
    gate: 'visualFeasibility',
    detail: issues.length > 0
      ? `Text beat issues: ${issues.join('; ')}`
      : `Text beats: ${beats.length}, all properly spaced`,
  };
}

function checkDuration(idea) {
  const readyPrompt = idea.readyPrompt || '';
  const timestampMatches = readyPrompt.match(/\[(\d+(?:\.\d+)?)\s*-\s*(\d+(?:\.\d+)?)\s*s?\]/g);
  if (!timestampMatches || timestampMatches.length === 0) {
    return {
      id: 'durationCheck',
      passed: true,
      severity: 'minor',
      gate: 'visualFeasibility',
      detail: 'No timestamps found to infer duration',
    };
  }
  let maxEnd = 0;
  for (const match of timestampMatches) {
    const [, start, end] = match.match(/\[(\d+(?:\.\d+)?)\s*-\s*(\d+(?:\.\d+)?)\s*s?\]/);
    maxEnd = Math.max(maxEnd, parseFloat(end));
  }
  const passed = maxEnd >= 15 && maxEnd <= 30;
  return {
    id: 'durationCheck',
    passed,
    severity: 'minor',
    gate: 'visualFeasibility',
    detail: passed
      ? `Inferred duration: ${maxEnd}s (within 15-30s)`
      : `Inferred duration: ${maxEnd}s (outside 15-30s range)`,
  };
}

function checkRepeatedEndSlate(idea, allIdeas = []) {
  const readyPrompt = idea.readyPrompt || '';
  const textLines = readyPrompt.split('\n');
  const onScreenTextLines = textLines.filter(l => l.trim().startsWith('On-Screen Text:'));
  if (onScreenTextLines.length === 0) {
    return {
      id: 'repeatedEndSlate',
      passed: true,
      severity: 'suggestion',
      gate: 'originality',
      detail: 'No on-screen text to check',
    };
  }
  const lastBeat = onScreenTextLines[onScreenTextLines.length - 1];
  const lastText = lastBeat.replace('On-Screen Text:', '').trim();
  if (!lastText) {
    return {
      id: 'repeatedEndSlate',
      passed: true,
      severity: 'suggestion',
      gate: 'originality',
      detail: 'Last on-screen text beat is empty',
    };
  }
  let matchCount = 0;
  for (const otherIdea of allIdeas) {
    if (otherIdea.id === idea.id) continue;
    const otherPrompt = otherIdea.readyPrompt || '';
    const otherLines = otherPrompt.split('\n');
    const otherOnScreen = otherLines.filter(l => l.trim().startsWith('On-Screen Text:'));
    if (otherOnScreen.length === 0) continue;
    const otherLast = otherOnScreen[otherOnScreen.length - 1].replace('On-Screen Text:', '').trim();
    if (otherLast && normalizeText(otherLast) === normalizeText(lastText)) {
      matchCount++;
    }
  }
  const percentage = allIdeas.length > 1 ? (matchCount / (allIdeas.length - 1)) * 100 : 0;
  const passed = percentage <= 50;
  return {
    id: 'repeatedEndSlate',
    passed,
    severity: 'suggestion',
    gate: 'originality',
    detail: passed
      ? `End slate appears in ${percentage.toFixed(1)}% of library (threshold: 50%)`
      : `End slate appears in ${percentage.toFixed(1)}% of library (threshold: 50%) - consider varying`,
  };
}

function checkHashtagCount(idea) {
  const caption = idea.caption || '';
  const hashtags = caption.match(/#[^\s#]+/g) || [];
  const count = hashtags.length;
  const passed = count >= 3 && count <= 5;
  return {
    id: 'hashtagCount',
    passed,
    severity: 'minor',
    gate: 'captionCommentPackage',
    detail: passed
      ? `Caption has ${count} hashtags (within 3-5 range)`
      : `Caption has ${count} hashtags (expected 3-5)`,
  };
}

function checkDuplicateSimilarity(idea, allIdeas = [], mode = 'offline') {
  const text = `${idea.title || ''} ${idea.problem || ''} ${idea.storyDetail || ''}`;
  const duplicates = [];
  if (mode === 'online') {
    return {
      id: 'duplicateSimilarity',
      passed: true,
      severity: 'major',
      gate: 'originality',
      detail: 'Online duplicate check requires embedding API - skipped in offline mode',
      duplicateOf: [],
    };
  }
  const vecA = termFrequency(text);
  for (const otherIdea of allIdeas) {
    if (otherIdea.id === idea.id) continue;
    const otherText = `${otherIdea.title || ''} ${otherIdea.problem || ''} ${otherIdea.storyDetail || ''}`;
    const vecB = termFrequency(otherText);
    const similarity = cosineSimilarity(vecA, vecB);
    if (similarity > 0.8) {
      duplicates.push({ id: otherIdea.id, similarity: similarity.toFixed(3) });
    }
  }
  return {
    id: 'duplicateSimilarity',
    passed: duplicates.length === 0,
    severity: 'major',
    gate: 'originality',
    detail: duplicates.length > 0
      ? `Near-duplicates found: ${duplicates.map(d => `${d.id} (${d.similarity})`).join(', ')}`
      : 'No near-duplicates found (cosine < 0.8)',
    duplicateOf: duplicates.map(d => d.id),
  };
}

function checkSeasonality(idea) {
  const fields = ['title', 'cover', 'opening', 'problem', 'storyDetail', 'caption', 'pinnedComment'];
  const text = fields.map(f => idea[f] || '').join(' ').toLowerCase();
  const matched = [];
  for (const festival of FESTIVALS) {
    for (const keyword of festival.keywords) {
      if (text.includes(keyword.toLowerCase())) {
        matched.push(festival.name);
        break;
      }
    }
  }
  let detail = matched.length > 0
    ? `Seasonal tags matched: ${matched.join(', ')}`
    : 'No seasonal keywords matched';
  let flagged = false;
  for (const festival of FESTIVALS) {
    if (festival.dates && festival.dates.length > 0) {
      const today = new Date();
      for (const dateStr of festival.dates) {
        const festivalDate = new Date(dateStr);
        if (festivalDate < today) {
          flagged = true;
          detail += `; ${festival.name} date (${dateStr}) has passed`;
        }
      }
    }
  }
  return {
    id: 'seasonality',
    passed: !flagged,
    severity: 'suggestion',
    gate: 'formatFit',
    detail,
    seasonTag: matched.length > 0 ? matched.join(', ') : undefined,
  };
}

function checkTypo(idea) {
  const allowList = new Set([
    'hinglish', 'beti', 'beta', 'mumma', 'papa', 'daadi', 'nani', 'nana', 'chacha', 'chachi', 'mama', 'mami',
    'bhaiya', 'didi', 'bhai', 'behen', 'choti', 'badi', 'chota', 'bada', 'accha', 'achha', 'theek', 'bas',
    'chalo', 'jao', 'dekho', 'suno', 'karo', 'mat', 'nahi', 'nahin', 'haan', 'ji', 'ok', 'okay', 'arre',
    'bacha', 'bachi', 'bacche', 'baccha', 'bacchi', 'chhota', 'chhoti', 'bade', 'badi', 'naya', 'nayi',
    'purana', 'purani', 'ghar', 'ghar', 'school', 'park', 'market', 'shop', 'dukaan', 'gaadi', 'cycle',
    'ball', 'toy', 'khilona', 'khel', 'khelna', 'padhna', 'likhna', 'khana', 'peena', 'sona', 'uthna',
    'baithna', 'chalna', 'daudna', 'nachna', 'gaana', 'sunna', 'dekhna', 'bolna', 'samajhna', 'jaanna'
  ]);
  const fields = ['readyPrompt', 'caption', 'pinnedComment', 'storyDetail', 'dialogue'];
  const text = fields.map(f => idea[f] || '').join(' ');
  const words = text.match(/\b[a-zA-Z]{3,}\b/g) || [];
  const suspicious = [];
  for (const word of words) {
    const lower = word.toLowerCase();
    if (allowList.has(lower)) continue;
    if (/^[a-z]+$/.test(lower) && lower.length > 3) {
      const dict = ['the', 'and', 'for', 'with', 'you', 'your', 'are', 'have', 'has', 'had', 'was', 'were', 'will', 'would', 'could', 'should', 'this', 'that', 'from', 'they', 'them', 'their', 'what', 'when', 'where', 'which', 'who', 'whom', 'whose', 'how', 'why', 'can', 'will', 'just', 'like', 'into', 'over', 'under', 'again', 'then', 'than', 'very', 'much', 'more', 'most', 'some', 'any', 'each', 'every', 'other', 'another', 'such', 'only', 'own', 'same', 'so', 'too', 'also', 'even', 'still', 'yet', 'already', 'always', 'never', 'often', 'sometimes', 'usually', 'almost', 'about', 'after', 'before', 'during', 'since', 'until', 'while', 'because', 'although', 'though', 'if', 'unless', 'whether', 'either', 'neither', 'both', 'all', 'any', 'few', 'many', 'several'];
      if (!dict.includes(lower) && !/^(?:ing|ed|er|est|ly|tion|sion|ness|ment|able|ible|ful|less|ous|ive|ize|ise|ify|ate|en|em|re|un|pre|pro|anti|sub|super|inter|trans|over|under|out|up|down|in|on|off|away|back|through|across|along|around|between|among|beyond|within|without|inside|outside|above|below|beneath|beside|behind|before|after|during|since|until|while|when|where|why|how|what|which|who|whom|whose|that|this|these|those|here|there|everywhere|somewhere|anywhere|nowhere|now|then|soon|later|early|late|today|tomorrow|yesterday|tonight|morning|evening|afternoon|midnight|noon|week|month|year|day|hour|minute|second|time|times|once|twice|thrice|always|never|often|sometimes|usually|rarely|seldom|ever|never|already|still|yet|just|only|even|also|too|either|neither|both|all|any|some|none|no|yes|maybe|perhaps|probably|certainly|definitely|absolutely|clearly|obviously|really|truly|actually|basically|essentially|fundamentally|practically|virtually|literally|figuratively|metaphorically|symbolically|ironically|sarcastically|humorously|seriously|honestly|frankly|candidly|openly|plainly|simply|merely|barely|hardly|scarcely|nearly|almost|virtually|practically|roughly|approximately|about|around|circa|more|less|fewer|greater|smaller|larger|higher|lower|better|worse|best|worst|most|least|much|many|few|several|some|any|all|none|each|every|either|neither|both|one|two|three|four|five|six|seven|eight|nine|ten|first|second|third|fourth|fifth|sixth|seventh|eighth|ninth|tenth|last|next|previous|former|latter|same|different|other|another|such|so|very|too|enough|quite|rather|pretty|fairly|really|truly|actually|indeed|certainly|surely|obviously|clearly|plainly|simply|merely|just|only|even|still|yet|already|always|never|often|sometimes|usually|rarely|seldom|ever|now|then|soon|later|early|late|today|tomorrow|yesterday|tonight|morning|evening|afternoon|midnight|noon)$/.test(lower)) {
        suspicious.push(word);
      }
    }
  }
  return {
    id: 'typoCheck',
    passed: suspicious.length === 0,
    severity: 'minor',
    gate: 'formatFit',
    detail: suspicious.length > 0
      ? `Possible typos/non-words: ${suspicious.slice(0, 10).join(', ')}${suspicious.length > 10 ? '...' : ''}`
      : 'No obvious typos detected',
  };
}

function runAllChecks(idea, allIdeas = [], mode = 'offline') {
  const checks = [
    checkPlaceholderText(idea),
    checkMissingFields(idea),
    checkGenericPinnedComment(idea),
    checkPinnedCommentMismatch(idea),
    checkCaptionStoryMismatch(idea),
    checkOpeningCastMismatch(idea),
    checkUnapprovedCharacterName(idea),
    checkBrandNames(idea),
    checkTextBeatDensity(idea),
    checkDuration(idea),
    checkRepeatedEndSlate(idea, allIdeas),
    checkHashtagCount(idea),
    checkDuplicateSimilarity(idea, allIdeas, mode),
    checkSeasonality(idea),
    checkTypo(idea),
  ];
  return checks;
}

module.exports = {
  runAllChecks,
  checkPlaceholderText,
  checkMissingFields,
  checkGenericPinnedComment,
  checkPinnedCommentMismatch,
  checkCaptionStoryMismatch,
  checkOpeningCastMismatch,
  checkUnapprovedCharacterName,
  checkBrandNames,
  checkTextBeatDensity,
  checkDuration,
  checkRepeatedEndSlate,
  checkHashtagCount,
  checkDuplicateSimilarity,
  checkSeasonality,
  checkTypo,
  APPROVED_NAMES,
  PRONOUNS,
  BRAND_BLOCKLIST,
  IP_BLOCKLIST,
  GENERIC_TEMPLATES,
  FESTIVALS,
  STOPWORDS,
  normalizeText,
  tokenize,
  jaccardSimilarity,
  cosineSimilarity,
  termFrequency,
};