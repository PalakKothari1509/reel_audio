const fs = require('fs');
const path = require('path');
const { offlineEvaluate } = require('./backend/ratingEngine');

const CONTENT_JSON_PATH = path.resolve(__dirname, '../../assets/data/content_ideas.json');
const raw = fs.readFileSync(CONTENT_JSON_PATH, 'utf8');
const data = JSON.parse(raw);
const ideas = data.ideas;

const danglingPreps = ['a','an','the','to','of','in','on','at','for','or','and','but',
  'under','over','with','from','by','about','across','along','around','before',
  'after','during','without','within','beside','between','among','beneath','below',
  'above','toward','towards','into','onto','upon','via','per'];

let totalHooks = 0;
let passHooks = 0;
let improveHooks = 0;
let danglingHooks = [];
let incompleteHooks = [];
let genericHooks = [];

const instructionPatterns = [
  /^(end on|trim|add a|use only|open on|replace|write|avoid|do not|never|keep the|make sure|ensure|consider|try to|think about|focus on|remember to|don't|please|let's|we should|you should|the creator|the model|the system|this idea|this story|this post|this reel|this video|this content)/i,
  /^(story|narrative|plot|summary|overview|description|explanation)/i,
];

console.log('HOOK QUALITY TEST - All 122 ideas\n');
console.log('='.repeat(80));

for (const idea of ideas) {
  const result = offlineEvaluate(idea, ideas);
  const hookSol = result.rewrittenHook || '';
  totalHooks++;

  if (hookSol.startsWith('PASS')) {
    passHooks++;
    continue;
  }

  improveHooks++;

  // Check dangling preposition at end
  const trimmed = hookSol.trim().replace(/["?!.]$/, '');
  const lastWord = trimmed.split(/\s+/).pop() || '';
  if (danglingPreps.includes(lastWord.toLowerCase())) {
    danglingHooks.push({ id: idea.id, hook: hookSol });
  }

  // Check incomplete (no ending punctuation)
  const hookTrimmed = hookSol.trim();
  if (!/[.!?]$/.test(hookTrimmed.replace(/["]$/, ''))) {
    incompleteHooks.push({ id: idea.id, hook: hookSol });
  }

  // Check generic/instructional
  for (const pat of instructionPatterns) {
    if (pat.test(hookTrimmed)) {
      genericHooks.push({ id: idea.id, hook: hookSol });
      break;
    }
  }
}

console.log(`\nTotal hooks generated: ${totalHooks}`);
console.log(`PASS hooks: ${passHooks}`);
console.log(`IMPROVE hooks: ${improveHooks}`);
console.log(`Dangling preposition hooks: ${danglingHooks.length}`);
console.log(`Incomplete hooks (no ending punctuation): ${incompleteHooks.length}`);
console.log(`Generic/instructional hooks: ${genericHooks.length}`);

if (danglingHooks.length > 0) {
  console.log('\nDANGLING PREPOSITION HOOKS:');
  danglingHooks.forEach(h => console.log(`  ${h.id}: ${h.hook}`));
}
if (incompleteHooks.length > 0) {
  console.log('\nINCOMPLETE HOOKS:');
  incompleteHooks.forEach(h => console.log(`  ${h.id}: ${h.hook}`));
}
if (genericHooks.length > 0) {
  console.log('\nGENERIC/INSTRUCTIONAL HOOKS:');
  genericHooks.forEach(h => console.log(`  ${h.id}: ${h.hook}`));
}

// Sample specific edge cases
console.log('\n' + '='.repeat(80));
console.log('SAMPLE GENERATED HOOKS (first 20 IMPROVE hooks)');
console.log('='.repeat(80));
let count = 0;
for (const idea of ideas) {
  const result = offlineEvaluate(idea, ideas);
  const hookSol = result.rewrittenHook || '';
  if (!hookSol.startsWith('PASS')) {
    console.log(`${idea.id}: ${hookSol}`);
    count++;
    if (count >= 20) break;
  }
}

console.log(`\nDisplayed ${count} sample hooks.`);

const allClean = danglingHooks.length === 0 && incompleteHooks.length === 0 && genericHooks.length === 0;
console.log(`\nHook quality: ${allClean ? 'PASS' : 'FAIL'}`);
process.exit(allClean ? 0 : 1);
