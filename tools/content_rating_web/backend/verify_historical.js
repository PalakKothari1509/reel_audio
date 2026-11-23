'use strict';

const fs = require('fs');
const path = require('path');

const backupDir = path.resolve('C:/Users/palak/AppData/Local/Temp/kilo/rating_backups');
const currentDir = path.resolve('C:/Flutter/reel_audio/tools/content_rating_web/data/ratings');

const backupFiles = fs.readdirSync(backupDir).filter(f => f.endsWith('.json'));
const currentFiles = fs.readdirSync(currentDir).filter(f => f.endsWith('.json'));

console.log(`Backup files: ${backupFiles.length}`);
console.log(`Current files: ${currentFiles.length}`);

let changedCount = 0;
let unchangedCount = 0;
const changes = [];

for (const f of backupFiles) {
  const backupRaw = fs.readFileSync(path.join(backupDir, f), 'utf8');
  const currentRaw = fs.readFileSync(path.join(currentDir, f), 'utf8');
  
  const backup = JSON.parse(backupRaw);
  const current = JSON.parse(currentRaw);
  
  const prevVerdict = backup.verdict;
  const newVerdict = current.verdict;
  const prevScore = backup.overallScore;
  const newScore = current.overallScore;
  const prevRawScore = backup.rawScore;
  const newRawScore = current.rawScore;
  
  const verdictChanged = prevVerdict !== newVerdict;
  const scoreChanged = prevScore !== newScore;
  
  if (verdictChanged || scoreChanged) {
    changedCount++;
    changes.push({
      id: current.ideaId,
      prevVerdict, newVerdict,
      prevScore, newScore,
      prevRawScore, newRawScore,
      verdictChanged,
      scoreChanged,
    });
  } else {
    unchangedCount++;
  }
}

console.log(`\n=== HISTORICAL COMPARISON ===`);
console.log(`Unchanged: ${unchangedCount}`);
console.log(`Changed: ${changedCount}`);

if (changedCount > 0) {
  console.log(`\n=== CHANGED VERDICTS/SCORES ===`);
  for (const c of changes) {
    const vChange = c.verdictChanged ? ` (${c.prevVerdict} → ${c.newVerdict})` : '';
    const sChange = c.scoreChanged ? ` (${c.prevScore} → ${c.newScore})` : '';
    console.log(`  ${c.id}: verdict${vChange}, score${sChange}`);
  }
}

console.log('\n=== HISTORICAL COMPARISON COMPLETE ===');
