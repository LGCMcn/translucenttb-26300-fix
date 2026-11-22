$ErrorActionPreference = 'Stop'

$key    = $env:MINIMAX_KEY
$root   = 'C:\Users\35315\ttb-publish'
$cfgPath = Join-Path $root 'video\segments.json'
$outDir  = Join-Path $root 'media\voice'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$cfg = [System.IO.File]::ReadAllText($cfgPath, [Text.Encoding]::UTF8) | ConvertFrom-Json

$results = @()

foreach ($seg in $cfg.segments) {
    $body = [ordered]@{
        model          = $cfg.model
        text           = $seg.text
        stream         = $false
        language_boost = 'Chinese'
        voice_setting  = @{ voice_id = $cfg.voice; speed = $cfg.speed; vol = 1.0; pitch = 0 }
        audio_setting  = @{ sample_rate = 32000; bitrate = 128000; format = 'mp3'; channel = 1 }
    } | ConvertTo-Json -Depth 6

    $tmpJson = Join-Path $env:TEMP ("tts_{0}.json" -f $seg.id)
    $tmpReq  = Join-Path $env:TEMP ("tts_{0}_req.json" -f $seg.id)
    [System.IO.File]::WriteAllText($tmpReq, $body, (New-Object System.Text.UTF8Encoding($false)))

    $code = curl.exe -s --max-time 180 -o $tmpJson -w "%{http_code}" -X POST 'https://api.minimaxi.com/v1/t2a_v2' `
        -H "Authorization: Bearer $key" -H 'Content-Type: application/json' --data-binary "@$tmpReq"

    $resp = [System.IO.File]::ReadAllText($tmpJson, [Text.Encoding]::UTF8) | ConvertFrom-Json
    if ($resp.base_resp.status_code -ne 0) {
        Write-Host ("[{0}] FAIL http={1} status={2} msg={3}" -f $seg.id, $code, $resp.base_resp.status_code, $resp.base_resp.status_msg)
        continue
    }

    $hex   = $resp.data.audio
    $bytes = New-Object byte[] ($hex.Length / 2)
    for ($i = 0; $i -lt $bytes.Length; $i++) {
        $bytes[$i] = [Convert]::ToByte($hex.Substring($i * 2, 2), 16)
    }
    $mp3 = Join-Path $outDir ("{0}.mp3" -f $seg.id)
    [System.IO.File]::WriteAllBytes($mp3, $bytes)

    $dur = 0.0
    $probe = & ffprobe -v error -show_entries format=duration -of csv=p=0 $mp3
    if ($probe) { $dur = [double]$probe }

    Write-Host ("[{0}] ok  start={1}s  dur={2:N2}s" -f $seg.id, $seg.start, $dur)
    $results += [pscustomobject]@{ id = $seg.id; start = $seg.start; dur = [math]::Round($dur, 2) }
}

$results | ConvertTo-Json -Depth 4 | Set-Content (Join-Path $root 'media\voice\durations.json') -Encoding UTF8
Write-Host "`n--- summary ---"
$results | Format-Table -AutoSize
