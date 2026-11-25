#requires -Version 5.1
<#
    RestoreRadios.ps1
    Turns WiFi and Bluetooth radios back On via WinRT Windows.Devices.Radios.Radio
    without UAC prompts.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Runtime.WindowsRuntime
$null = [Windows.Devices.Radios.Radio, Windows.System.Devices, ContentType = WindowsRuntime]

function Invoke-WinRtAsync {
    param(
        [Parameter(Mandatory = $true)]$AsyncOp,
        [Parameter(Mandatory = $true)][Type]$ResultType
    )
    $asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
        $_.Name -eq 'AsTask' -and
        $_.IsGenericMethod -and
        $_.GetParameters().Count -eq 1 -and
        $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1'
    })[0]
    $asTask = $asTaskGeneric.MakeGenericMethod($ResultType)
    $netTask = $asTask.Invoke($null, @($AsyncOp))
    $netTask.Wait(-1) | Out-Null
    return $netTask.Result
}

try {
    $access = Invoke-WinRtAsync -AsyncOp ([Windows.Devices.Radios.Radio]::RequestAccessAsync()) -ResultType ([Windows.Devices.Radios.RadioAccessStatus])
    if ($access -ne [Windows.Devices.Radios.RadioAccessStatus]::Allowed) {
        Write-Warning "Radio access status: $access"
        return
    }

    $radios = Invoke-WinRtAsync -AsyncOp ([Windows.Devices.Radios.Radio]::GetRadiosAsync()) -ResultType ([System.Collections.Generic.IReadOnlyList[Windows.Devices.Radios.Radio]])
    foreach ($radio in $radios) {
        if ($radio.Kind -in @([Windows.Devices.Radios.RadioKind]::WiFi, [Windows.Devices.Radios.RadioKind]::Bluetooth)) {
            if ($radio.State -ne [Windows.Devices.Radios.RadioState]::On) {
                $null = Invoke-WinRtAsync -AsyncOp ($radio.SetStateAsync([Windows.Devices.Radios.RadioState]::On)) -ResultType ([Windows.Devices.Radios.RadioAccessStatus])
                Write-Host "Radio $($radio.Kind) ($($radio.Name)) -> On"
            }
        }
    }
}
catch {
    Write-Warning "RestoreRadios failed: $($_.Exception.Message)"
}
