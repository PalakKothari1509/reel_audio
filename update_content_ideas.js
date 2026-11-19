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
console.log(`Total rows parsed: ${rows.length}`);

// Clean up headers and values (remove surrounding quotes if present)
function cleanValue(val) {
    if (val.startsWith('"') && val.endsWith('"') && val.length >= 2) {
        return val.slice(1, -1);
    }
    return val;
}

const headers = rows[0].map(cleanValue);
console.log(`Headers: ${headers.length}`);
console.log(`First header: "${headers[0]}"`);
console.log(`Second header: "${headers[1]}"`);

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
if (Object.keys(csvData).length > 0) {
    console.log(`First idea: ${Object.keys(csvData)[0]}`);
    console.log(`First idea title: ${csvData[Object.keys(csvData)[0]]['Title']}`);
}

// Update each idea in JSON with CSV data
let updated = 0;
const notFound = [];

jsonData.ideas.forEach(idea => {
    const ideaId = idea.id;
    if (csvData[ideaId]) {
        const csvRow = csvData[ideaId];
        
        // Update score
        idea.score = parseInt(csvRow['Overall Score']) || 0;
        
        // Update band (verdict)
        idea.band = csvRow['Verdict'] || '';
        
        // Update reviewedOn with Evaluated At
        if (csvRow['Evaluated At']) {
            idea.reviewedOn = csvRow['Evaluated At'];
        }
        
        // Build comprehensive strategy from CSV evaluation data
        const strategyParts = [];
        
        // Original strategy (production recommendations)
        const originalStrategy = idea.strategy || '';
        
        // Add evaluation summary
        strategyParts.push('EVALUATION SUMMARY (v2.0.0):');
        strategyParts.push(`Overall Score: ${csvRow['Overall Score']}/100 (Raw: ${csvRow['Raw Score']})`);
        strategyParts.push(`Verdict: ${csvRow['Verdict']}`);
        strategyParts.push(`Score Capped: ${csvRow['Score Capped']}`);
        strategyParts.push(`Version: ${csvRow['Version']}`);
        strategyParts.push(`Evaluation Mode: ${csvRow['Evaluation Mode'] || 'N/A'}`);
        strategyParts.push(`Evaluated At: ${csvRow['Evaluated At'] || 'N/A'}`);
        strategyParts.push(`Confidence: ${csvRow['Confidence'] || 'N/A'}`);
        strategyParts.push('');
        
        // Dimension scores
        const dimensions = [
            { id: 'hookStrength', name: 'Hook Strength', weight: 15 },
            { id: 'relatabilityAudienceFit', name: 'Relatability & Audience Fit', weight: 15 },
            { id: 'payoffRetention', name: 'Payoff & Retention', weight: 14 },
            { id: 'hinglishNaturalness', name: 'Hinglish Naturalness', weight: 10 },
            { id: 'visualFeasibility', name: 'Visual Feasibility', weight: 10 },
            { id: 'soundOffReadability', name: 'Sound-Off Readability', weight: 8 },
            { id: 'shareSaveTrigger', name: 'Share/Save Trigger', weight: 8 },
            { id: 'captionCommentPackage', name: 'Caption/Comment Package', weight: 8 },
            { id: 'originality', name: 'Originality', weight: 5 },
            { id: 'audioHook', name: 'Audio Hook', weight: 7 }
        ];
        
        strategyParts.push('DIMENSION SCORES:');
        dimensions.forEach(dim => {
            const score = csvRow[`${dim.id} Score`] || 'N/A';
            strategyParts.push(`  ${dim.name} (weight ${dim.weight}): ${score}/10`);
        });
        strategyParts.push('');
        
        // Additional evaluation fields
        const extraFields = [
            { key: 'Gate Results', label: 'GATE RESULTS' },
            { key: 'Critical Findings', label: 'CRITICAL FINDINGS' },
            { key: 'Major Findings', label: 'MAJOR FINDINGS' },
            { key: 'Minor Findings', label: 'MINOR FINDINGS' },
            { key: 'Suggestions', label: 'SUGGESTIONS' },
            { key: 'Fixes to Reach 100', label: 'FIXES TO REACH 100' },
            { key: 'Potential Score', label: 'POTENTIAL SCORE' },
            { key: 'Rewritten Hook', label: 'REWRITTEN HOOK' },
            { key: 'Duplicate Of', label: 'DUPLICATE OF' },
            { key: 'Recommended Format', label: 'RECOMMENDED FORMAT' },
            { key: 'Season Tag', label: 'SEASON TAG' },
            { key: 'Deterministic Checks', label: 'DETERMINISTIC CHECKS' }
        ];
        
        extraFields.forEach(field => {
            if (csvRow[field.key]) {
                strategyParts.push(`${field.label}: ${csvRow[field.key]}`);
                strategyParts.push('');
            }
        });
        
        // Original production recommendations
        if (originalStrategy) {
            strategyParts.push('---');
            strategyParts.push('ORIGINAL PRODUCTION RECOMMENDATIONS:');
            strategyParts.push(originalStrategy);
        }
        
        idea.strategy = strategyParts.join('\n');
        updated++;
    } else {
        notFound.push(ideaId);
    }
});

console.log(`Updated: ${updated}`);
console.log(`Not found in CSV: ${notFound.join(', ')}`);

// Update metadata
jsonData.version = '2.0.0';
jsonData.generatedAt = new Date().toISOString();

// Write updated JSON
fs.writeFileSync(jsonPath, JSON.stringify(jsonData, null, 2), 'utf-8');
console.log('JSON file updated successfully!');