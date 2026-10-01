$ErrorActionPreference = 'Stop'

# Inserts section 13 before the log table. The "## Log" heading was consumed by an
# earlier edit, so this restores it too.

$path = Join-Path $PSScriptRoot '..\REDESIGN_PLAN.md'
$text = [System.IO.File]::ReadAllText($path)
$lines = [System.IO.File]::ReadAllLines($path)

$idx = -1
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -like '| Date | Point | Result |*') { $idx = $i; break }
}
if ($idx -lt 0) { throw 'Log table header not found.' }
Write-Output "Log table at line $($idx + 1)"

$section = @'
---

## 13. The Content Studio architecture, as specified

Your latest architecture is largely consistent with 10 and 12, and needs no changes to
those decisions. Recorded here with the three places it collides with applied work.

### 13.1 Agreed and already reflected

| Your point | Where it already lives |
|---|---|
| One generator, no separate caption/hashtag/hook tools | 12.2, 11.3 Stage D |
| Idea to Format to Content Type to Script to Hook to Visual to Caption to SEO to Hashtags | 9 |
| Format and Content Type stay separate axes | 10.8, where `format_handbook.dart` owns both |
| Carousel must not be a Reel script split into slides | 9, format rules table |
| Trial Reel is a distinct type with its own generation | 10.6 |
| AI Content Brief screen before generating | 12.2, with format recommendation plus reasoning |
| Performance tracking only after real posting | 11.3 Stage E |
| Modes rather than ten separate features | 12.2, approved vs proposed |

### 13.2 Three collisions to settle

**A. Point 23 reverses a decision you made two messages ago.** You wrote:

> "every single character model is unambiguously rendered in a stylized 3D
> Pixar/Disney-inspired aesthetic, not traditional watercolor"

and instructed me to change it. I did: 30 occurrences across 6 files, and
`BrandDefaults.visualStyle` now reads "Soft 3D Pixar/Disney-style render, NOT
watercolor".

Point 23 now says the opposite, and proposes defining the style as "Fun Learning
With Palak soft watercolor children's illustration style".

The underlying reasoning is sound and worth separating from the conclusion. Not
depending on a studio name is good practice, because "NOT kawaii-chibi" and "NOT
flat 2D" are negative constraints against a look some generators will not
recognise. But the replacement proposed is watercolor, and the seven reference
renders are not. Adopting it would send every generation toward a look the
character art does not show, which is the same class of bug as the one just fixed,
only in the other direction.

To get a brand-owned style name without contradicting the assets:

```
Soft 3D Pixar/Disney-style children's illustration, warm Indian home settings,
pastel-leaning palette, rounded friendly shapes, expressive faces, clean
backgrounds, preschool-friendly. NOT flat 2D, NOT watercolor, NOT kawaii-chibi.
```

Nothing has been changed for point 23. This needs one word: **Pixar-derived, or
watercolor**.

**B. Point 21 splits the brand across six markdown files.** `brand.md` and
`characters.md` would duplicate what `brand_system.dart` now holds in `const`.
Moving them back into markdown recreates the drift just removed: 30 stale
watercolor strings, four character description sets, three age ranges.

The split is right for `formats.md`, `series.md` and `ideas.md`, which are data
that changes. It is wrong for brand and characters, which are identity and must
stay `const` to keep prompt builders synchronous.

**C. Point 18 and point 4 conflict with decisions in section 10.** The status ladder
here has nine values; 10.5 settled on six. The content-type enum here has seventeen
values; 10.8 settled on six, each with a `FormatSpec` contract behind it. Both should
defer to section 10 unless deliberately reopened, and if reopened the seventeen need
seventeen generation contracts, not seventeen names.

### 13.3 Still blocked

**The 50-format handbook.** This is now the fourth time it has blocked, and point 20
depends on it entirely. The app needs a definition per format, not a name. Twenty-six
format names exist across `content_ideas.md` and the bundled `assets/ideas/*.md`
files, and none has a structure attached. Without it, Stage A can propose a format
the generator has no rules for.

Worth checking: `assets/ideas/*.md` is four more idea files that are neither bundled
nor read (7.6). If the handbook is hiding in there, it is already in the repo.

### 13.4 One factual correction

Point 24's dashboard says "37 ideas". The library currently holds **57** - 24 seeded
posts plus 33 added this session. The dashboard count should be computed, not typed.

---

## Log

'@ -split "`r?`n"

$head = $lines[0..($idx - 1)]
while ($head.Count -gt 0 -and $head[-1].Trim() -eq '') { $head = $head[0..($head.Count - 2)] }
$tail = $lines[$idx..($lines.Count - 1)]

$out = $head + $section + $tail
$utf8 = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllLines($path, $out, $utf8)
Write-Output "Wrote $($out.Count) lines."
