param(
    [Parameter(Mandatory=$true)]
    [string]$Path
)

$oldText = "seed01.kmdefi.net"
$newText = "seed04.kmdefi.net"

if (-not (Test-Path -LiteralPath $Path)) {
    throw "KDF executable not found: $Path"
}

$old = [Text.Encoding]::ASCII.GetBytes($oldText)
$new = [Text.Encoding]::ASCII.GetBytes($newText)

if ($old.Length -ne $new.Length) {
    throw "Seed replacement must keep the same byte length"
}

[byte[]]$bytes = [IO.File]::ReadAllBytes($Path)
$patched = 0

for ($i = 0; $i -le $bytes.Length - $old.Length; $i++) {
    $match = $true
    for ($j = 0; $j -lt $old.Length; $j++) {
        if ($bytes[$i + $j] -ne $old[$j]) {
            $match = $false
            break
        }
    }

    if ($match) {
        [Array]::Copy($new, 0, $bytes, $i, $new.Length)
        $patched++
    }
}

if ($patched -gt 0) {
    [IO.File]::WriteAllBytes($Path, $bytes)
    Write-Host "Patched KDF seed01 -> seed04 ($patched occurrence(s))"
} else {
    Write-Host "seed01 not found; checking existing KDF"
}

$text = [Text.Encoding]::ASCII.GetString([IO.File]::ReadAllBytes($Path))

if ($text.Contains($oldText)) {
    throw "KDF still contains $oldText"
}

if (-not $text.Contains($newText)) {
    throw "KDF does not contain $newText"
}
