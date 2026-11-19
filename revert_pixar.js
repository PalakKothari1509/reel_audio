const fs = require('fs');
const path = require('path');

const jsonPath = path.join(__dirname, 'assets', 'data', 'content_ideas.json');
const jsonData = JSON.parse(fs.readFileSync(jsonPath, 'utf-8'));

// Revert "3D animated style" back to "3D Pixar animation style"
let totalFixes = 0;

jsonData.ideas.forEach(idea => {
    if (idea.readyPrompt && typeof idea.readyPrompt === 'string') {
        const before = idea.readyPrompt;
        
        // Revert all variations back to "3D Pixar animation style"
        idea.readyPrompt = idea.readyPrompt
            .replace(/3D animated style/gi, '3D Pixar animation style')
            .replace(/PROMPT: 3D animated/gi, 'PROMPT: 3D Pixar animation style');
        
        if (before !== idea.readyPrompt) {
            totalFixes++;
        }
    }
});

console.log(`Reverted readyPrompt in ${totalFixes} ideas`);

// Update metadata
jsonData.version = '2.0.4';
jsonData.generatedAt = new Date().toISOString();

fs.writeFileSync(jsonPath, JSON.stringify(jsonData, null, 2), 'utf-8');
console.log('JSON file updated successfully!');