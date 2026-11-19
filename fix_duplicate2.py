with open('lib/content_library_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Find and remove the duplicate line 234 (which has 'action from line 234')
# Line 233: '  static String? _testTempDir; // Set by tests to override asset locking path'
# Line 234: '  static String? _testTempDir; // Set by tests to override asset loading path'

# We want to keep line 233 and remove line 234
lines = content.split('\n')

# Find lines that match exactly '  static String? _testTempDir; // Set by tests to override asset loading path'
lines_to_remove = []
for i, line in enumerate(lines):
    if line.strip() == '  static String? _testTempDir; // Set by tests to override asset loading path':
        lines_to_remove.append(i)
        print(f"Found duplicate at line {i+1}: {line.strip()}")

# Remove lines in reverse order to preserve indices
for idx in sorted([i for i, line in enumerate(lines) if line.strip() == '  static String? _testTempDir; // Set by tests to override asset loading path'], reverse=True):
    del lines[idx]
    print(f"Removed line {idx+1}")

with open('lib/content_library_service.dart', 'w', encoding='utf-8') as f:
    f.write('\n'.join(lines))

print("Done!")