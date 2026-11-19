import json
import csv
import re
from datetime import datetime

# Read the JSON file
with open(r'C:\Flutter\reel_audio\assets\data\content_ideas.json', 'r', encoding='utf-8') as f:
    json_data = json.load(f)

# Read the CSV file
csv_data = {}
with open(r'C:\Users\palak\Downloads\content_ideas_full_table (3).csv', 'r', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    for row in reader:
        idea_id = row['Idea ID']
        csv_data[idea_id] = row

print(f"JSON ideas: {len(json_data['ideas'])}")
print(f"CSV ideas: {len(csv_data)}")

# Update each idea in JSON with CSV data
updated = 0
not_found = []

for idea in json_data['ideas']:
    idea_id = idea['id']
    if idea_id in csv_data:
        csv_row = csv_data[idea_id]
        
        # Update score
        idea['score'] = int(csv_row['Overall Score'])
        
        # Update band (verdict)
        idea['band'] = csv_row['Verdict']
        
        # Update reviewedOn with Evaluated At
        if csv_row.get('Evaluated At'):
            idea['reviewedOn'] = csv_row['Evaluated At']
        
        # Build comprehensive strategy from CSV evaluation data
        strategy_parts = []
        
        # Original strategy (production recommendations)
        original_strategy = idea.get('strategy', '')
        
        # Add evaluation summary
        strategy_parts.append(f"EVALUATION SUMMARY (v2.0.0):")
        strategy_parts.append(f"Overall Score: {csv_row['Overall Score']}/100 (Raw: {csv_row['Raw Score']})")
        strategy_parts.append(f"Verdict: {csv_row['Verdict']}")
        strategy_parts.append(f"Score Capped: {csv_row['Score Capped']}")
        strategy_parts.append(f"Version: {csv_row['Version']}")
        strategy_parts.append(f"Evaluation Mode: {csv_row.get('Evaluation Mode', 'N/A')}")
        strategy_parts.append(f"Evaluated At: {csv_row.get('Evaluated At', 'N/A')}")
        strategy_parts.append(f"Confidence: {csv_row.get('Confidence', 'N/A')}")
        strategy_parts.append("")
        
        # Dimension scores
        dimensions = [
            ('hookStrength', 'Hook Strength', 15),
            ('relatabilityAudienceFit', 'Relatability & Audience Fit', 15),
            ('payoffRetention', 'Payoff & Retention', 14),
            ('hinglishNaturalness', 'Hinglish Naturalness', 10),
            ('visualFeasibility', 'Visual Feasibility', 10),
            ('soundOffReadability', 'Sound-Off Readability', 8),
            ('shareSaveTrigger', 'Share/Save Trigger', 8),
            ('captionCommentPackage', 'Caption/Comment Package', 8),
            ('originality', 'Originality', 5),
            ('audioHook', 'Audio Hook', 7)
        ]
        
        strategy_parts.append("DIMENSION SCORES:")
        for dim_id, dim_name, weight in dimensions:
            score = csv_row.get(f'{dim_id} Score', 'N/A')
            strategy_parts.append(f"  {dim_name} (weight {weight}): {score}/10")
        strategy_parts.append("")
        
        # Gate Results
        if csv_row.get('Gate Results'):
            strategy_parts.append(f"GATE RESULTS: {csv_row['Gate Results']}")
            strategy_parts.append("")
        
        # Critical Findings
        if csv_row.get('Critical Findings'):
            strategy_parts.append(f"CRITICAL FINDINGS: {csv_row['Critical Findings']}")
            strategy_parts.append("")
        
        # Major Findings
        if csv_row.get('Major Findings'):
            strategy_parts.append(f"MAJOR FINDINGS: {csv_row['Major Findings']}")
            strategy_parts.append("")
        
        # Minor Findings
        if csv_row.get('Minor Findings'):
            strategy_parts.append(f"MINOR FINDINGS: {csv_row['Minor Findings']}")
            strategy_parts.append("")
        
        # Suggestions
        if csv_row.get('Suggestions'):
            strategy_parts.append(f"SUGGESTIONS: {csv_row['Suggestions']}")
            strategy_parts.append("")
        
        # Fixes to Reach 100
        if csv_row.get('Fixes to Reach 100'):
            strategy_parts.append(f"FIXES TO REACH 100: {csv_row['Fixes to Reach 100']}")
            strategy_parts.append("")
        
        # Potential Score
        if csv_row.get('Potential Score'):
            strategy_parts.append(f"POTENTIAL SCORE: {csv_row['Potential Score']}")
            strategy_parts.append("")
        
        # Rewritten Hook
        if csv_row.get('Rewritten Hook'):
            strategy_parts.append(f"REWRITTEN HOOK: {csv_row['Rewritten Hook']}")
            strategy_parts.append("")
        
        # Duplicate Of
        if csv_row.get('Duplicate Of'):
            strategy_parts.append(f"DUPLICATE OF: {csv_row['Duplicate Of']}")
            strategy_parts.append("")
        
        # Recommended Format
        if csv_row.get('Recommended Format'):
            strategy_parts.append(f"RECOMMENDED FORMAT: {csv_row['Recommended Format']}")
            strategy_parts.append("")
        
        # Season Tag
        if csv_row.get('Season Tag'):
            strategy_parts.append(f"SEASON TAG: {csv_row['Season Tag']}")
            strategy_parts.append("")
        
        # Deterministic Checks
        if csv_row.get('Deterministic Checks'):
            strategy_parts.append(f"DETERMINISTIC CHECKS: {csv_row['Deterministic Checks']}")
            strategy_parts.append("")
        
        # Original production recommendations (from existing strategy)
        if original_strategy:
            strategy_parts.append("---")
            strategy_parts.append("ORIGINAL PRODUCTION RECOMMENDATIONS:")
            strategy_parts.append(original_strategy)
        
        idea['strategy'] = '\n'.join(strategy_parts)
        updated += 1
    else:
        not_found.append(idea_id)

print(f"Updated: {updated}")
print(f"Not found in CSV: {not_found}")

# Update metadata
json_data['version'] = "2.0.0"
json_data['generatedAt'] = datetime.utcnow().isoformat() + 'Z'

# Write updated JSON
with open(r'C:\Flutter\reel_audio\assets\data\content_ideas.json', 'w', encoding='utf-8') as f:
    json.dump(json_data, f, ensure_ascii=False, indent=2)

print("JSON file updated successfully!")