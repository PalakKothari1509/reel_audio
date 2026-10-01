$ErrorActionPreference = 'Stop'

# QuickIdea and its two stores moved to lib/models/quick_idea.dart. This removes the
# original definitions, lines 19 through 199 inclusive, which is the QuickIdea class,
# QuickIdeaStore and QuickHistoryStore. Line 1-18 are the imports, line 200 onward is
# the rest of the file.

$path = Join-Path $PSScriptRoot '..\lib\quick_content.dart'
$lines = [System.IO.File]::ReadAllLines($path)

if ($lines.Count -lt 200) { throw "Unexpected file length: $($lines.Count)" }
if ($lines[18].Trim() -ne 'class QuickIdea {') { throw "Line 19 is not 'class QuickIdea {' - refusing to cut." }
if ($lines[198].Trim() -ne '}') { throw "Line 199 is not a closing brace - refusing to cut." }
if ($lines[200].Trim() -ne '') { Write-Output "Note: line 201 is not blank: $($lines[200])" }

$kept = $lines[0..17] + $lines[199..($lines.Count - 1)]
$utf8 = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllLines($path, $kept, $utf8)

Write-Output "Removed $($lines.Count - $kept.Count) lines. Now $($kept.Count)."
