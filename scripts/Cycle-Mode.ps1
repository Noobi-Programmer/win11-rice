#requires -Version 5.1
<#
    Cycle-Mode.ps1 - Advances linux -> hybrid -> studio -> saver -> linux.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$Scripts = 'C:\Scripts'
$ModeFile = Join-Path $Scripts 'current_mode.txt'
$Log = Join-Path $Scripts 'cycle-mode.log'
$Order = @('linux', 'hybrid', 'studio', 'saver')

$current = 'linux'
if (Test-Path -LiteralPath $ModeFile) {
    $fromFile = (Get-Content -Path $ModeFile -Raw -ErrorAction SilentlyContinue).Trim()
    if ($fromFile) { $current = $fromFile }
}

$index = [Array]::IndexOf($Order, $current)
if ($index -lt 0) { $index = 0 }
$next = $Order[($index + 1) % $Order.Count]

$line = '{0}  {1} -> {2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $current, $next
Write-Host $line
Add-Content -Path $Log -Value $line -Encoding UTF8

& (Join-Path $Scripts 'Switch-Mode.ps1') -Mode $next
