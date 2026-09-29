powershell -ExecutionPolicy Bypass -Command {
    $projectPath = Get-Location
    $outputFile = "debug_report.txt"

    if (Test-Path $outputFile) { Remove-Item $outputFile }

    function Log {
        param([string]$msg)
        Write-Host $msg
        Add-Content -Path $outputFile -Value $msg
    }

    Log "=== FLUTTER DEBUG REPORT ==="
    Log "Time: $(Get-Date)"
    Log "Path: $projectPath"
    Log ""

    Log "=== FLUTTER VERSION ==="
    flutter --version | ForEach-Object { Log $_ }
    Log ""

    Log "=== GRADLE CACHE ==="
    $gradleCache = "$env:USERPROFILE\.gradle\caches"
    if (Test-Path $gradleCache) {
        Log "Gradle cache found at: $gradleCache"
    } else {
        Log "No gradle cache found"
    }
    Log ""

    Log "=== DART FILES ==="
    Get-ChildItem -Path "$projectPath\lib" -Filter "*.dart" -Recurse | ForEach-Object {
        Log $_.FullName.Replace($projectPath, "")
    }
    Log ""

    Log "=== SCREENS ==="
    Get-ChildItem -Path "$projectPath\lib\screens" -Filter "*.dart" -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
        Log $_.Name
    }
    Log ""

    Log "=== PUBSPEC.YAML ==="
    if (Test-Path "pubspec.yaml") {
        Get-Content "pubspec.yaml" | ForEach-Object { Log $_ }
    }
    Log ""

    Log "=== REPORT COMPLETE ==="
    Write-Host "Report saved to debug_report.txt"
}
