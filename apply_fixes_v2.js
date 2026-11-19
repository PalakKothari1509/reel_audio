const fs = require('fs');
const path = require('path');

// Read the JSON file
const jsonPath = path.join(__dirname, 'assets', 'data', 'content_ideas.json');
const jsonData = JSON.parse(fs.readFileSync(jsonPath, 'utf-8'));

// Read the CSV file
const csvPath = path.join('C:', 'Users', 'palak', 'Downloads', 'content_ideas_full_table (3).csv');
let csvContent = fs.readFileSync(csvPath, 'utf-8');

// Remove BOM if present
if (csvContent.charCodeAt(0) === 0xFEFF) {
    csvContent = csvContent.slice(1);
}

// Parse CSV properly handling quoted fields with embedded newlines and commas
function parseCSV(csv) {
    const rows = [];
    let currentRow = [];
    let currentField = '';
    let inQuotes = false;
    let fieldStart = true;
    
    for (let i = 0; i < csv.length; i++) {
        const char = csv[i];
        const nextChar = csv[i + 1];
        
        if (fieldStart && char === '"') {
            inQuotes = true;
            fieldStart = false;
        } else if (inQuotes) {
            if (char === '"' && nextChar === '"') {
                currentField += '"';
                i++; // skip escaped quote
            } else if (char === '"') {
                inQuotes = false;
            } else {
                currentField += char;
            }
        } else if (char === ',') {
            currentRow.push(currentField);
            currentField = '';
            fieldStart = true;
        } else if (char === '\n' || char === '\r') {
            if (char === '\r' && nextChar === '\n') {
                i++; // skip \n in \r\n
            }
            currentRow.push(currentField);
            currentField = '';
            fieldStart = true;
            
            if (currentRow.length > 0) {
                rows.push(currentRow);
                currentRow = [];
            }
        } else {
            currentField += char;
            fieldStart = false;
        }
    }
    
    // Handle last field/row
    if (currentField || currentRow.length > 0) {
        currentRow.push(currentField);
        if (currentRow.length > 0) {
            rows.push(currentRow);
        }
    }
    
    return rows;
}

const rows = parseCSV(csvContent);

// Clean up values (remove surrounding quotes if present)
function cleanValue(val) {
    if (val.startsWith('"') && val.endsWith('"') && val.length >= 2) {
        return val.slice(1, -1);
    }
    return val;
}

const headers = rows[0].map(cleanValue);

const csvData = {};
for (let i = 1; i < rows.length; i++) {
    const row = rows[i];
    if (row.length >= headers.length) {
        const obj = {};
        headers.forEach((header, idx) => {
            obj[header] = cleanValue(row[idx] || '');
        });
        if (obj['Idea ID']) {
            csvData[obj['Idea ID']] = obj;
        }
    }
}

console.log(`CSV ideas parsed: ${Object.keys(csvData).length}`);

// Helper to parse JSON fields from CSV
function parseJsonField(csvRow, fieldName) {
    try {
        const val = csvRow[fieldName];
        if (!val || val.trim() === '' || val === '[]' || val === '{}') return null;
        return JSON.parse(val);
    } catch (e) {
        return null;
    }
}

// Apply fixes to each idea
let updated = 0;
let fixesApplied = 0;

jsonData.ideas.forEach(idea => {
    const ideaId = idea.id;
    if (!csvData[ideaId]) return;
    
    const csvRow = csvData[ideaId];
    let ideaFixes = 0;
    
    // 1. Apply Rewritten Hook to opening
    if (csvRow['Rewritten Hook'] && csvRow['Rewritten Hook'].trim()) {
        idea.opening = csvRow['Rewritten Hook'].trim();
        ideaFixes++;
    }
    
    // 2. Apply Suggestions (e.g., "Add an opening hook")
    const suggestions = parseJsonField(csvRow, 'Suggestions');
    if (suggestions && Array.isArray(suggestions)) {
        suggestions.forEach(sugg => {
            if (sugg.suggested && sugg.title === 'Add an opening hook') {
                idea.opening = sugg.suggested;
                ideaFixes++;
            }
        });
    }
    
    // 3. Fix specific known issues from evaluation
    // Fix "Mummy" -> "Mumma" across all fields
    const fieldsToFix = ['opening', 'problem', 'lesson', 'storyDetail', 'endingBeat', 'caption', 'pinnedComment', 'setting', 'sceneDetail', 'dialogue', 'readyPrompt'];
    fieldsToFix.forEach(field => {
        if (idea[field] && typeof idea[field] === 'string') {
            const before = idea[field];
            idea[field] = idea[field].replace(/\bMummy\b/gi, 'Mumma');
            if (before !== idea[field]) ideaFixes++;
        }
    });
    
    // Fix "Daadi" consistency
    fieldsToFix.forEach(field => {
        if (idea[field] && typeof idea[field] === 'string') {
            const before = idea[field];
            idea[field] = idea[field].replace(/\bDadi\b/gi, 'Daadi').replace(/\bDAADI\b/gi, 'Daadi');
            if (before !== idea[field]) ideaFixes++;
        }
    });
    
    // Fix common typos in readyPrompt and dialogue
    const typoFields = ['readyPrompt', 'dialogue', 'storyDetail', 'endingBeat'];
    typoFields.forEach(field => {
        if (idea[field] && typeof idea[field] === 'string') {
            const before = idea[field];
            // Fix specific known typos
            idea[field] = idea[field]
                .replace(/AAG LAGI THI/gi, 'ATTA GIRA THA')
                .replace(/PAANI DAAL DIYA/gi, 'PAANI DAL DIYA')
                .replace(/NO SCOld/gi, 'NO SCOLD')
                .replace(/EKPairo SHOES/gi, 'EK PAIR SHOES')
                .replace(/pakho/gi, 'pakdo')
                .replace(/saambhaa lunga/gi, 'saambhal lunga')
                .replace(/neela nahi hota/gi, 'neela hota')
                .replace(/hiccers/gi, 'hiccups')
                .replace(/The End story\?/gi, 'The end?')
                .replace(/Mummy/gi, 'Mumma')
                .replace(/Dadi\b/gi, 'Daadi')
                .replace(/\bDaadi\b/gi, 'Daadi');
            if (before !== idea[field]) ideaFixes++;
        }
    });
    
    // Fix "3D Pixar animation style" -> "3D animated style" (correct replacement)
    if (idea.readyPrompt && typeof idea.readyPrompt === 'string') {
        const before = idea.readyPrompt;
        // Fix the broken replacement from previous run
        idea.readyPrompt = idea.readyPrompt.replace(/3D 3D animated animation style/gi, '3D animated style');
        // Fix the original replacement
        idea.readyPrompt = idea.readyPrompt.replace(/3D Pixar animation style/gi, '3D animated style');
        // Fix "PROMPT: 3D Pixar" -> "PROMPT: 3D animated"
        idea.readyPrompt = idea.readyPrompt.replace(/PROMPT: 3D Pixar/gi, 'PROMPT: 3D animated');
        if (before !== idea.readyPrompt) ideaFixes++;
    }
    
    // Fix character consistency issues from Major Findings
    const majorFindings = parseJsonField(csvRow, 'Major Findings');
    if (majorFindings && Array.isArray(majorFindings)) {
        majorFindings.forEach(finding => {
            if (finding.suggestedFix && finding.title === 'Unapproved Character Name') {
                // Fix Mummy -> Mumma in dialogue/story
                if (idea.dialogue) {
                    const before = idea.dialogue;
                    idea.dialogue = idea.dialogue.replace(/Mummy/gi, 'Mumma');
                    if (before !== idea.dialogue) ideaFixes++;
                }
                if (idea.storyDetail) {
                    const before = idea.storyDetail;
                    idea.storyDetail = idea.storyDetail.replace(/Mummy/gi, 'Mumma');
                    if (before !== idea.storyDetail) ideaFixes++;
                }
            }
        });
    }
    
    // Fix Critical Findings - Brand Names (already handled above)
    
    // Fix Minor Findings - Typo Check specific to readyPrompt
    const minorFindings = parseJsonField(csvRow, 'Minor Findings');
    if (minorFindings && Array.isArray(minorFindings)) {
        minorFindings.forEach(finding => {
            if (finding.suggestedFix && finding.title === 'Typo Check' && idea.readyPrompt) {
                const before = idea.readyPrompt;
                idea.readyPrompt = idea.readyPrompt
                    .replace(/AAG LAGI THI/gi, 'ATTA GIRA THA')
                    .replace(/PAANI DAAL DIYA/gi, 'PAANI DAL DIYA')
                    .replace(/NO SCOld/gi, 'NO SCOLD')
                    .replace(/EKPairo SHOES/gi, 'EK PAIR SHOES')
                    .replace(/pakho/gi, 'pakdo')
                    .replace(/saambhaa lunga/gi, 'saambhal lunga')
                    .replace(/neela nahi hota/gi, 'neela hota')
                    .replace(/hiccers/gi, 'hiccups')
                    .replace(/The End story\?/gi, 'The end?')
                    .replace(/Mummy/gi, 'Mumma');
                if (before !== idea.readyPrompt) ideaFixes++;
            }
        });
    }
    
    // Fix Opening Cast Mismatch - use Rewritten Hook if available
    const criticalFindings = parseJsonField(csvRow, 'Critical Findings');
    if (criticalFindings && Array.isArray(criticalFindings)) {
        criticalFindings.forEach(finding => {
            if (finding.title === 'Character Consistency' && finding.suggestedFix && finding.suggestedFix.includes('pronoun')) {
                // Fix pronoun consistency - this is complex, skip auto
            }
        });
    }
    
    if (ideaFixes > 0) {
        updated++;
        fixesApplied += ideaFixes;
    }
});

console.log(`Ideas updated: ${updated}`);
console.log(`Total fixes applied: ${fixesApplied}`);

// Update metadata
jsonData.version = '2.0.2';
jsonData.generatedAt = new Date().toISOString();

// Write updated JSON
fs.writeFileSync(jsonPath, JSON.stringify(jsonData, null, 2), 'utf-8');
console.log('JSON file updated successfully!');