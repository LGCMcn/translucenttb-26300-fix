<#
    Post-reboot verification for the TranslucentTB fix.

    Checks that the shell came back, that TranslucentTB runs, and runs the paint self-test
    (Test-TaskbarAccent.ps1) to prove the taskbar is actually driven again.

    Result is written to: <Desktop>\TBTB-verification.txt   (and printed to stdout)

    Usually started by the one-shot logon task "TBTB-PostReboot-Verify" registered by
    Fix-RollbackUpdate.ps1; that task removes itself after this script finishes.
#>
[CmdletBinding()]
param(
    [int]$WaitSeconds = 60,
    [switch]$SkipWait
)

$ErrorActionPreference = 'Continue'

$base = $PSScriptRoot
if (-not $base) { $base = Split-Path -Parent $MyInvocation.MyCommand.Definition }

$desktop = [Environment]::GetFolderPath('Desktop')
if (-not $desktop) { $desktop = Join-Path $env:USERPROFILE 'Desktop' }
$outFile = Join-Path $desktop 'TBTB-verification.txt'

$sb = New-Object System.Text.StringBuilder
function Log($t) {
    [void]$sb.AppendLine([string]$t)
    Write-Host $t
}

try {
    if (-not $SkipWait) { Start-Sleep -Seconds $WaitSeconds }

    $os  = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
    $pkg = Get-AppxPackage -Name '28017CharlesMilette.TranslucentTB' | Select-Object -First 1

    Log "===== TranslucentTB fix verification  $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ====="
    Log ("OS            : {0} {1}  build {2}.{3}" -f $os.ProductName, $os.DisplayVersion, $os.CurrentBuild, $os.UBR)
    if ($pkg) { Log ("TranslucentTB : {0}" -f $pkg.Version) } else { Log "TranslucentTB : NOT INSTALLED" }

    if ($pkg -and -not (Get-Process TranslucentTB -ErrorAction SilentlyContinue)) {
        Start-Process 'explorer.exe' -ArgumentList ("shell:AppsFolder\{0}!TranslucentTB" -f $pkg.PackageFullName)
        Start-Sleep -Seconds 6
    }
    $p = Get-Process TranslucentTB -ErrorAction SilentlyContinue
    Log ("process       : {0}" -f ($(if ($p) { "running (PID $($p.Id -join ','))" } else { "NOT running" })))

    Log ""
    Log "--- paint self-test: is TranslucentTB applying taskbar appearance? ---"
    $tester = Join-Path $base 'Test-TaskbarAccent.ps1'
    if (Test-Path $tester) {
        $res = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $tester 2>&1 | Out-String
        $code = $LASTEXITCODE
        Log $res.Trim()
        Log ("exit code     : {0}" -f $code)
        Log ""
        if ($code -eq 0) { Log "VERDICT: FIXED - TranslucentTB drives the taskbar again." }
        else { Log "VERDICT: STILL BROKEN - report upstream with this file and the TempState logs." }
    }
    else {
        Log "Test-TaskbarAccent.ps1 not found next to this script; state recorded only."
    }
}
catch {
    Log ("verification script error: {0}" -f $_.Exception.Message)
}
finally {
    try {
        $sb.ToString() | Set-Content -Path $outFile -Encoding UTF8 -Force
        Write-Host ("result written to: {0}" -f $outFile)
    }
    catch { Write-Host ("could not write result file: {0}" -f $_.Exception.Message) }

    try { Unregister-ScheduledTask -TaskName 'TBTB-PostReboot-Verify' -Confirm:$false -ErrorAction SilentlyContinue } catch { }
}
