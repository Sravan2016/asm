param(
    [Parameter(Mandatory = $true)][string]$InputPath,
    [Parameter(Mandatory = $true)][string]$OutputPath
)

$outDir = Split-Path -Parent $OutputPath
if ($outDir) {
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
}

$result = foreach ($line in Get-Content -Path $InputPath) {
    if ($line -match '^\s*\.intel_syntax') { continue }
    if ($line -match '^\s*\.def\b') { continue }
    if ($line -match '^\s*\.endef\b') { continue }
    if ($line -match '^\s*\.extern\s+(.+)$') {
        "extern $($matches[1].Trim())"
        continue
    }

    if ($line -match '^\s*\.equ\s+([^,]+),\s*(.+)$') {
        "%define $($matches[1].Trim()) $($matches[2].Trim())"
        continue
    }

    if ($line -match '^\s*\.section\s+\.rdata') {
        'section .rdata'
        continue
    }

    if ($line -match '^\s*\.section\s+\.bss') {
        'section .bss'
        continue
    }

    if ($line -match '^\s*\.text\s*$') {
        'section .text'
        continue
    }

    if ($line -match '^\s*\.globl\s+(.+)$') {
        "global $($matches[1].Trim())"
        continue
    }

    if ($line -match '^(\s*[A-Za-z_\.][A-Za-z0-9_\.]*:)\s*\.asciz\s+"(.*)"\s*$') {
        $label = $matches[1]
        $text = $matches[2].Replace('`', '``')
        "$label db ``$text``, 0"
        continue
    }

    if ($line -match '^(\s*[A-Za-z_\.][A-Za-z0-9_\.]*:)\s*\.skip\s+([0-9]+)\s*$') {
        "$($matches[1]) resb $($matches[2])"
        continue
    }

    $converted = $line -replace '\[rip\+([A-Za-z_][A-Za-z0-9_]*)\]', '[rel $1]'
    $converted = $converted -replace '\b(byte|word|dword|qword) ptr\b', '$1'
    $converted = $converted -replace "'\\\\'", '0x5c'
    $converted
}

$result | Set-Content -Path $OutputPath -Encoding ASCII
