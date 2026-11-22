$ErrorActionPreference = 'Stop'
$root  = 'C:\Users\35315\ttb-publish'
$media = Join-Path $root 'media'
$voice = Join-Path $media 'voice'
$work  = Join-Path $env:TEMP 'ttb_audio3'
New-Item -ItemType Directory -Force -Path $work | Out-Null

# ---------------------------------------------------------------- 1. bed
# clean low bed + airy shimmer, breathing LFO, soft space
$bgm = Join-Path $work 'bgm.wav'
& ffmpeg -y -v error `
  -f lavfi -i "sine=f=55:d=106" `
  -f lavfi -i "sine=f=82.41:d=106" `
  -f lavfi -i "sine=f=110:d=106" `
  -f lavfi -i "anoisesrc=d=106:c=pink:a=0.05" `
  -filter_complex "[0:a]volume=0.45[a0];[1:a]volume=0.32[a1];[2:a]volume=0.18[a2];[3:a]highpass=f=6000,lowpass=f=12000,volume=0.09[a3];[a0][a1][a2][a3]amix=inputs=4:normalize=0,lowpass=f=1100,tremolo=f=0.12:d=0.30,aecho=0.75:0.65:130:0.22,afade=t=in:st=0:d=4,afade=t=out:st=98:d=8" `
  -ar 48000 -ac 2 $bgm
Write-Host "bed ok"

# ---------------------------------------------------------------- 2. airy transition
$air = Join-Path $work 'air.wav'
& ffmpeg -y -v error -f lavfi -i "anoisesrc=d=0.9:c=pink:a=0.5" -af `
  "bandpass=f=1100:width_type=o:w=2.4,highpass=f=280,lowpass=f=5200,volume=0.30,afade=t=in:st=0:d=0.42:curve=qsin,afade=t=out:st=0.48:d=0.42:curve=qsin,aecho=0.7:0.6:75:0.28" `
  -ar 48000 -ac 2 $air
Write-Host "air ok"

# ---------------------------------------------------------------- 3. bouncy tick (chirp down)
$tick = Join-Path $work 'tick.wav'
& ffmpeg -y -v error -f lavfi -i "aevalsrc=0.55*sin(2*PI*(1900*t-9500*t*t)):s=48000:d=0.11" -af `
  "afade=t=out:st=0.012:d=0.098:curve=exp,aecho=0.55:0.45:38:0.25" `
  -ar 48000 -ac 2 $tick
Write-Host "tick ok"

# ---------------------------------------------------------------- 4. bloop (elastic drop) - the "Q" sound
$bloop = Join-Path $work 'bloop.wav'
& ffmpeg -y -v error -f lavfi -i "aevalsrc=0.65*sin(2*PI*(540*t-620*t*t)):s=48000:d=0.34" -af `
  "lowpass=f=2600,afade=t=out:st=0.02:d=0.32:curve=exp,aecho=0.6:0.5:70:0.30" `
  -ar 48000 -ac 2 $bloop
Write-Host "bloop ok"

# ---------------------------------------------------------------- 5. pop (elastic rise)
$pop = Join-Path $work 'pop.wav'
& ffmpeg -y -v error -f lavfi -i "aevalsrc=0.6*sin(2*PI*(210*t+1300*t*t)):s=48000:d=0.20" -af `
  "lowpass=f=3800,afade=t=out:st=0.015:d=0.185:curve=exp,aecho=0.55:0.45:55:0.22" `
  -ar 48000 -ac 2 $pop
Write-Host "pop ok"

# ---------------------------------------------------------------- 6. low thump
$thump = Join-Path $work 'thump.wav'
& ffmpeg -y -v error -f lavfi -i "sine=f=64:d=0.45" -af `
  "volume=0.8,lowpass=f=150,afade=t=out:st=0.015:d=0.43:curve=exp" `
  -ar 48000 -ac 2 $thump
Write-Host "thump ok"

# ---------------------------------------------------------------- timeline
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
$airAt   = @(4.05, 19.25, 36.85, 52.75, 77.95, 86.15, 92.95)
$tickAt  = @(78.60, 79.60)
$bloopAt = @(53.35, 54.50, 55.70, 56.85, 90.40)
$popAt   = @(0.35)
$thumpAt = @(0.35, 93.20)

# ---------------------------------------------------------------- graph
$videoIn = Join-Path $media '_video-src.mp4'
$args = @('-y','-v','error','-i', $videoIn, '-i',$bgm,'-i',$air,'-i',$tick,'-i',$bloop,'-i',$pop,'-i',$thump)
$filter = @()
$idx = 7
foreach ($v in $voiceStarts) {
    $args += @('-i', (Join-Path $voice $v.f))
    $ms = [int]($v.t * 1000)
    $filter += ("[{0}:a]aresample=48000,aformat=sample_fmts=fltp:channel_layouts=stereo,adelay={1}|{1}[v{0}]" -f $idx, $ms)
    $idx++
}
$nVoice = $idx - 1

function Add-Instances([int]$inputIndex, [double[]]$times, [double]$vol, [string]$tag) {
    if ($times.Count -eq 0) { return @() }
    $script:filter += ("[{0}:a]asplit={1}" -f $inputIndex, $times.Count) + (($times | ForEach-Object -Begin { $k = 0 } -Process { "[${tag}s$k]"; $k++ }) -join '')
    $outs = @()
    $k = 0
    foreach ($t in $times) {
        $ms = [int]($t * 1000)
        $script:filter += ("[${tag}s{0}]adelay={1}|{1},volume={2}[{3}{0}]" -f $k, $ms, $vol, $tag)
        $outs += "[$tag$k]"
        $k++
    }
    return $outs
}

$airOuts   = Add-Instances 2 $airAt   0.95 'a'
$tickOuts  = Add-Instances 3 $tickAt  0.36 't'
$bloopOuts = Add-Instances 4 $bloopAt 0.60 'b'
$popOuts   = Add-Instances 5 $popAt   0.55 'p'
$thumpOuts = Add-Instances 6 $thumpAt 0.32 'h'

$voiceStreams = (0..($nVoice - 7) | ForEach-Object { "[v$($_ + 7)]" }) -join ''
$filter += "[1:a]volume=0.12[bg]"

$mix = "[bg]" + $voiceStreams + ($airOuts -join '') + ($tickOuts -join '') + ($bloopOuts -join '') + ($popOuts -join '') + ($thumpOuts -join '')
$nInputs = 1 + ($nVoice - 6) + $airAt.Count + $tickAt.Count + $bloopAt.Count + $popAt.Count + $thumpAt.Count
$filter += ($mix + ("amix=inputs={0}:normalize=0:duration=longest,loudnorm=I=-16:TP=-1.5:LRA=11[aout]" -f $nInputs))

$graph = $filter -join ';'
[System.IO.File]::WriteAllText((Join-Path $work 'filter.txt'), $graph, (New-Object System.Text.UTF8Encoding($false)))

$out = Join-Path $media 'ttb-26300-fix.mp4'
$args += @('-filter_complex', $graph, '-map','0:v','-map','[aout]','-c:v','copy',
    '-c:a','aac','-b:a','192k','-ar','48000','-map_metadata','-1','-map_chapters','-1',
    '-fflags','+bitexact','-flags','+bitexact','-metadata','encoder=',
    '-movflags','+faststart','-shortest', $out)

Write-Host "mixing ..."
& ffmpeg @args
if ($LASTEXITCODE -ne 0) { throw "ffmpeg failed: $LASTEXITCODE" }
Write-Host "output: $out"
& ffprobe -v error -show_entries format=duration,size:stream=codec_name -of default=noprint_wrappers=1 $out
