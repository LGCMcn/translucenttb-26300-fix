$ErrorActionPreference = 'Stop'
$root = 'C:\Users\35315\ttb-publish'
$media = Join-Path $root 'media'
$voice = Join-Path $media 'voice'
$work  = Join-Path $env:TEMP 'ttb_audio'
New-Item -ItemType Directory -Force -Path $work | Out-Null

# ---- 1. background bed (low, warm, no drums) --------------------------------
$bgm = Join-Path $work 'bgm.wav'
& ffmpeg -y -v error -f lavfi -i "sine=f=110:d=106" -f lavfi -i "sine=f=164.81:d=106" `
    -f lavfi -i "sine=f=220:d=106" -filter_complex `
    "[0:a][1:a][2:a]amix=inputs=3:normalize=1,lowpass=f=700,tremolo=f=0.12:d=0.35,volume=0.5,afade=t=in:st=0:d=3,afade=t=out:st=99:d=6" `
    -ar 44100 -ac 2 $bgm
Write-Host "bgm ok"

# ---- 2. transitions swoosh --------------------------------------------------
$whoosh = Join-Path $work 'whoosh.wav'
& ffmpeg -y -v error -f lavfi -i "anoisesrc=d=0.7:c=pink:a=0.7" -af "highpass=f=350,lowpass=f=5000,afade=t=in:st=0:d=0.12,afade=t=out:st=0.30:d=0.40,volume=0.55" -ar 44100 -ac 2 $whoosh
Write-Host "whoosh ok"

# ---- 3. ui click ------------------------------------------------------------
$click = Join-Path $work 'click.wav'
& ffmpeg -y -v error -f lavfi -i "anoisesrc=d=0.05:c=white:a=0.9" -af "highpass=f=1500,lowpass=f=6000,afade=t=out:st=0.01:d=0.04,volume=0.5" -ar 44100 -ac 2 $click
Write-Host "click ok"

# ---- 4. timeline ------------------------------------------------------------
$voiceStarts = @(
    @{ f = 's1.mp3'; t = 0.60 },
    @{ f = 's2.mp3'; t = 4.60 },
    @{ f = 's3.mp3'; t = 19.80 },
    @{ f = 's4.mp3'; t = 37.40 },
    @{ f = 's5.mp3'; t = 53.30 },
    @{ f = 's6.mp3'; t = 78.50 },
    @{ f = 's7.mp3'; t = 86.70 },
    @{ f = 's8.mp3'; t = 93.60 }
)
$whooshAt = @(4.15, 19.35, 36.95, 52.85, 78.05, 86.25, 93.05)
$clickAt  = @(53.40, 61.90, 70.40, 78.55, 80.30)

# ---- 5. build ffmpeg command ------------------------------------------------
$args = @('-y','-v','error','-i', (Join-Path $media 'video-silent.mp4'), '-i', $bgm, '-i', $whoosh, '-i', $click)
$filter = @()
$idx = 4
foreach ($v in $voiceStarts) {
    $args += @('-i', (Join-Path $voice $v.f))
    $ms = [int]($v.t * 1000)
    $filter += ("[{0}:a]aresample=48000,aformat=sample_fmts=fltp:channel_layouts=stereo,adelay={1}|{1}[v{0}]" -f $idx, $ms)
    $idx++
}
$nVoice = $idx - 1

# whoosh instances
$whooshStreams = @()
$filter += "[2:a]asplit=$($whooshAt.Count)" + (($whooshAt | ForEach-Object -Begin { $i = 0 } -Process { "[w$i]"; $i++ }) -join '')
$i = 0
foreach ($t in $whooshAt) {
    $ms = [int]($t * 1000)
    $filter += ("[w{0}]adelay={1}|{1},volume=0.32[wo{0}]" -f $i, $ms)
    $whooshStreams += "[wo$i]"
    $i++
}
# click instances
$filter += "[3:a]asplit=$($clickAt.Count)" + (($clickAt | ForEach-Object -Begin { $j = 0 } -Process { "[c$j]"; $j++ }) -join '')
$j = 0
$clickStreams = @()
foreach ($t in $clickAt) {
    $ms = [int]($t * 1000)
    $filter += ("[c{0}]adelay={1}|{1},volume=0.28[ck{0}]" -f $j, $ms)
    $clickStreams += "[ck$j]"
    $j++
}

$voiceStreams = (0..($nVoice - 4) | ForEach-Object { "[v$($_ + 4)]" }) -join ''
$filter += "[1:a]volume=0.16[bg]"
$mixInputs = "[bg]" + $voiceStreams + ($whooshStreams -join '') + ($clickStreams -join '')
$nInputs = 1 + ($nVoice - 3) + $whooshAt.Count + $clickAt.Count
$filter += ($mixInputs + ("amix=inputs={0}:normalize=0:duration=longest,loudnorm=I=-16:TP=-1.5:LRA=11[aout]" -f $nInputs))

$filterFile = Join-Path $work 'filter.txt'
$graph = $filter -join ';'
[System.IO.File]::WriteAllText($filterFile, $graph, (New-Object System.Text.UTF8Encoding($false)))

$out = Join-Path $media 'ttb-26300-fix.mp4'
$args += @('-filter_complex', $graph, '-map','0:v','-map','[aout]','-c:v','copy',
    '-c:a','aac','-b:a','192k','-ar','48000','-map_metadata','-1','-map_chapters','-1',
    '-fflags','+bitexact','-flags','+bitexact','-metadata','encoder=',
    '-movflags','+faststart','-shortest', $out)

Write-Host "mixing ..."
& ffmpeg @args
if ($LASTEXITCODE -ne 0) { throw "ffmpeg failed: $LASTEXITCODE" }
Write-Host "output: $out"

& ffprobe -v error -show_entries format=duration,size:stream=codec_name,width,height,r_frame_rate -of default=noprint_wrappers=1 $out
