const fs = require('fs');
const path = 'C:/Flutter/reel_audio/content_ideas.md';
const text = fs.readFileSync(path, 'utf8');
const lines = text.split(/\r?\n/);
const sections = [];
let current = null;
const skipTitles = new Set(['Every idea has these fields', 'How the app picks the format for you', '<Title>', '<Title>, version 2']);
for (const line of lines) {
  if (/^###\s+/.test(line)) {
    if (current) sections.push(current);
    current = { title: line.replace(/^###\s+/, '').trim(), lines: [] };
  } else if (current) {
    current.lines.push(line);
  }
}
if (current) sections.push(current);
const good = sections.filter((s) => s.lines.some((l) => /\*\*id:\*\*\s*`/.test(l)) && !skipTitles.has(s.title.trim()));
const out = [];
out.push('# Master Content File — Complete Current Post Generation Ideas');
out.push('');
out.push('This file contains every actual post-generation idea currently present in the app library extracted from `content_ideas.md`.');
out.push('');
out.push('Total actual idea entries: ' + good.length);
out.push('');
for (const section of good) {
  const idLine = section.lines.find((l) => /\*\*id:\*\*\s*`/.test(l));
  const id = idLine ? idLine.match(/\*\*id:\*\*\s*`([^`]+)`/)[1] : 'unknown';
  out.push('## ' + section.title);
  out.push('');
  out.push('- **ID:** `' + id + '`');
  for (const line of section.lines) {
    if (line.startsWith('- **')) out.push(line.trim());
    else if (line.trim().startsWith('**') && line.includes(':')) out.push(line.trim());
  }
  const notes = section.lines.filter((l) => l.trim() && !l.startsWith('- **') && !l.startsWith('### ') && !l.startsWith('---') && !l.startsWith('**') && !l.startsWith('>'));
  if (notes.length) {
    out.push('');
    for (const note of notes) {
      const t = note.trim();
      if (t) out.push(t);
    }
  }
  out.push('');
}
fs.writeFileSync('C:/Flutter/reel_audio/MASTER_CONTENT.md', out.join('\n') + '\n', 'utf8');
console.log('wrote ' + good.length + ' ideas');
