<#
.SYNOPSIS
Run the Flutter app on a wirelessly paired Android phone.

.DESCRIPTION
Wireless debugging ports rotate every time you toggle the setting on the phone,
so hardcoding 192.168.x.x:37639 breaks constantly. This script avoids that:

  1. Tries `adb mdns services` to discover the current IP:port automatically.
  2. Falls back to the last address that worked (cached in .adb_wireless_cache).
  3. Falls back to an already-connected device in `adb devices`.
  4. Only asks you to pair if the phone has never been paired before.

Pairing is a one-time operation. Android remembers the paired device until you
tap "Forget paired device" in Wireless debugging settings, so after the first
successful run this script needs no input at all.

.EXAMPLE
.\run_phone.ps1
.\run_phone.ps1 -Profile          # list known mDNS services and exit
.\run_phone.ps1 -Pair             # force a fresh pairing
.\run_phone.ps1 -DeviceAddress 192.168.29.91:37639   # manual override
#>
[CmdletBinding()]
param(
    [switch]$Pair,
    [switch]$Profile,
    [string]$PairAddress,
    [string]$DeviceAddress
)

$ErrorActionPreference = 'Stop'
$projectRoot = $PSScriptRoot
$platformTools = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools'
$adb = Join-Path $platformTools 'adb.exe'
$cacheFile = Join-Path $projectRoot '.adb_wireless_cache'

if (-not (Test-Path $adb)) {
    throw "ADB was not found at '$adb'. Check your Android SDK installation."
}
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw 'Flutter was not found on PATH. Add the Flutter SDK bin directory, then run this script again.'
}

$env:Path = "$platformTools;$env:Path"

function Invoke-Adb {
    param([string[]]$Arguments)
    $output = & $adb @Arguments 2>&1
    [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output   = ($output | Out-String).Trim()
    }
}

<#
Returns the address of the first _adb-tls-connect service that is reachable.
mDNS entries look like:  S7GMN...  abcd-efgh-ijkl._adb-tls-connect. 192.168.29.91:37639
#>
function Find-MdnsService {
    param(
        [string]$ServiceType = '_adb-tls-connect',
        [int]$TimeoutSeconds = 15
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        $result = Invoke-Adb -Arguments @('mdns', 'services')
        $matches = [regex]::Matches(
            $result.Output,
            "$([regex]::Escape($ServiceType))\.?\s+(\S+):(\d+)",
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
        )

        $candidates = @(
            foreach ($m in $matches) {
                "$($m.Groups[1].Value):$($m.Groups[2].Value)"
            }
        ) | Select-Object -Unique

        # Try each advertised address once. adb's cache can hold stale entries
        # from earlier sessions, so the first one is not necessarily the phone.
        foreach ($candidate in $candidates) {
            $probe = Invoke-Adb -Arguments @('connect', $candidate)
            if ($probe.ExitCode -eq 0 -and $probe.Output -match 'connected to') {
                return $candidate
            }
        }

        if ($candidates) {
            # Services were advertised but none answered, so stop waiting.
            return $null
        }
        Start-Sleep -Milliseconds 750
    }
    return $null
}

function Get-ConnectedDevice {
    $result = Invoke-Adb -Arguments @('devices')
    foreach ($line in ($result.Output -split "`r?`n")) {
        if ($line -match '^(\S+)\s+device$') {
            return $Matches[1]
        }
    }
    return $null
}

function Get-UsbDevice {
    $result = Invoke-Adb -Arguments @('devices')
    foreach ($line in ($result.Output -split "`r?`n")) {
        if ($line -match '^(\S+)\s+device\s*$' -and $Matches[1] -notmatch ':') {
            return $Matches[1]
        }
    }
    return $null
}

function Save-Cache {
    param([string]$Serial, [string]$Address)
    if (-not $Address) { return }
    $entry = "{0}|{1}" -f $Serial, $Address
    Set-Content -LiteralPath $cacheFile -Value $entry -Encoding ascii
}

<#
Prompts until the user types a valid IP:port. Keeps asking instead of dying,
so a typo never costs you a re-run.
#>
function Read-AddressInput {
    param([string]$Prompt, [string]$Example)
    while ($true) {
        $value = (Read-Host $Prompt).Trim()
        if ($value -match '^\S+:\d+$') {
            return $value
        }
        Write-Host "That does not look right. Copy the 'IP address & port' box from the phone, like $Example" -ForegroundColor Yellow
    }
}

<#
Asks the phone itself what its Wi-Fi IP is, over USB. This is the only way to
get a correct address when the DHCP lease has moved, and it means nobody has to
read digits off a phone screen.
#>
function Get-PhoneWlanAddress {
    param([string]$Serial)
    foreach ($iface in @('wlan0', 'wlan1')) {
        $result = Invoke-Adb -Arguments @('-s', $Serial, 'shell', "ip -f inet addr show $iface")
        $match = [regex]::Match($result.Output, 'inet\s+(\d+\.\d+\.\d+\.\d+)')
        if ($match.Success) {
            return $match.Groups[1].Value
        }
    }
    return $null
}

<# Pings the local /24 and returns the hosts that answered. #>

<#
Fallback when mDNS is unavailable: find hosts on the LAN that expose an open
port in the range adbd uses for wireless debugging, then let adb try them.
#>

Push-Location $projectRoot
try {
    if ($Profile) {
        Write-Host 'mDNS services advertised by nearby devices:'
        (Invoke-Adb -Arguments @('mdns', 'services')).Output | ForEach-Object { Write-Host "  $_" }
        Write-Host ''
        Write-Host 'Currently connected devices:'
        (Invoke-Adb -Arguments @('devices', '-l')).Output | ForEach-Object { Write-Host "  $_" }
        exit 0
    }

    $target = $null

    # 1. Explicit override.
    if ($DeviceAddress) {
        $target = $DeviceAddress.Trim()
        Write-Host "Using provided address $target"
    }

    # 2. Already connected to something.
    if (-not $target) {
        $existing = Get-ConnectedDevice
        if ($existing) {
            Write-Host "Already connected to $existing"
            $target = $existing
        }
    }

    # 3. USB device, promoted to a stable TCP port. This sidesteps the rotating
    #    ports entirely: adbd keeps listening on 5555 until the phone reboots.
    #    The phone is asked for its own Wi-Fi IP so DHCP changes don't matter.
    if (-not $target -and -not $Pair) {
        $usb = Get-UsbDevice
        if ($usb) {
            Write-Host "USB device $usb found, switching it to wireless debugging on port 5555."
            Write-Host 'This fixed port resets after the phone reboots, but it never rotates.'
            [void](Invoke-Adb -Arguments @('-s', $usb, 'tcpip', '5555'))
            Start-Sleep -Seconds 3
            $phoneIp = Get-PhoneWlanAddress -Serial $usb
            if ($phoneIp) {
                Write-Host "Phone reports its Wi-Fi IP as $phoneIp"
                $guess = "$phoneIp`:5555"
                $probe = Invoke-Adb -Arguments @('connect', $guess)
                if ($probe.ExitCode -eq 0 -and $probe.Output -match 'connected to') {
                    $target = $guess
                    Write-Host "Connected to $guess"
                }
            }
        }
    }

    # 4. mDNS discovery. Covers the normal case: wireless debugging already on.
    if (-not $target) {
        Write-Host 'Looking for the phone over mDNS (make sure Wireless debugging is ON)...'
        $found = Find-MdnsService
        if ($found) {
            $target = $found
            Write-Host "Discovered $target"
        }
        else {
            Write-Host 'mDNS found nothing.' -ForegroundColor Yellow
            Write-Host 'Plug the phone into USB once, or enter the address by hand below.' -ForegroundColor Yellow
        }
    }

    # 4b. Optional: nothing. mDNS is the supported discovery path, and USB
    #     (step 3) is the reliable fallback. A manual port scan proved too slow
    #     and too noisy to be worth running on every launch.

    # 5. Cached address from a previous successful run.
    if (-not $target -and (Test-Path $cacheFile)) {
        $cached = (Get-Content -LiteralPath $cacheFile -Raw -ErrorAction SilentlyContinue).Trim()
        if ($cached -and $cached -match '^(.*\|)?(\S+:\d+)$') {
            $candidate = $Matches[2]
            Write-Host "Trying cached address $candidate"
            $probe = Invoke-Adb -Arguments @('connect', $candidate)
            if ($probe.ExitCode -eq 0 -and $probe.Output -match 'connected to') {
                $target = $candidate
            }
        }
    }

    # 6. Last resort: ask. Pairing only when the phone has not been paired yet.
    if (-not $target) {
        Write-Host ''
        Write-Host 'On the phone, open Developer options > Wireless debugging.' -ForegroundColor Cyan
        Write-Host 'Tell me the IP address and port shown in the main screen.' -ForegroundColor Cyan
        Write-Host 'If it says "Pair device with pairing code", we also need to pair first.' -ForegroundColor Cyan
        Write-Host ''

        $doPair = Read-Host 'Has this phone been paired with this computer before? (y/n)'
        while ($doPair -notmatch '^\s*(y|n)\s*$') {
            Write-Host 'Please type just y or n.' -ForegroundColor Yellow
            $doPair = Read-Host 'Has this phone been paired with this computer before? (y/n)'
        }

        if ($doPair -match '^\s*n') {
            $pairAddr = $PairAddress
            if (-not $pairAddr) {
                Write-Host ''
                Write-Host 'Tap "Pair device with pairing code" on the phone.' -ForegroundColor Cyan
                $pairAddr = Read-AddressInput -Prompt 'Pairing address (IP:port) from that pop-up' -Example '192.168.29.92:42449'
            }

            Write-Host 'Now enter the 6-digit code when ADB asks for it.' -ForegroundColor Cyan
            $pairResult = Invoke-Adb -Arguments @('pair', $pairAddr)
            if ($pairResult.ExitCode -ne 0) {
                throw "Wireless pairing failed. $($pairResult.Output)"
            }
            Write-Host 'Paired. This is a one-time step; later runs will not ask again.' -ForegroundColor Green
        }

        $connAddr = $DeviceAddress
        if (-not $connAddr) {
            Write-Host ''
            $connAddr = Read-AddressInput -Prompt 'Connect address (IP:port) from the main Wireless debugging screen' -Example '192.168.29.92:37639'
        }
        $target = $connAddr
    }

    $connectResult = Invoke-Adb -Arguments @('connect', $target)
    if ($connectResult.ExitCode -ne 0 -or $connectResult.Output -notmatch 'connected to|already connected') {
        throw "ADB could not connect to $target. $($connectResult.Output)"
    }

    Save-Cache -Serial $target -Address $target

    & flutter devices
    if ($LASTEXITCODE -ne 0) {
        throw 'Flutter could not list connected devices.'
    }

    Write-Host "Starting Flutter on $target. Press r to hot reload, R to hot restart, or q to quit."
    & flutter run -d $target
    exit $LASTEXITCODE
}
finally {
    Pop-Location
}
