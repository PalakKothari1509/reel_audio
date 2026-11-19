with open('lib/content_library_service.dart', 'r', encoding='utf-8') as f:
    content = f.readlines()
# Remove line 234 (index 233)
del content[233]
with open('lib/content_library_service.dart', 'w', encoding='utf-8') as f:
    f.writelines(content)
print('Done')