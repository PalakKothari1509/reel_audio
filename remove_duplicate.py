with open('lib/content_library_service.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Find and remove the duplicate line 234 (index 233, 0-indexed)
# Both lines 233 and 234 have "static String? _testTempDir;" - we need to remove ONE of them
# Line 234 is index 233 (0-indexed)
new_lines = []
skip_next = False
for i, line in enumerate(lines):
    if i == 233:  # line 234 (0-indexed 233)
        continue  # skip this line
    new_lines.append(line)

with open('lib/content_library_service.dart', 'w', encoding='utf-8') as f:
    f.writelines(new_lines)

print("Removed line 234 successfully")