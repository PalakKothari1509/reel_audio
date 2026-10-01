$ErrorActionPreference = 'Stop'

# Phase 1 follow-through: "Soft pastel watercolor" was hardcoded in 6 files beyond the
# two named in the plan, including the main ContentPackage system prompt. Every one of
# them reaches the image generator, so leaving them means the contradiction survives the
# brand_system.dart fix.
#
# An array of pairs, not a hashtable: PowerShell hashtable keys are case-insensitive,
# so 'soft pastel watercolor' and 'Soft pastel watercolor' collide. Longest phrases come
# first so a short pattern cannot truncate a longer one.

$pairs = @(
    @('soft pastel watercolour storybook shading', 'Soft 3D Pixar/Disney-style render shading'),
    @('Soft pastel watercolor storybook illustration', 'Soft 3D Pixar/Disney-style render'),
    @('soft pastel watercolor storybook illustration', 'Soft 3D Pixar/Disney-style render'),
    @('soft pastel watercolor illustration', 'Soft 3D Pixar/Disney-style render'),
    @('Soft pastel watercolor illustration', 'Soft 3D Pixar/Disney-style render'),
    @('Soft pastel watercolor storybook aesthetic', 'Soft 3D Pixar/Disney-style render aesthetic'),
    @('Soft pastel watercolor storybook', 'Soft 3D Pixar/Disney-style render'),
    @('soft pastel watercolor storybook', 'Soft 3D Pixar/Disney-style render'),
    @('soft pastel watercolor style', 'Soft 3D Pixar/Disney-style render'),
    @('soft pastel watercolor', 'Soft 3D Pixar/Disney-style render'),
    @('Soft pastel watercolor', 'Soft 3D Pixar/Disney-style render'),
    @('soft watercolor, cream', 'Soft 3D Pixar/Disney-style render, cream'),
    @('soft watercolor', 'Soft 3D Pixar/Disney-style render'),
    @('in soft watercolor style', 'in soft 3D Pixar render style'),
    @('captured in soft watercolor style', 'rendered in soft 3D Pixar style')
)

$files = @(
    'lib\gemini_client.dart',
    'lib\format_adapter.dart',
    'lib\quick_content.dart',
    'lib\slide_prompts.dart',
    'lib\content_ideas.dart'
)

$utf8 = New-Object System.Text.UTF8Encoding($false)
$total = 0

foreach ($file in $files) {
    $path = Join-Path $PSScriptRoot "..\$file"
    if (-not (Test-Path -LiteralPath $path)) { continue }
    $text = [System.IO.File]::ReadAllText($path)
    $before = $text
    $count = 0
    foreach ($p in $pairs) {
        $n = ([regex]::Matches($text, [regex]::Escape($p[0]))).Count
        if ($n -gt 0) {
            # String.Replace(String,String) is ordinal, so case matters.
            $text = $text.Replace($p[0], $p[1])
            $count += $n
        }
    }
    if ($text -ne $before) {
        [System.IO.File]::WriteAllText($path, $text, $utf8)
        Write-Output "$file : $count replaced"
        $total += $count
    } else {
        Write-Output "$file : 0"
    }
}

Write-Output "TOTAL: $total"
