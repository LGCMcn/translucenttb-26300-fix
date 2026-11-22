<#
.SYNOPSIS
    Self-test: does TranslucentTB ACTUALLY paint the taskbar?

.DESCRIPTION
    Method:
      1) capture taskbar pixel average (baseline)
      2) temporarily write a screaming-magenta opaque config, restart TBTB
      3) capture again and compare
         - taskbar color changed  => TBTB pipeline works (PASS)
         - taskbar color unchanged => TBTB never applies anything (FAIL)
      4) always restore the original config and restart TBTB

    Exit codes: 0 = PASS, 1 = FAIL, 2 = script error.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\Test-TaskbarAccent.ps1
#>
[CmdletBinding()]
param(
    [string]$PackageName = '28017CharlesMilette.TranslucentTB',
    [int]$SettleMs = 4500
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing, System.Windows.Forms

function Get-TbtbInfo {
    $pkg = Get-AppxPackage -Name $PackageName | Select-Object -First 1
    if (-not $pkg) { throw "TranslucentTB package not found: $PackageName" }
    $roam = Join-Path $env:LOCALAPPDATA ("Packages\{0}\RoamingState" -f $pkg.PackageFamilyName)
    $temp = Join-Path $env:LOCALAPPDATA ("Packages\{0}\TempState"    -f $pkg.PackageFamilyName)
    if (-not (Test-Path $roam)) { New-Item -ItemType Directory -Force -Path $roam | Out-Null }
    [pscustomobject]@{
        Full      = $pkg.PackageFullName
        Family    = $pkg.PackageFamilyName
        Settings  = Join-Path $roam 'settings.json'
        TempState = $temp
    }
}

function Get-TaskbarPixel {
    param([int]$YOffset = 30, [int]$XFrom = 120, [int]$XTo = 760)
    $vs = [System.Windows.Forms.SystemInformation]::VirtualScreen
    $bmp = New-Object System.Drawing.Bitmap $vs.Width, $vs.Height
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen($vs.X, $vs.Y, 0, 0, $bmp.Size)
    $y = $vs.Height - $YOffset
    $r = 0; $gg = 0; $bb = 0; $n = 0
    for ($x = $XFrom; $x -lt $XTo; $x += 7) {
        $px = $bmp.GetPixel($x, $y)
        $r += $px.R; $gg += $px.G; $bb += $px.B; $n++
    }
    $g.Dispose(); $bmp.Dispose()
    [pscustomobject]@{ R = [int]($r / $n); G = [int]($gg / $n); B = [int]($bb / $n) }
}

function Start-Tbtb { param($info)
    Start-Process 'explorer.exe' -ArgumentList ("shell:AppsFolder\{0}!TranslucentTB" -f $info.Full)
}

$info = Get-TbtbInfo
Write-Host "== TranslucentTB paint self-test ==" -ForegroundColor Cyan
Write-Host ("package : {0}" -f $info.Full)
Write-Host ("settings: {0}" -f $info.Settings)

$backup = $null
if (Test-Path $info.Settings) {
    $backup = Join-Path $env:TEMP ("ttb_settings_{0}.bak" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
    Copy-Item $info.Settings $backup -Force
    Write-Host ("backup  : {0}" -f $backup)
}

$magenta = @"
{
  "`$schema": "https://TranslucentTB.github.io/settings.schema.json",
  "desktop_appearance": { "accent": "opaque", "color": "#FFFF00FF", "show_peek": false, "show_line": false, "blur_radius": 9.0 },
  "visible_window_appearance": { "enabled": true, "accent": "opaque", "color": "#FFFF00FF", "show_peek": true, "show_line": false, "blur_radius": 9.0, "rules": { "window_class": {}, "window_title": {}, "process_name": {} } },
  "maximized_window_appearance": { "enabled": true, "accent": "opaque", "color": "#FFFF00FF", "show_peek": true, "show_line": false, "blur_radius": 9.0, "rules": { "window_class": {}, "window_title": {}, "process_name": {} } },
  "start_opened_appearance": { "enabled": false, "accent": "normal", "color": "#00000000", "show_peek": true, "show_line": true, "blur_radius": 9.0 },
  "search_opened_appearance": { "enabled": false, "accent": "normal", "color": "#00000000", "show_peek": true, "show_line": true, "blur_radius": 9.0 },
  "task_view_opened_appearance": { "enabled": false, "accent": "normal", "color": "#00000000", "show_peek": false, "show_line": true, "blur_radius": 9.0 },
  "battery_saver_appearance": { "enabled": false, "accent": "opaque", "color": "#00000000", "show_peek": true, "show_line": false, "blur_radius": 9.0 },
  "ignored_windows": { "window_class": [], "window_title": [], "process_name": [] },
  "disable_saving": true,
  "verbosity": "trace"
}
"@

try {
    Write-Host "`n[1/4] capture baseline ..." -ForegroundColor Yellow
    Start-Sleep -Milliseconds 400
    $before = Get-TaskbarPixel
    Write-Host ("      baseline RGB = {0},{1},{2}" -f $before.R, $before.G, $before.B)

    Write-Host "[2/4] write magenta test config and restart TBTB ..." -ForegroundColor Yellow
    Set-Content -Path $info.Settings -Value $magenta -Encoding UTF8
    Stop-Process -Name TranslucentTB -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 900
    if (Test-Path $info.TempState) {
        Get-ChildItem (Join-Path $info.TempState '*.log') -ErrorAction SilentlyContinue |
            Remove-Item -Force -ErrorAction SilentlyContinue
    }
    Start-Tbtb $info
    Start-Sleep -Milliseconds $SettleMs

    Write-Host "[3/4] capture after ..." -ForegroundColor Yellow
    $after = Get-TaskbarPixel
    Write-Host ("      test RGB     = {0},{1},{2}" -f $after.R, $after.G, $after.B)
    $delta = [math]::Abs($after.R - $before.R) + [math]::Abs($after.G - $before.G) + [math]::Abs($after.B - $before.B)
    Write-Host ("      delta        = {0}" -f $delta)

    $log = Get-ChildItem (Join-Path $info.TempState '*.log') -ErrorAction SilentlyContinue |
           Sort-Object LastWriteTime -Descending | Select-Object -First 1

    Write-Host "`n[4/4] restore config ..." -ForegroundColor Yellow
    if ($backup) { Copy-Item $backup $info.Settings -Force }
    Stop-Process -Name TranslucentTB -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 900
    Start-Tbtb $info
    Start-Sleep -Milliseconds 1500

    Write-Host ''
    if ($delta -ge 40) {
        Write-Host "RESULT: PASS - TranslucentTB is applying taskbar appearance." -ForegroundColor Green
        Write-Host "        If it still looks opaque, the problem is the appearance values / compositor, not the hook." -ForegroundColor Green
        exit 0
    }
    Write-Host "RESULT: FAIL - TranslucentTB applies NOTHING to the taskbar (even magenta is invisible)." -ForegroundColor Red
    Write-Host "        The hook chain is dead on this shell build; reinstall/reset/explorer-restart cannot fix it." -ForegroundColor Red
    if ($log) {
        Write-Host ("`n--- suspicious lines in {0} ---" -f $log.Name) -ForegroundColor DarkYellow
        Select-String -Path $log.FullName -Pattern 'failed|error|0x[0-9A-Fa-f]{8}|Unknown' |
            ForEach-Object { Write-Host $_.Line }
    }
    exit 1
}
catch {
    Write-Host ("`nself-test error: {0}" -f $_.Exception.Message) -ForegroundColor Red
    if ($backup -and (Test-Path $backup)) { Copy-Item $backup $info.Settings -Force }
    exit 2
}
finally {
    # always leave TranslucentTB running
    for ($i = 0; $i -lt 3; $i++) {
        if (Get-Process TranslucentTB -ErrorAction SilentlyContinue) { break }
        try { Start-Tbtb $info } catch { }
        Start-Sleep -Milliseconds 1500
    }
    if (-not (Get-Process TranslucentTB -ErrorAction SilentlyContinue)) {
        Write-Host "WARNING: TranslucentTB is not running - start it manually." -ForegroundColor Yellow
    }
}
