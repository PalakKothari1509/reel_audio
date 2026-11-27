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