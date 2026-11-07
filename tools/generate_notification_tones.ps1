# Generates short, distinct alarm tones as 22.05 kHz mono 16-bit WAV files
# bundled by Flutter from assets/sounds/.

$ErrorActionPreference = 'Stop'
$sampleRate = 22050
$outDir = Join-Path $PSScriptRoot '..\assets\sounds'

if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

function New-Wav {
    param(
        [string]$Name,
        [scriptblock]$Render,
        [double]$Seconds
    )
    $total = [int]($sampleRate * $Seconds)
    $samples = New-Object 'double[]' $total
    & $Render $samples $total $sampleRate

    $path = Join-Path $outDir "$Name.wav"
    $stream = [System.IO.File]::Create($path)
    $writer = New-Object System.IO.BinaryWriter($stream)
    $dataBytes = $total * 2

    # RIFF header
    $writer.Write([char[]]'RIFF')
    $writer.Write([int](36 + $dataBytes))
    $writer.Write([char[]]'WAVE')
    $writer.Write([char[]]'fmt ')
    $writer.Write([int]16)
    $writer.Write([int16]1)            # PCM
    $writer.Write([int16]1)            # mono
    $writer.Write([int]$sampleRate)
    $writer.Write([int]($sampleRate * 2))
    $writer.Write([int16]2)
    $writer.Write([int16]16)
    $writer.Write([char[]]'data')
    $writer.Write([int]$dataBytes)

    foreach ($s in $samples) {
        $v = [Math]::Max(-1.0, [Math]::Min(1.0, $s))
        $writer.Write([int16]($v * 32767))
    }
    $writer.Flush()
    $writer.Close()
    Write-Output "  $Name.wav  ($([Math]::Round($Seconds,2))s)"
}

# Soft two-note chime (C6 -> G6), gentle sine attack/decay, bell-ish 2nd partial.
New-Wav -Name 'chime' -Seconds 1.1 -Render {
    param($s, $n, $sr)
    $notes = @(1046.5, 1568.0)
    $noteLen = 0.5
    for ($i = 0; $i -lt $n; $i++) {
        $t = $i / $sr
        $idx = [Math]::Min(1, [int]($t / $noteLen))
        $lt = $t - ($idx * $noteLen)
        $env = [Math]::Exp(-4.5 * $lt)
        $attack = [Math]::Min(1.0, $lt / 0.006)
        $f = $notes[$idx]
        $v = ([Math]::Sin(2 * [Math]::PI * $f * $lt) * 0.62) +
             ([Math]::Sin(2 * [Math]::PI * $f * 2.0 * $lt) * 0.22) +
             ([Math]::Sin(2 * [Math]::PI * $f * 3.01 * $lt) * 0.10)
        $s[$i] = $v * $env * $attack * 0.85
    }
}

# Bright bell — inharmonic partials with fast attack.
New-Wav -Name 'bell' -Seconds 1.0 -Render {
    param($s, $n, $sr)
    $f = 880.0
    for ($i = 0; $i -lt $n; $i++) {
        $t = $i / $sr
        $env = [Math]::Exp(-3.2 * $t)
        $attack = [Math]::Min(1.0, $t / 0.002)
        $v = ([Math]::Sin(2 * [Math]::PI * $f * $t) * 0.55) +
             ([Math]::Sin(2 * [Math]::PI * $f * 2.76 * $t) * 0.25) +
             ([Math]::Sin(2 * [Math]::PI * $f * 5.40 * $t) * 0.14)
        $s[$i] = $v * $env * $attack * 0.8
    }
}

# Church bells — three staggered strikes on a lower note with long decay.
New-Wav -Name 'bells' -Seconds 2.4 -Render {
    param($s, $n, $sr)
    $f = 587.3
    $strikes = @(0.0, 0.75, 1.5)
    for ($i = 0; $i -lt $n; $i++) {
        $t = $i / $sr
        $v = 0.0
        foreach ($st in $strikes) {
            $lt = $t - $st
            if ($lt -lt 0) { continue }
            $env = [Math]::Exp(-4.0 * $lt)
            $attack = [Math]::Min(1.0, $lt / 0.003)
            $v += (([Math]::Sin(2 * [Math]::PI * $f * $lt) * 0.5) +
                   ([Math]::Sin(2 * [Math]::PI * $f * 2.0 * $lt) * 0.22) +
                   ([Math]::Sin(2 * [Math]::PI * $f * 3.0 * $lt) * 0.12) +
                   ([Math]::Sin(2 * [Math]::PI * $f * 4.2 * $lt) * 0.07)) * $env * $attack
        }
        $s[$i] = [Math]::Max(-1.0, [Math]::Min(1.0, $v)) * 0.7
    }
}

# Digital beep — two short square-ish pips.
New-Wav -Name 'beep' -Seconds 0.55 -Render {
    param($s, $n, $sr)
    $f = 1318.5
    for ($i = 0; $i -lt $n; $i++) {
        $t = $i / $sr
        $on = (($t -lt 0.16) -or ($t -ge 0.30 -and $t -lt 0.46))
        if (-not $on) { $s[$i] = 0.0; continue }
        $phase = [Math]::Sin(2 * [Math]::PI * $f * $t)
        $sq = [Math]::Sign($phase) * 0.35 + $phase * 0.65
        $edge = [Math]::Min(1.0, [Math]::Min($t % 0.30, 0.16 - ($t % 0.30)) / 0.01)
        $s[$i] = $sq * 0.45 * [Math]::Max(0.0, [Math]::Min(1.0, $edge))
    }
}

# Marimba — warm wooden ascending run.
New-Wav -Name 'marimba' -Seconds 1.2 -Render {
    param($s, $n, $sr)
    $notes = @(523.3, 659.3, 784.0, 1046.5)
    $step = 0.22
    for ($i = 0; $i -lt $n; $i++) {
        $t = $i / $sr
        $v = 0.0
        for ($k = 0; $k -lt $notes.Count; $k++) {
            $lt = $t - ($k * $step)
            if ($lt -lt 0) { continue }
            $env = [Math]::Exp(-7.0 * $lt)
            $attack = [Math]::Min(1.0, $lt / 0.004)
            $v += ([Math]::Sin(2 * [Math]::PI * $notes[$k] * $lt) * 0.6) +
                  ([Math]::Sin(2 * [Math]::PI * $notes[$k] * 3.9 * $lt) * 0.3) 
            $v *= $env * $attack
        }
        $s[$i] = [Math]::Max(-1.0, [Math]::Min(1.0, $v)) * 0.55
    }
}

# Harp — soft plucked arpeggio with shimmer.
New-Wav -Name 'harp' -Seconds 1.6 -Render {
    param($s, $n, $sr)
    $notes = @(523.3, 659.3, 784.0, 1046.5, 1318.5)
    $step = 0.14
    for ($i = 0; $i -lt $n; $i++) {
        $t = $i / $sr
        $v = 0.0
        for ($k = 0; $k -lt $notes.Count; $k++) {
            $lt = $t - ($k * $step)
            if ($lt -lt 0) { continue }
            $env = [Math]::Exp(-4.5 * $lt) * [Math]::Min(1.0, $lt / 0.005)
            $v += ([Math]::Sin(2 * [Math]::PI * $notes[$k] * $lt) * 0.55) +
                  ([Math]::Sin(2 * [Math]::PI * $notes[$k] * 2.0 * $lt) * 0.18) +
                  ([Math]::Sin(2 * [Math]::PI * $notes[$k] * 4.0 * $lt) * 0.08)
            $v *= $env
        }
        $s[$i] = [Math]::Max(-1.0, [Math]::Min(1.0, $v)) * 0.5
    }
}

# Drum — two low, punchy hits.
New-Wav -Name 'drum' -Seconds 0.9 -Render {
    param($s, $n, $sr)
    foreach ($i in 0..($n - 1)) {
        $t = $i / $sr
        $v = 0.0
        foreach ($hit in @(0.0, 0.42)) {
            $lt = $t - $hit
            if ($lt -lt 0) { continue }
            $env = [Math]::Exp(-9.0 * $lt)
            $freq = 110.0 + (90.0 * [Math]::Exp(-22.0 * $lt))
            $v += [Math]::Sin(2 * [Math]::PI * $freq * $lt) * $env
        }
        $s[$i] = [Math]::Max(-1.0, [Math]::Min(1.0, $v)) * 0.8
    }
}

# Birds — quick whistled chirps with pitch bends.
New-Wav -Name 'birds' -Seconds 1.4 -Render {
    param($s, $n, $sr)
    $chirps = @(
        @(0.10, 0.16, 2400.0, 3400.0),
        @(0.33, 0.14, 2800.0, 2200.0),
        @(0.55, 0.18, 2500.0, 3600.0),
        @(0.85, 0.15, 3100.0, 2500.0),
        @(1.05, 0.16, 2600.0, 3300.0)
    )
    $phase = 0.0
    for ($i = 0; $i -lt $n; $i++) {
        $t = $i / $sr
        $v = 0.0
        foreach ($c in $chirps) {
            $start = $c[0]; $dur = $c[1]; $f0 = $c[2]; $f1 = $c[3]
            $lt = $t - $start
            if ($lt -lt 0 -or $lt -gt $dur) { continue }
            $p = $lt / $dur
            $f = $f0 + (($f1 - $f0) * $p)
            $env = [Math]::Sin([Math]::PI * $p)
            $v += [Math]::Sin(2 * [Math]::PI * $f * $lt) * $env
        }
        $s[$i] = [Math]::Max(-1.0, [Math]::Min(1.0, $v)) * 0.35
    }
}

# Hallelujah — triumphant rising fanfare on a major triad.
New-Wav -Name 'hallelujah' -Seconds 1.8 -Render {
    param($s, $n, $sr)
    $chord = @(523.3, 659.3, 784.0, 1046.5)
    for ($i = 0; $i -lt $n; $i++) {
        $t = $i / $sr
        $v = 0.0
        foreach ($idx in 0..($chord.Count - 1)) {
            $start = $idx * 0.12
            $lt = $t - $start
            if ($lt -lt 0) { continue }
            $env = [Math]::Exp(-1.4 * $lt) * [Math]::Min(1.0, $lt / 0.01)
            $f = $chord[$idx]
            $v += ([Math]::Sin(2 * [Math]::PI * $f * $lt) * 0.32) +
                  ([Math]::Sin(2 * [Math]::PI * $f * 2.0 * $lt) * 0.12) +
                  ([Math]::Sin(2 * [Math]::PI * $f * 3.0 * $lt) * 0.06)
            $v *= $env
        }
        $s[$i] = [Math]::Max(-1.0, [Math]::Min(1.0, $v)) * 0.6
    }
}

# Piano — warm struck notes, three-note motif with harmonics.
New-Wav -Name 'piano' -Seconds 1.6 -Render {
    param($s, $n, $sr)
    $notes = @(392.0, 523.3, 659.3)
    $step = 0.30
    for ($i = 0; $i -lt $n; $i++) {
        $t = $i / $sr
        $v = 0.0
        for ($k = 0; $k -lt $notes.Count; $k++) {
            $lt = $t - ($k * $step)
            if ($lt -lt 0) { continue }
            $env = [Math]::Exp(-2.6 * $lt) * [Math]::Min(1.0, $lt / 0.006)
            $f = $notes[$k]
            $v += ([Math]::Sin(2 * [Math]::PI * $f * $lt) * 0.48) +
                  ([Math]::Sin(2 * [Math]::PI * $f * 2.0 * $lt) * 0.20) +
                  ([Math]::Sin(2 * [Math]::PI * $f * 3.0 * $lt) * 0.10) +
                  ([Math]::Sin(2 * [Math]::PI * $f * 4.0 * $lt) * 0.05)
            $v *= $env
        }
        $s[$i] = [Math]::Max(-1.0, [Math]::Min(1.0, $v)) * 0.5
    }
}

# Water drops — three falling drips.
New-Wav -Name 'water' -Seconds 1.3 -Render {
    param($s, $n, $sr)
    $drops = @(
        @(0.05, 2100.0, 900.0),
        @(0.42, 2400.0, 1000.0),
        @(0.85, 1900.0, 800.0)
    )
    for ($i = 0; $i -lt $n; $i++) {
        $t = $i / $sr
        $v = 0.0
        foreach ($d in $drops) {
            $lt = $t - $d[0]
            if ($lt -lt 0 -or $lt -gt 0.28) { continue }
            $p = $lt / 0.28
            $f = $d[1] + (($d[2] - $d[1]) * $p)
            $env = [Math]::Exp(-9.0 * $lt) * [Math]::Min(1.0, $lt / 0.002)
            $v += [Math]::Sin(2 * [Math]::PI * $f * $lt) * $env
        }
        $s[$i] = [Math]::Max(-1.0, [Math]::Min(1.0, $v)) * 0.55
    }
}

Write-Output "Done. Alarm tone assets written to $outDir"
