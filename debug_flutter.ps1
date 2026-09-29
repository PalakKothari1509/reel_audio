# Flutter Project Debug Script
# Usage: powershell -ExecutionPolicy Bypass -File debug_flutter.ps1

$projectPath = Get-Location
$reportFile = "debug_report.txt"

# Remove old report if exists
if (Test-Path $reportFile) {
    Remove-Item $reportFile
}

# Logging function
function WriteLog {
    param([string]$text)
    Write-Host $text
    Add-Content -Path $reportFile -Value $text
}

WriteLog "=========================================="
WriteLog "FLUTTER PROJECT DEBUG REPORT"
WriteLog "=========================================="
WriteLog "Generated: $(Get-Date)"
WriteLog "Project: $projectPath"
WriteLog ""

WriteLog "--- FLUTTER VERSION ---"
flutter --version | ForEach-Object { WriteLog $_ }
WriteLog ""

WriteLog "--- DART FILES ---"
$dartFiles = Get-ChildItem -Path "lib" -Filter "*.dart" -Recurse -ErrorAction SilentlyContinue
if ($dartFiles) {
    foreach ($file in $dartFiles) {
        WriteLog $file.FullName.Replace($projectPath, ".")
    }
} else {
    WriteLog "No dart files found"
}
WriteLog ""

WriteLog "--- SCREEN FILES ---"
$screens = Get-ChildItem -Path "lib\screens" -Filter "*.dart" -Recurse -ErrorAction SilentlyContinue
if ($screens) {
    foreach ($screen in $screens) {
        WriteLog $screen.Name
    }
} else {
    WriteLog "No screens found"
}
WriteLog ""

WriteLog "--- PUBSPEC.YAML ---"
if (Test-Path "pubspec.yaml") {
    $content = Get-Content "pubspec.yaml" -Raw
    WriteLog $content
} else {
    WriteLog "pubspec.yaml not found"
}
WriteLog ""

WriteLog "=========================================="
WriteLog "REPORT COMPLETE - Check debug_report.txt"
WriteLog "=========================================="

Write-Host "`nDone! Check debug_report.txt for full details."
