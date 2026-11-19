const fs = require('fs');
const path = require('path');
const csvPath = path.join('C:', 'Users', 'palak', 'Downloads', 'content_ideas_full_table (3).csv');
let csvContent = fs.readFileSync(csvPath, 'utf-8');
if (csvContent.charCodeAt(0) === 0xFEFF) csvContent = csvContent.slice(1);

function parseCSV(csv) {
    const rows = [];
    let currentRow = [];
    let currentField = '';
    let inQuotes = false;
    let fieldStart = true;
    for (let i = 0; i < csv.length; i++) {
        const char = csv[i];
        const nextChar = csv[i + 1];
        if (fieldStart && char === '"') { inQuotes = true; fieldStart = false; }
        else if (inQuotes) {
            if (char === '"' && nextChar === '"') { currentField += '"'; i++; }
            else if (char === '"') { inQuotes = false; }
            else { currentField += char; }
        } else if (char === ',') { currentRow.push(currentField); currentField = ''; fieldStart = true; }
        else if (char === '\n' || char === '\r') {
            if (char === '\r' && nextChar === '\n') i++;
            currentRow.push(currentField); currentField = ''; fieldStart = true;
            if (currentRow.length > 0) { rows.push(currentRow); currentRow = []; }
        } else { currentField += char; fieldStart = false; }
    }
    if (currentField || currentRow.length > 0) { currentRow.push(currentField); if (currentRow.length > 0) rows.push(currentRow); }
    return rows;
}

const rows = parseCSV(csvContent);
function cleanValue(val) { if (val.startsWith('"') && val.endsWith('"') && val.length >= 2) return val.slice(1, -1); return val; }
const headers = rows[0].map(cleanValue);

let diffCount = 0;
for (let i = 1; i < rows.length; i++) {
    const row = rows[i];
    const obj = {};
    headers.forEach((h, idx) => obj[h] = cleanValue(row[idx] || ''));
    const opening = obj['Opening'] || '';
    const rewritten = obj['Rewritten Hook'] || '';
    if (opening && rewritten && opening.trim() !== rewritten.trim()) {
        console.log('DIFF:', obj['Idea ID']);
        console.log('  Opening:', opening.substring(0, 80));
        console.log('  Rewritten:', rewritten.substring(0, 80));
        diffCount++;
    }
}
console.log('Total different:', diffCount);