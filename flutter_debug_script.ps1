# Flutter/Android Project Debug Script
# Run this in PowerShell in your Flutter project directory: powershell -ExecutionPolicy Bypass -File flutter_debug_script.ps1

$projectPath = Get-Location
$outputFile = "debug_report.txt"

# Clear previous report
if (Test-Path $outputFile) { Remove-Item $outputFile }

# Function to add to report
function Log {
    param([string]$message)
    Write-Host $message
    Add-Content -Path $outputFile -Value $message
}

Log "=== FLUTTER PROJECT DEBUG REPORT ==="
Log "Generated: $(Get-Date)"
Log "Project Path: $projectPath"
Log ""

# 1. Check Flutter version
Log "=== FLUTTER & DART INFO ==="
Log "$(flutter --version)"
Log ""

# 2. Check Gradle cache size
Log "=== GRADLE CACHE STATUS ==="
$gradleCache = "$env:USERPROFILE\.gradle\caches"
if (Test-Path $gradleCache) {
    $cacheSize = (Get-ChildItem $gradleCache -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
    Log "Gradle Cache Size: $($cacheSize) MB"
    Log "Cache Location: $gradleCache"
} else {
    Log "Gradle cache not found"
}
Log ""

# 3. Check build directory corruption
Log "=== BUILD DIRECTORY STATUS ==="
$buildDir = "$projectPath\build\app\intermediates\incremental\debug\mergeDebugResources"
if (Test-Path $buildDir) {
    $fileCount = (Get-ChildItem $buildDir -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count
    Log "Build intermediates exists with $fileCount items"
} else {
    Log "Build intermediates directory missing (will be regenerated)"
}
Log ""

# 4. Find Flutter files
Log "=== FLUTTER FILE STRUCTURE ==="
Log "Dart files found:"
$dartFiles = Get-ChildItem -Path "$projectPath\lib" -Filter "*.dart" -Recurse | Select-Object -ExpandProperty FullName
foreach ($file in $dartFiles) {
    Log "  - $($file.Replace($projectPath, ''))"
}
Log ""

# 5. Search for Promotion Comments files
Log "=== PROMOTION COMMENTS RELATED FILES ==="
$promoFiles = Get-ChildItem -Path "$projectPath\lib" -Filter "*promo*" -Recurse -ErrorAction SilentlyContinue
$commentFiles = Get-ChildItem -Path "$projectPath\lib" -Filter "*comment*" -Recurse -ErrorAction SilentlyContinue

if ($promoFiles) {
    Log "Promotion files:"
    foreach ($file in $promoFiles) {
        Log "  - $($file.FullName.Replace($projectPath, ''))"
    }
} else {
    Log "No 'promo' files found"
}

if ($commentFiles) {
    Log "Comment files:"
    foreach ($file in $commentFiles) {
        Log "  - $($file.FullName.Replace($projectPath, ''))"
    }
} else {
    Log "No 'comment' files found"
}
Log ""

# 6. Check pubspec.yaml for plugins
Log "=== PUBSPEC.YAML (Plugin Dependencies) ==="
if (Test-Path "pubspec.yaml") {
    $pubspec = Get-Content "pubspec.yaml" -Raw
    Log $pubspec
} else {
    Log "pubspec.yaml not found"
}
Log ""

# 7. List all screens
Log "=== ALL SCREEN FILES ==="
$screens = Get-ChildItem -Path "$projectPath\lib\screens" -Filter "*.dart" -Recurse -ErrorAction SilentlyContinue
if ($screens) {
    foreach ($screen in $screens) {
        Log "  - $($screen.Name)"
    }
} else {
    Log "No screens directory or files found"
}
Log ""

# 8. Find API/Service files
Log "=== API/SERVICE FILES ==="
$services = Get-ChildItem -Path "$projectPath\lib" -Filter "*service*" -Recurse -ErrorAction SilentlyContinue
$apis = Get-ChildItem -Path "$projectPath\lib" -Filter "*api*" -Recurse -ErrorAction SilentlyContinue
if ($services) {
    foreach ($file in $services) {
        Log "  - $($file.FullName.Replace($projectPath, ''))"
    }
}
if ($apis) {
    foreach ($file in $apis) {
        Log "  - $($file.FullName.Replace($projectPath, ''))"
    }
}
Log ""

# 9. Check build.gradle
Log "=== BUILD.GRADLE (Android Config) ==="
if (Test-Path "android\app\build.gradle") {
    $buildGradle = Get-Content "android\app\build.gradle" -Raw
    Log $buildGradle.Substring(0, [Math]::Min(2000, $buildGradle.Length))
    Log "`n... (truncated for size)"
} else {
    Log "build.gradle not found"
}
Log ""

Log "=== DEBUG REPORT COMPLETE ==="
Log "Report saved to: debug_report.txt"

Write-Host "`n✓ Report generated: debug_report.txt"
Write-Host "Share the content of debug_report.txt with me"
