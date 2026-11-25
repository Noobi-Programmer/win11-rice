#requires -Version 5.1
# Prints the current ricing mode in uppercase for the YASB mode button.
$modeFile = 'C:\Scripts\current_mode.txt'
$mode = 'linux'
if (Test-Path -LiteralPath $modeFile) {
    $raw = (Get-Content -Path $modeFile -Raw -ErrorAction SilentlyContinue)
    if ($raw) { $mode = $raw.Trim() }
}
if (-not $mode) { $mode = 'linux' }
Write-Output $mode.ToUpperInvariant()
