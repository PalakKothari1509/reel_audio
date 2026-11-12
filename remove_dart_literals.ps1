$content = Get-Content -Path 'lib/content_ideas.dart' -Raw

# Find buildDefaultHooks start
$startIdx = $content.IndexOf('List<HookIdea> buildDefaultHooks() {')
if ($startIdx -eq -1) { Write-Host 'ERROR: buildDefaultHooks not found'; exit 1 }

# Find end - scan forward for matching closing brace
$braceDepth = 0
$foundEnd = $false
for ($i = $startIdx; $i -lt $content.Length; $i++) {
    if ($content[$i] -eq '{') { $braceDepth++ }
    if ($content[$i] -eq '}') {
        $braceDepth--
        if ($braceDepth -eq 0) { $foundEnd = $true; break }
    }
}
if (-not $foundEnd) { Write-Host 'ERROR: end not found'; exit 1 }

# Remove buildDefaultHooks function
$content = $content.Substring(0, $startIdx) + $content.Substring($i + 1)

# Find and remove kDefaultHooks definition block
$startAlias = $content.IndexOf('final kDefaultHooks = buildDefaultHooks();')
if ($startAlias -eq -1) { Write-Host 'WARNING: kDefaultHooks not found' }
else {
    # Find end of kDay14PostIdeas block
    $endAlias = $content.IndexOf('.toList(growable: false);', $startAlias)
    if ($endAlias -eq -1) { Write-Host 'WARNING: end of alias block not found' }
    else {
        $endAlias += '.toList(growable: false);'.Length
        $content = $content.Substring(0, $startAlias) + $content.Substring($endAlias)
    }
}

Set-Content -Path 'lib/content_ideas.dart' -Value $content
Write-Host 'Done'
