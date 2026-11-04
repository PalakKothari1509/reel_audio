# setup-hosts.ps1
# Adds 127.0.0.1 contentrating.local to the Windows hosts file
# Requires Administrator privileges

$hostsPath = "C:\Windows\System32\drivers\etc\hosts"
$entry = "127.0.0.1 contentrating.local"

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Error "This script must be run as Administrator. Right-click PowerShell and select 'Run as Administrator', then try again."
    exit 1
}

# Check if entry already exists
$existing = Get-Content $hostsPath -ErrorAction SilentlyContinue | Where-Object { $_ -match "contentrating\.local" }

if ($existing) {
    Write-Host "Entry already exists in hosts file:`n$existing" -ForegroundColor Green
} else {
    # Add the entry
    Add-Content -Path $hostsPath -Value "`n`n# Content Rating Tool`n$entry"
    Write-Host "Successfully added to hosts file:`n$entry" -ForegroundColor Green
    Write-Host "`nYou can now access the tool at: http://contentrating.local:3001" -ForegroundColor Cyan
    Write-Host "Remember to start the server first: npm start" -ForegroundColor Cyan
}
