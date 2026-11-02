// Validation script for content_ideas.json
const fs = require('fs');
const path = require('path');

const jsonPath = path.join(__dirname, '..', 'assets', 'data', 'content_ideas.json');
const data = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));

console.log('=== VALIDATION REPORT ===');
console.log('Version:', data.version);
console.log('Generated:', data.generatedAt);
console.log('Ideas count:', data.ideas.length);

// Check unique IDs
const ids = data.ideas.map(i => i.id);
const uniqueIds = new Set(ids);
console.log('Unique IDs:', uniqueIds.size);
if (ids.length !== uniqueIds.size) {
  console.log('ERROR: Duplicate IDs found');
  const duplicates = ids.filter((id, idx) => ids.indexOf(id) !== idx);
  console.log('Duplicates:', [...new Set(duplicates)]);
}

// Check expected count
if (data.ideas.length !== 117) {
  console.log('WARNING: Expected 117, got', data.ideas.length);
} else {
  console.log('Count check: PASSED (117)');
}

// Check all 34 fields
const requiredFields = ['id', 'category', 'title', 'cover', 'opening', 'problem', 'lesson',
  'forApp', 'usedOn', 'custom', 'archived', 'postFormat', 'strategy', 'caption',
  'pinnedComment', 'storyDetail', 'setting', 'sceneDetail', 'dialogue', 'mess',
  'innerThought', 'endingBeat', 'defaultCast', 'keepMoralOffScreen', 'quote',
  'detail', 'punchline', 'readyPrompt', 'score', 'band', 'reviewedOn'];

let missingFields = 0;
for (let i = 0; i < data.ideas.length; i++) {
  for (let f = 0; f < requiredFields.length; f++) {
    if (!(requiredFields[f] in data.ideas[i])) {
      console.log('Missing field', requiredFields[f], 'in', data.ideas[i].id);
      missingFields++;
    }
  }
}
if (missingFields === 0) {
  console.log('All 34 fields present: PASSED');
} else {
  console.log('Missing fields:', missingFields);
}

// Check the 8 specific IDs
const checkIds = ['idea_60', 'idea_63', 'idea_66', 'idea_67', 'idea_70', 'idea_74', 'idea_75', 'idea_77'];
for (let c = 0; c < checkIds.length; c++) {
  const found = ids.includes(checkIds[c]);
  console.log(checkIds[c] + ':', found ? 'PRESENT' : 'MISSING');
}

console.log('=== END VALIDATION ===');
