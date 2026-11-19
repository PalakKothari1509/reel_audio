const fs = require('fs');
const path = require('path');

// Read the JSON file
const jsonPath = path.join(__dirname, 'assets', 'data', 'content_ideas.json');
const jsonData = JSON.parse(fs.readFileSync(jsonPath, 'utf-8'));

// Fix all readyPrompt occurrences of "3D Pixar style" and "3D 3D animated style"
let totalFixes = 0;

jsonData.ideas.forEach(idea => {
    if (idea.readyPrompt && typeof idea.readyPrompt === 'string') {
        const before = idea.readyPrompt;
        
        // Fix all variations
        idea.readyPrompt = idea.readyPrompt
            // Fix the broken double replacement first
            .replace(/3D 3D animated animation style/gi, '3D animated style')
            .replace(/3D 3D animated style/gi, '3D animated style')
            // Fix original "3D Pixar animation style" 
            .replace(/3D Pixar animation style/gi, '3D animated style')
            // Fix "3D Pixar style" in Part sections
            .replace(/3D Pixar style/gi, '3D animated style')
            // Fix "PROMPT: 3D Pixar" 
            .replace(/PROMPT: 3D Pixar/gi, 'PROMPT: 3D animated')
            // Fix any remaining "Pixar" references
            .replace(/\bPixar\b/gi, '3D animated');
        
        if (before !== idea.readyPrompt) {
            totalFixes++;
        }
    }
});

console.log(`Fixed readyPrompt in ${totalFixes} ideas`);

// Update metadata
jsonData.version = '2.0.3';
jsonData.generatedAt = new Date().toISOString();

// Write updated JSON
fs.writeFileSync(jsonPath, JSON.stringify(jsonData, null, 2), 'utf-8');
console.log('JSON file updated successfully!');