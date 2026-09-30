<#
.SYNOPSIS
Lets the real platform-tools adb discover and reach your phone over Wi-Fi.

.DESCRIPTION
This machine has firewall rules for PC Suite's adb (C:\Program Files (x86)\pcsuite\...)
but none for the adb that actually runs Flutter:

  C:\Users\<you>\AppData\Local\Android\Sdk\platform-tools\adb.exe

With no rule and the Wi-Fi network on the Public profile, Windows drops the
inbound mDNS traffic, so `adb mdns services` never finds the phone even with
Wireless debugging switched on. Ping keeps working, which is what makes it look
like everything is fine.

This adds rules for the correct adb.exe: mDNS discovery in and out, and inbound
TCP so `adb connect` can reach the phone on whatever port it picked.

Safe to run more than once: an existing identical rule is left alone.
#>
[CmdletBinding()]
param(
    [switch]$Remove
)

$ErrorActionPreference = 'Stop'
$adb = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'

if (-not (Test-Path $adb)) {
    throw "ADB not found at '$adb'."
}

# Self-elevate, because a firewall rule cannot be added without it.
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host 'This needs administrator rights. Reopening as administrator...'
    $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"")
    if ($Remove) { $argList += '-Remove' }
    try {
        Start-Process powershell -Verb RunAs -ArgumentList $argList -Wait
    }
    catch {
        throw 'Could not get administrator rights. Right-click PowerShell and Run as administrator, then run this file again.'
    }
    return
}

if ($Remove) {
    foreach ($name in @(
            'adb platform-tools mDNS (UDP-In)',
            'adb platform-tools mDNS (UDP-Out)',
            'adb platform-tools wireless debug (TCP-In)')) {
        if (Get-NetFirewallRule -DisplayName $name -ErrorAction SilentlyContinue) {
            Remove-NetFirewallRule -DisplayName $name
            Write-Host "Removed: $name" -ForegroundColor Yellow
        }
    }
    Write-Host 'Done. The rules are gone.' -ForegroundColor Green
    return
}

Write-Host "Adding firewall rules for: $adb" -ForegroundColor Cyan
Write-Host ''

$rules = @(
    @{
        Name  = 'adb platform-tools mDNS (UDP-In)'
        Proto = 'UDP'
        Port  = @{ LocalPort = '5353' }
        Dir   = 'Inbound'
    },
    @{
        Name  = 'adb platform-tools mDNS (UDP-Out)'
        Proto = 'UDP'
        Port  = @{ RemotePort = '5353' }
        Dir   = 'Outbound'
    },
    @{
        Name  = 'adb platform-tools wireless debug (TCP-In)'
        Proto = 'TCP'
        Port  = @{}
        Dir   = 'Inbound'
    }
)

foreach ($r in $rules) {
    if (Get-NetFirewallRule -DisplayName $r.Name -ErrorAction SilentlyContinue) {
        Write-Host "Already there: $($r.Name)" -ForegroundColor DarkGray
        continue
    }
    # Built up as a hashtable and then written into key by key. Appending the port
    # filter with += does not work here, because that would be adding a hashtable
    # to a hashtable rather than adding a key.
    $params = @{
        DisplayName = $r.Name
        Direction   = $r.Dir
        Program     = $adb
        Protocol    = $r.Proto
        Action      = 'Allow'
        Profile     = 'Any'
    }
    foreach ($key in $r.Port.Keys) {
        $params[$key] = $r.Port[$key]
    }
    New-NetFirewallRule @params | Out-Null
    Write-Host "Added: $($r.Name)" -ForegroundColor Green
}

Write-Host ''
Write-Host 'Restarting the adb server so it re-binds with the new rules...' -ForegroundColor Cyan
& $adb kill-server 2>&1 | Out-Null
Start-Sleep -Seconds 1
& $adb start-server 2>&1 | Out-String
& $adb mdns services 2>&1 | Out-String

Write-Host 'Now keep Wireless debugging ON and run: .\run_phone.ps1' -ForegroundColor Green
Write-Host 'If nothing shows yet, open the Wireless debugging screen on the phone and leave it open for a few seconds.' -ForegroundColor DarkGray
