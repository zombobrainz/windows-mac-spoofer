# MAC Spoofer for Windows
# Finds your adapters, lets you pick one, then randomizes, sets, or restores its MAC.

# --- Auto-elevate to Administrator ---
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
           ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    $self = if ($PSCommandPath) { $PSCommandPath } else { [Diagnostics.Process]::GetCurrentProcess().MainModule.FileName }
    if ($self -like '*.ps1') {
        Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$self`""
    } else {
        Start-Process $self -Verb RunAs
    }
    exit
}

$ClassKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002BE10318}'

function Get-AdapterKey($nic) {
    Get-ChildItem $ClassKey -ErrorAction SilentlyContinue | Where-Object {
        (Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue).NetCfgInstanceId -eq $nic.InterfaceGuid
    } | Select-Object -First 1
}

function New-RandomMac {
    $b = 1..5 | ForEach-Object { '{0:X2}' -f (Get-Random -Maximum 256) }
    '02' + ($b -join '')   # 02 = locally administered, unicast
}

function Format-Mac($m) { ($m -replace '(.{2})(?=.)', '$1-') }

function Pause-Exit { Write-Host ""; Read-Host "Press Enter to exit" | Out-Null; exit }

Clear-Host
Write-Host "=== MAC Spoofer ===" -ForegroundColor Cyan
Write-Host ""

# --- Detect adapters ---
$adapters = @(Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Sort-Object Status, Name)
if ($adapters.Count -eq 0) {
    Write-Host "No physical network adapters found." -ForegroundColor Red
    Pause-Exit
}

Write-Host "Detected adapters:"
for ($i = 0; $i -lt $adapters.Count; $i++) {
    $a = $adapters[$i]
    Write-Host ("  [{0}] {1,-20} {2,-14} {3}" -f ($i + 1), $a.Name, $a.Status, $a.MacAddress)
}
Write-Host ""

$default = 1
$up = $adapters | Where-Object Status -eq 'Up' | Select-Object -First 1
if ($up) { $default = [array]::IndexOf($adapters, $up) + 1 }

$sel = Read-Host "Choose adapter number (Enter = $default)"
if ([string]::IsNullOrWhiteSpace($sel)) { $sel = $default }
if ($sel -notmatch '^\d+$' -or [int]$sel -lt 1 -or [int]$sel -gt $adapters.Count) {
    Write-Host "Invalid choice." -ForegroundColor Red
    Pause-Exit
}
$nic = $adapters[[int]$sel - 1]
$key = Get-AdapterKey $nic
if (-not $key) {
    Write-Host "Couldn't find the registry entry for $($nic.Name)." -ForegroundColor Red
    Pause-Exit
}

Write-Host ""
Write-Host "Selected: $($nic.Name)  (current MAC: $($nic.MacAddress))" -ForegroundColor Yellow
Write-Host ""
Write-Host "  [1] Random MAC"
Write-Host "  [2] Enter a custom MAC"
Write-Host "  [3] Restore original MAC"
Write-Host ""
$choice = Read-Host "Choose an option"

switch ($choice) {
    '1' { $mac = New-RandomMac }
    '2' {
        $in = Read-Host "Enter MAC (e.g. 02-11-22-33-44-55)"
        $mac = ($in -replace '[-:\.\s]', '').ToUpper()
        if ($mac -notmatch '^[0-9A-F]{12}$') {
            Write-Host "That isn't a valid MAC (need 12 hex digits)." -ForegroundColor Red
            Pause-Exit
        }
        if ($mac[1] -notin '2','6','A','E') {
            Write-Host "Note: many drivers only accept MACs whose 2nd digit is 2, 6, A or E." -ForegroundColor DarkYellow
        }
    }
    '3' { $mac = $null }
    default { Write-Host "Invalid option." -ForegroundColor Red; Pause-Exit }
}

try {
    if ($mac) {
        Set-ItemProperty -Path $key.PSPath -Name NetworkAddress -Value $mac -ErrorAction Stop
    } else {
        Remove-ItemProperty -Path $key.PSPath -Name NetworkAddress -ErrorAction SilentlyContinue
    }

    Write-Host "Restarting adapter..." -ForegroundColor Gray
    Restart-NetAdapter -Name $nic.Name -ErrorAction Stop
    Start-Sleep -Seconds 4

    $new = (Get-NetAdapter -Name $nic.Name).MacAddress
    Write-Host ""
    if ($mac -and ($new -replace '-', '') -eq $mac) {
        Write-Host "Success! New MAC: $new" -ForegroundColor Green
    } elseif (-not $mac) {
        Write-Host "Restored. MAC is now: $new" -ForegroundColor Green
    } else {
        Write-Host "MAC is still $new. Your driver may not support changing it." -ForegroundColor Red
    }
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

Pause-Exit
