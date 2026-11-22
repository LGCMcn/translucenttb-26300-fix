<#
.SYNOPSIS
    One-click fix for "TranslucentTB (taskbar transparency) stopped working after a Windows update".

.DESCRIPTION
    Root cause found on Windows 10 Pro 26H2 / build 26300.10075 (KB5132057):
    TranslucentTB runs, injects ExplorerTAP.dll and reads its config, but never applies any
    appearance to the taskbar. The system's SetWindowCompositionAttribute channel still works,
    so it is not a transparency/compositor problem - the shell of that build simply does not
    talk to the hook layer any more.

    Fix that was verified on the machine: remove the offending cumulative update (LCU),
    reboot, and TranslucentTB paints the taskbar again.

    This script:
      1) lists installed cumulative updates (packages named Package_for_RollupFix)
      2) removes the selected one with DISM /NoRestart
      3) if a reboot is required, registers a one-shot logon task that runs the
         paint self-test after reboot and writes the result to the Desktop
      4) otherwise runs the self-test right away

.PARAMETER Latest
    Remove the newest installed cumulative update (rollup package with the highest version).

.PARAMETER PackageName
    Remove this exact package name, e.g.
    Package_for_RollupFix~31bf3856ad364e35~amd64~~26100.10075.1.25

.PARAMETER Restart
    Reboot automatically after a successful removal (default: only tell you to reboot).

.PARAMETER NoVerify
    Do not register / run the paint self-test.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\Fix-RollbackUpdate.ps1 -Latest

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\Fix-RollbackUpdate.ps1 `
        -PackageName 'Package_for_RollupFix~31bf3856ad364e35~amd64~~26100.10075.1.25' -Restart

    Exit codes: 0 = removed (no reboot needed or reboot pending), 1 = failed, 2 = usage/admin issue.
#>
[CmdletBinding(DefaultParameterSetName = 'List')]
param(
    [Parameter(ParameterSetName = 'Latest')][switch]$Latest,
    [Parameter(ParameterSetName = 'Explicit')][string]$PackageName,
    [switch]$Restart,
    [switch]$NoVerify
)

$ErrorActionPreference = 'Continue'

function Write-Step($t) { Write-Host "`n=== $t ===" -ForegroundColor Cyan }
function Write-Ok($t)   { Write-Host "  [OK]   $t" -ForegroundColor Green }
function Write-Bad($t)  { Write-Host "  [BAD]  $t" -ForegroundColor Red }
function Write-Note($t) { Write-Host "  [i]    $t" -ForegroundColor Gray }

# ---- admin check / self-elevate ------------------------------------------------
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Note "not elevated - relaunching with RunAs ..."
    $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"{0}"' -f $PSCommandPath))
    if ($Latest) { $argList += '-Latest' }
    if ($PackageName) { $argList += @('-PackageName', ('"{0}"' -f $PackageName)) }
    if ($Restart) { $argList += '-Restart' }
    if ($NoVerify) { $argList += '-NoVerify' }
    try {
        Start-Process powershell.exe -Verb RunAs -ArgumentList $argList
        exit 0
    }
    catch {
        Write-Bad "elevation refused: $($_.Exception.Message)"
        exit 2
    }
}

# ---- environment ---------------------------------------------------------------
Write-Step "Environment"
$os = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
$build = "{0}.{1}" -f $os.CurrentBuild, $os.UBR
Write-Note ("OS        : {0} {1}  build {2}" -f $os.ProductName, $os.DisplayVersion, $build)
$tbtb = Get-AppxPackage -Name '28017CharlesMilette.TranslucentTB' | Select-Object -First 1
if ($tbtb) { Write-Note ("TranslucentTB: {0}" -f $tbtb.Version) }
else { Write-Note "TranslucentTB: not installed (script still works, it only fixes the shell side)" }

# ---- list cumulative updates ---------------------------------------------------
Write-Step "Installed cumulative updates"
$dismOut = & dism.exe /Online /Get-Packages /Format:Table 2>&1 | Out-String
$rollups = @()
foreach ($line in ($dismOut -split "`r?`n")) {
    if ($line -notmatch '(Package_for_RollupFix|Package_for_KB)~[^|]+\|\s*(已安装|Installed)\s*\|') { continue }
    $name = ($line -split '\|')[0].Trim()
    if ($name -match '~~(\d+)\.(\d+)\.(\d+)') {
        $ver = [version]("{0}.{1}.{2}" -f $matches[1], $matches[2], $matches[3])
    }
    else { $ver = [version]'0.0.0' }
    $rollups += [pscustomobject]@{ Name = $name; Version = $ver }
}
$rollups = $rollups | Sort-Object Version -Descending
if (-not $rollups.Count) {
    Write-Bad "no installed rollup package found (DISM output unparsable?)"
    exit 1
}
$i = 0
foreach ($r in $rollups) {
    $i++
    Write-Host ("  [{0}] {1}   (version tag {2})" -f $i, $r.Name, $r.Version)
}

# ---- pick target ---------------------------------------------------------------
$target = $null
if ($PackageName) {
    $target = $rollups | Where-Object { $_.Name -eq $PackageName } | Select-Object -First 1
    if (-not $target) { $target = [pscustomobject]@{ Name = $PackageName; Version = [version]'0.0.0' } }
}
elseif ($Latest) {
    $target = $rollups[0]
}
else {
    Write-Step "Nothing to do"
    Write-Note "pick one:"
    Write-Note "  .\Fix-RollbackUpdate.ps1 -Latest"
    Write-Note "  .\Fix-RollbackUpdate.ps1 -PackageName '<name from the list above>'"
    exit 2
}

Write-Step ("Removing " + $target.Name)
Write-Note "this can take 10-30 minutes, do not close the window"

try {
    $rp = Checkpoint-Computer -Description 'Before TBTB LCU rollback' -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
    Write-Ok "restore point created"
}
catch { Write-Note ("restore point skipped: {0}" -f $_.Exception.Message) }

$log = Join-Path $env:TEMP 'ttb_remove_lcu.log'
$out = & dism.exe /Online /Remove-Package /PackageName:$($target.Name) /NoRestart 2>&1 | Out-String
$code = $LASTEXITCODE
$out | Set-Content $log -Encoding UTF8
$tail = ($out -split "`r?`n" | Where-Object { $_ -match '操作成功|success|错误|error' } | Select-Object -Last 3) -join ' / '
Write-Note ("dism exit code: {0}" -f $code)
if ($tail) { Write-Note $tail }
Write-Note ("full log: {0}" -f $log)

if ($code -eq 3010 -or $code -eq 0) {
    Write-Ok "cumulative update removed"
}
else {
    Write-Bad ("removal failed (exit {0}). Check the log above." -f $code)
    exit 1
}

# ---- reboot / verification -----------------------------------------------------
$pending = Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'

if ($pending) {
    Write-Step "Reboot required"
    if (-not $NoVerify) {
        $verify = Join-Path $PSScriptRoot 'Verify-AfterReboot.ps1'
        if (Test-Path $verify) {
            try {
                Unregister-ScheduledTask -TaskName 'TBTB-PostReboot-Verify' -Confirm:$false -ErrorAction SilentlyContinue
                $user = "$env:USERDOMAIN\$env:USERNAME"
                $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument ('-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "{0}"' -f $verify)
                $trigger = New-ScheduledTaskTrigger -AtLogOn -User $user
                $principal = New-ScheduledTaskPrincipal -UserId $user -LogonType Interactive -RunLevel Highest
                $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 15)
                Register-ScheduledTask -TaskName 'TBTB-PostReboot-Verify' -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
                Write-Ok "post-reboot verification registered (result -> Desktop\TBTB-验证结果.txt)"
            }
            catch { Write-Note ("could not register verification: {0}" -f $_.Exception.Message) }
        }
    }
    if ($Restart) {
        Write-Note "rebooting in 60 seconds (cancel with: shutdown /a)"
        shutdown.exe /r /t 60 /c "Rebooting to finish the taskbar transparency fix"
    }
    else {
        Write-Host "`n  >>> REBOOT to finish:  Restart-Computer" -ForegroundColor Yellow
    }
    exit 0
}

Write-Step "Verifying (no reboot needed)"
if (-not $NoVerify) {
    $tester = Join-Path $PSScriptRoot 'Test-TaskbarAccent.ps1'
    if (Test-Path $tester) {
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $tester
        exit $LASTEXITCODE
    }
}
Write-Note "removed; start TranslucentTB and check the taskbar"
exit 0
