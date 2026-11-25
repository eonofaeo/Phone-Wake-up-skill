[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[0-9A-Fa-f]{4}$')]
    [string]$VendorId,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[0-9A-Fa-f]{4}$')]
    [string]$ProductId
)

$ErrorActionPreference = 'Stop'
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Run this recovery script from an elevated PowerShell window.'
}

$devicePattern = '^USB\\VID_' + $VendorId + '&PID_' + $ProductId + '\\[^\\]+$'
$matchingPhones = @(Get-PnpDevice -PresentOnly | Where-Object { $_.InstanceId -match $devicePattern })
if ($matchingPhones.Count -ne 1) { throw "Expected exactly one connected phone USB device; found $($matchingPhones.Count)." }
$deviceId = $matchingPhones[0].InstanceId
$service = (Get-PnpDeviceProperty -InstanceId $deviceId -KeyName 'DEVPKEY_Device_Service').Data
if ($service -ne 'WinUSB') { throw "The connected phone is not using WinUSB (detected: $service)." }
$publishedInf = (Get-PnpDeviceProperty -InstanceId $deviceId -KeyName 'DEVPKEY_Device_DriverInfPath').Data
if ($publishedInf -notmatch '^oem[0-9]+\.inf$') { throw "Unexpected published driver INF: $publishedInf" }
$infPath = Join-Path $env:windir ("INF\$publishedInf")
if (-not (Test-Path -LiteralPath $infPath)) { throw "Driver INF not found: $infPath" }
$expectedHardwareId = 'VID_' + $VendorId + '&PID_' + $ProductId
if ((Get-Content -LiteralPath $infPath -Raw) -notmatch [regex]::Escape($expectedHardwareId)) {
    throw 'The installed INF does not match the supplied USB IDs; refusing removal.'
}

if ($PSCmdlet.ShouldProcess("$deviceId ($publishedInf)", 'Remove the phone WinUSB driver package and rescan devices')) {
    & pnputil.exe /delete-driver $publishedInf /uninstall
    if ($LASTEXITCODE -ne 0) { throw 'Windows could not remove the phone driver package.' }
    & pnputil.exe /scan-devices
    if ($LASTEXITCODE -ne 0) { throw 'Windows removed the package but the device rescan failed.' }
    Write-Output 'WinUSB package removed. Reconnect the phone if MTP does not return.'
}
