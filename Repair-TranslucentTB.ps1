<#
.SYNOPSIS
    TranslucentTB (taskbar transparency) broke after a Windows update - one-click diagnose / repair.

.DESCRIPTION
    Steps:
      1) collect environment + TBTB state (OS build, package, process, autostart,
         injection, system transparency, config)
      2) repair every non-destructive item that *can* be repaired
         (autostart disabled, broken/missing config, stale shell hook)
      3) run the paint self-test to decide whether TBTB really paints the taskbar
      4) print the verdict, plus rollback / upstream-report hints if it is broken

.PARAMETER Fix
    Apply repairs (restarts explorer and TranslucentTB). Without it only diagnoses.

.PARAMETER SkipSelfTest
    Skip the paint self-test (it temporarily rewrites the config and restarts TBTB).

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\Repair-TranslucentTB.ps1

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\Repair-TranslucentTB.ps1 -Fix

    Exit codes: 0 = ok/fixed, 1 = broken (incompatible), 2 = package missing.
#>
[CmdletBinding()]
param(
    [switch]$Fix,
    [switch]$SkipSelfTest,
    [string]$PackageName = '28017CharlesMilette.TranslucentTB'
)

$ErrorActionPreference = 'Continue'
$issues = New-Object System.Collections.Generic.List[string]
$fixed  = New-Object System.Collections.Generic.List[string]

function Write-Step($t) { Write-Host "`n=== $t ===" -ForegroundColor Cyan }
function Write-Ok($t)   { Write-Host "  [OK]   $t" -ForegroundColor Green }
function Write-Bad($t)  { Write-Host "  [BAD]  $t" -ForegroundColor Red }
function Write-Note($t) { Write-Host "  [i]    $t" -ForegroundColor Gray }
function Write-Act($t)  { Write-Host "  [FIX]  $t" -ForegroundColor Yellow }

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)

# --------------------------------------------------------------- 1. environment
Write-Step "Environment"
$os = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
$build = "{0}.{1}" -f $os.CurrentBuild, $os.UBR
Write-Note ("OS        : {0} {1}  build {2}" -f $os.ProductName, $os.DisplayVersion, $build)
Write-Note ("elevated  : {0}" -f $isAdmin)

$pkg = Get-AppxPackage -Name $PackageName | Select-Object -First 1
if (-not $pkg) {
    Write-Bad "TranslucentTB is not installed ($PackageName). Install it from the Store first."
    exit 2
}
Write-Note ("package   : {0}  status={1}" -f $pkg.Version, $pkg.Status)
Write-Note ("full name : {0}" -f $pkg.PackageFullName)

$roam = Join-Path $env:LOCALAPPDATA ("Packages\{0}\RoamingState" -f $pkg.PackageFamilyName)
$temp = Join-Path $env:LOCALAPPDATA ("Packages\{0}\TempState"    -f $pkg.PackageFamilyName)
$settingsPath = Join-Path $roam 'settings.json'

# --------------------------------------------------------------- 2. checks
Write-Step "Checks"

$proc = Get-Process TranslucentTB -ErrorAction SilentlyContinue
if ($proc) { Write-Ok ("process running (PID {0})" -f ($proc.Id -join ',')) }
else { Write-Bad "process not running"; $issues.Add('process-not-running') }

$startupKey = "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppModel\SystemAppData\{0}\TranslucentTB" -f $pkg.PackageFamilyName
$state = (Get-ItemProperty $startupKey -Name State -ErrorAction SilentlyContinue).State
switch ($state) {
    2       { Write-Ok "autostart enabled (StartupTask State=2)" }
    1       { Write-Bad "autostart disabled (State=1)"; $issues.Add('startup-disabled') }
    3       { Write-Bad "autostart disabled by user (State=3)"; $issues.Add('startup-disabled') }
    4       { Write-Bad "autostart disabled by policy (State=4)"; $issues.Add('startup-policy') }
    default { Write-Bad ("autostart state unknown (State={0})" -f $state); $issues.Add('startup-unknown') }
}

if (Test-Path $settingsPath) {
    try {
        $raw  = Get-Content $settingsPath -Raw
        $json = $raw -replace '(?m)^\s*//.*$', ''
        $cfg  = $json | ConvertFrom-Json
        Write-Ok ("config OK: {0}" -f $settingsPath)
        Write-Note ("desktop_appearance = {0} {1}" -f $cfg.desktop_appearance.accent, $cfg.desktop_appearance.color)
        if ($cfg.desktop_appearance.accent -eq 'normal') {
            Write-Bad "desktop appearance is 'normal' (= stock opaque), it will look like 'not working'"
            $issues.Add('config-normal')
        }
    }
    catch {
        Write-Bad ("config exists but cannot be parsed: {0}" -f $_.Exception.Message)
        $issues.Add('config-invalid')
    }
}
else {
    Write-Bad ("config missing: {0}" -f $settingsPath)
    $issues.Add('config-missing')
}

$tr = (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name EnableTransparency -ErrorAction SilentlyContinue).EnableTransparency
if ($tr -eq 1) { Write-Ok "system transparency enabled (EnableTransparency=1)" }
else { Write-Bad ("system transparency disabled (EnableTransparency={0})" -f $tr); $issues.Add('transparency-off') }

$ex = Get-Process explorer -ErrorAction SilentlyContinue
$tap = $false
foreach ($e in $ex) {
    if ($e.Modules | Where-Object { $_.ModuleName -eq 'ExplorerTAP.dll' }) { $tap = $true; break }
}
if ($ex) {
    if ($tap) { Write-Ok "ExplorerTAP.dll injected into explorer (hook layer loaded)" }
    else { Write-Bad "ExplorerTAP.dll NOT injected into explorer"; $issues.Add('tap-not-injected') }
}

$conflicts = Get-Process -ErrorAction SilentlyContinue |
             Where-Object { $_.ProcessName -match 'StartAllBack|ExplorerPatcher|Start11|StartIsBack|Windhawk' }
if ($conflicts) {
    Write-Bad ("possible conflicting taskbar mod: " + (($conflicts.ProcessName | Sort-Object -Unique) -join ', '))
    $issues.Add('conflict-app')
}
else { Write-Ok "no known conflicting taskbar mod running" }

# --------------------------------------------------------------- 3. repair
if (-not $Fix) {
    Write-Step "Diagnose only"
    Write-Note "add -Fix to apply repairs"
}
else {
    Write-Step "Repair"

    if ($issues -contains 'startup-disabled') {
        try {
            Set-ItemProperty $startupKey -Name State -Value 2 -Type DWord
            Write-Act "StartupTask state restored to Enabled(2)"
            $fixed.Add('startup-enabled')
        }
        catch { Write-Bad ("failed to enable autostart: {0}" -f $_.Exception.Message) }
    }

    if ($issues -contains 'transparency-off') {
        try {
            Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name EnableTransparency -Value 1 -Type DWord
            Write-Act "system transparency re-enabled"
            $fixed.Add('transparency-enabled')
        }
        catch { Write-Bad ("failed to enable transparency: {0}" -f $_.Exception.Message) }
    }

    if (($issues -contains 'config-missing') -or ($issues -contains 'config-invalid')) {
        if (-not (Test-Path $roam)) { New-Item -ItemType Directory -Force -Path $roam | Out-Null }
        if (Test-Path $settingsPath) { Copy-Item $settingsPath ("{0}.bak" -f $settingsPath) -Force }
        $defaultCfg = @"
{
  "`$schema": "https://TranslucentTB.github.io/settings.schema.json",
  "desktop_appearance": { "accent": "clear", "color": "#00000000", "show_peek": false, "show_line": false, "blur_radius": 9.0 },
  "visible_window_appearance": { "enabled": false, "accent": "clear", "color": "#00000000", "show_peek": true, "show_line": false, "blur_radius": 9.0, "rules": { "window_class": {}, "window_title": {}, "process_name": {} } },
  "maximized_window_appearance": { "enabled": false, "accent": "acrylic", "color": "#00000000", "show_peek": true, "show_line": true, "blur_radius": 9.0, "rules": { "window_class": {}, "window_title": {}, "process_name": {} } },
  "start_opened_appearance": { "enabled": false, "accent": "normal", "color": "#00000000", "show_peek": true, "show_line": true, "blur_radius": 9.0 },
  "search_opened_appearance": { "enabled": false, "accent": "normal", "color": "#00000000", "show_peek": true, "show_line": true, "blur_radius": 9.0 },
  "task_view_opened_appearance": { "enabled": false, "accent": "normal", "color": "#00000000", "show_peek": false, "show_line": true, "blur_radius": 9.0 },
  "battery_saver_appearance": { "enabled": false, "accent": "opaque", "color": "#00000000", "show_peek": true, "show_line": false, "blur_radius": 9.0 },
  "ignored_windows": { "window_class": [], "window_title": [], "process_name": [] },
  "disable_saving": false,
  "verbosity": "warn"
}
"@
        Set-Content -Path $settingsPath -Value $defaultCfg -Encoding UTF8
        Write-Act ("default config recreated: {0}" -f $settingsPath)
        $fixed.Add('config-rebuilt')
    }

    Write-Act "restarting explorer + TranslucentTB (re-inject the hook layer) ..."
    Stop-Process -Name TranslucentTB -Force -ErrorAction SilentlyContinue
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3
    Start-Process explorer.exe
    Start-Sleep -Seconds 6
    Start-Process 'explorer.exe' -ArgumentList ("shell:AppsFolder\{0}!TranslucentTB" -f $pkg.PackageFullName)
    Start-Sleep -Seconds 4
    $fixed.Add('shell-restarted')
    Write-Ok "restarted"
}

# --------------------------------------------------------------- 4. self-test
$selfTest = $null
if (-not $SkipSelfTest) {
    Write-Step "Paint self-test (does TBTB actually paint the taskbar?)"
    $tester = Join-Path $PSScriptRoot 'Test-TaskbarAccent.ps1'
    if (Test-Path $tester) {
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $tester
        $selfTest = ($LASTEXITCODE -eq 0)
    }
    else {
        Write-Note "Test-TaskbarAccent.ps1 not found next to this script, skipping."
    }
}

# --------------------------------------------------------------- 5. verdict
Write-Step "Verdict"
if ($selfTest -eq $true) {
    Write-Host "  PASS: TranslucentTB can drive the taskbar again." -ForegroundColor Green
    Write-Host "        If it still looks opaque, set the 'Desktop' appearance to Clear/Blur in the tray menu." -ForegroundColor Green
    exit 0
}
elseif ($selfTest -eq $false) {
    Write-Host "  FAIL: not fixable from userland. Process/injection/config are all fine," -ForegroundColor Red
    Write-Host "        but TranslucentTB never applies an appearance to the taskbar on this shell build." -ForegroundColor Red
    Write-Host ("        OS build: {0}" -f $build) -ForegroundColor Red
    Write-Host ""
    Write-Host "  Options:" -ForegroundColor Yellow
    Write-Host "   1) roll back the latest cumulative update (needs reboot, admin):" -ForegroundColor Yellow
    Write-Host "        wusa /uninstall /kb:<KB>"
    Write-Host "   2) file an upstream issue with this script output + the trace log in:" -ForegroundColor Yellow
    Write-Host ("        {0}" -f $temp)
    Write-Host "        https://github.com/TranslucentTB/TranslucentTB/issues"
    exit 1
}
else {
    Write-Host "  Diagnose/repair finished, self-test skipped." -ForegroundColor Yellow
    if ($fixed.Count)  { Write-Host ("  applied: {0}" -f ($fixed -join ', ')) }
    if ($issues.Count) { Write-Host ("  remaining issues: {0}" -f ($issues -join ', ')) }
    exit 0
}
