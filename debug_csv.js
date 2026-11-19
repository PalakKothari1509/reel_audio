const fs = require('fs');
const path = require('path');

// Read the CSV file
const csvPath = path.join('C:', 'Users', 'palak', 'Downloads', 'content_ideas_full_table (3).csv');
const csvContent = fs.readFileSync(csvPath, 'utf-8');

// Debug: print first 500 chars
console.log('First 500 chars:');
console.log(JSON.stringify(csvContent.substring(0, 500)));

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

if (rows.length > 0) {
    console.log(`First row (headers): ${rows[0].length} columns`);
    console.log(`First header: "${rows[0][0]}"`);
    console.log(`Second header: "${rows[0][1]}"`);
    
    if (rows.length > 1) {
        console.log(`Second row (first data): ${rows[1].length} columns`);
        console.log(`First data cell: "${rows[1][0]}"`);
        console.log(`Second data cell: "${rows[1][1]}"`);
    }
}