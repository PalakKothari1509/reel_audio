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

// Helper to parse JSON fields from CSV (they're stored as JSON strings)
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
    
    // 2. Apply fixes from Critical Findings
    const criticalFindings = parseJsonField(csvRow, 'Critical Findings');
    if (criticalFindings && Array.isArray(criticalFindings)) {
        criticalFindings.forEach(finding => {
            if (finding.suggestedFix) {
                // Apply specific fixes based on finding type
                if (finding.title === 'Brand Names' && finding.suggestedFix.includes('Remove brand names')) {
                    // Remove brand names from readyPrompt and strategy
                    if (idea.readyPrompt) {
                        idea.readyPrompt = idea.readyPrompt.replace(/Pixar/gi, '3D animated');
                        idea.readyPrompt = idea.readyPrompt.replace(/3D Pixar animation style/gi, '3D animated style');
                    }
                }
                if (finding.title === 'Character Consistency' && finding.suggestedFix.includes('pronoun')) {
                    // Fix pronoun consistency in story fields
                    const fields = ['storyDetail', 'endingBeat', 'readyPrompt'];
                    fields.forEach(field => {
                        if (idea[field]) {
                            idea[field] = idea[field].replace(/\bhe\b/gi, 'she').replace(/\bhis\b/gi, 'her').replace(/\bhim\b/gi, 'her');
                        }
                    });
                }
                if (finding.title === 'Safety Violation' && finding.suggestedFix.includes('adult')) {
                    // Ensure adult supervision is clear
                }
            }
        });
    }
    
    // 3. Apply fixes from Major Findings
    const majorFindings = parseJsonField(csvRow, 'Major Findings');
    if (majorFindings && Array.isArray(majorFindings)) {
        majorFindings.forEach(finding => {
            if (finding.suggestedFix) {
                if (finding.title === 'Opening Cast Mismatch' && finding.suggestedFix.includes('approved character names')) {
                    // The opening should only use approved characters
                    // This is already handled by Rewritten Hook
                }
                if (finding.title === 'Unapproved Character Name' && finding.suggestedFix.includes('approved characters')) {
                    // Fix character names in dialogue/story
                    if (idea.dialogue) {
                        idea.dialogue = idea.dialogue.replace(/Mummy/gi, 'Mumma');
                    }
                    if (idea.storyDetail) {
                        idea.storyDetail = idea.storyDetail.replace(/Mummy/gi, 'Mumma');
                    }
                    if (idea.readyPrompt) {
                        idea.readyPrompt = idea.readyPrompt.replace(/Mummy/gi, 'Mumma');
                    }
                }
            }
        });
    }
    
    // 4. Apply fixes from Minor Findings
    const minorFindings = parseJsonField(csvRow, 'Minor Findings');
    if (minorFindings && Array.isArray(minorFindings)) {
        minorFindings.forEach(finding => {
            if (finding.suggestedFix) {
                if (finding.title === 'Typo Check' && finding.suggestedFix.includes('Review on-screen text')) {
                    // Fix common typos in readyPrompt
                    if (idea.readyPrompt) {
                        idea.readyPrompt = idea.readyPrompt.replace(/AAG LAGI THI/gi, 'ATTA GIRI THI');
                        idea.readyPrompt = idea.readyPrompt.replace(/PAANI DAAL DIYA/gi, 'PAANI DAL DIYA');
                        idea.readyPrompt = idea.readyPrompt.replace(/PROMPT:/gi, 'PROMPT:');
                        idea.readyPrompt = idea.readyPrompt.replace(/NO SCOld/gi, 'NO SCOLD');
                        idea.readyPrompt = idea.readyPrompt.replace(/EKPairo SHOES/gi, 'EK PAIR SHOES');
                        idea.readyPrompt = idea.readyPrompt.replace(/pakho/gi, 'pakdo');
                        idea.readyPrompt = idea.readyPrompt.replace(/saambhaa lunga/gi, 'saambhal lunga');
                        idea.readyPrompt = idea.readyPrompt.replace(/neela nahi hota/gi, 'neela hota');
                        idea.readyPrompt = idea.readyPrompt.replace(/hiccers/gi, 'hiccups');
                        idea.readyPrompt = idea.readyPrompt.replace(/The End story\?/gi, 'The end?');
                    }
                }
                if (finding.title === 'Caption Story Mismatch' && finding.suggestedFix.includes('Ensure caption references')) {
                    // Caption improvement would need manual work
                }
                if (finding.title === 'Generic Pinned Comment' && finding.suggestedFix.includes('specific question')) {
                    // Could update pinnedComment but leaving for now
                }
            }
        });
    }
    
    // 5. Apply Suggestions
    const suggestions = parseJsonField(csvRow, 'Suggestions');
    if (suggestions && Array.isArray(suggestions)) {
        suggestions.forEach(sugg => {
            if (sugg.suggested) {
                if (sugg.title === 'Add an opening hook' && sugg.suggested) {
                    idea.opening = sugg.suggested;
                    ideaFixes++;
                }
            }
        });
    }
    
    // 6. Fix specific known issues from evaluation
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
    
    // Fix "Ria" pronoun consistency (she/her)
    // This is complex, skip auto-fix
    
    // Fix "Cuty" pronoun (she/her for the bunny character)
    // Skip auto-fix
    
    // Remove brand names from readyPrompt
    if (idea.readyPrompt) {
        const before = idea.readyPrompt;
        idea.readyPrompt = idea.readyPrompt.replace(/Pixar/gi, '3D animated');
        idea.readyPrompt = idea.readyPrompt.replace(/3D Pixar animation style/gi, '3D animated style');
        if (before !== idea.readyPrompt) ideaFixes++;
    }
    
    // Fix common Hinglish issues
    if (idea.dialogue) {
        const before = idea.dialogue;
        idea.dialogue = idea.dialogue.replace(/Mummy/gi, 'Mumma');
        idea.dialogue = idea.dialogue.replace(/pakho/gi, 'pakdo');
        idea.dialogue = idea.dialogue.replace(/saambhaa lunga/gi, 'saambhal lunga');
        if (before !== idea.dialogue) ideaFixes++;
    }
    
    // Fix storyDetail common issues
    if (idea.storyDetail) {
        const before = idea.storyDetail;
        idea.storyDetail = idea.storyDetail.replace(/Mummy/gi, 'Mumma');
        idea.storyDetail = idea.storyDetail.replace(/pakho/gi, 'pakdo');
        idea.storyDetail = idea.storyDetail.replace(/saambhaa lunga/gi, 'saambhal lunga');
        idea.storyDetail = idea.storyDetail.replace(/hiccers/gi, 'hiccups');
        idea.storyDetail = idea.storyDetail.replace(/The Very Hungry Caterpillar/gi, 'a storybook');
        if (before !== idea.storyDetail) ideaFixes++;
    }
    
    if (ideaFixes > 0) {
        updated++;
        fixesApplied += ideaFixes;
    }
});

console.log(`Ideas updated: ${updated}`);
console.log(`Total fixes applied: ${fixesApplied}`);

// Update metadata
jsonData.version = '2.0.1';
jsonData.generatedAt = new Date().toISOString();

// Write updated JSON
fs.writeFileSync(jsonPath, JSON.stringify(jsonData, null, 2), 'utf-8');
console.log('JSON file updated successfully!');