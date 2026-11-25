[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param()

$ErrorActionPreference = 'Stop'
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Run this recovery script from an elevated PowerShell window.'
}

# Discover the connected WinUSB device and read its hardware IDs locally.
$candidates = @{}
foreach ($pnpDevice in (Get-PnpDevice -PresentOnly)) {
    $instanceId = [string]$pnpDevice.InstanceId
    if ($instanceId -notmatch '^USB\\VID_([0-9A-Fa-f]{4})&PID_([0-9A-Fa-f]{4})\\') { continue }
    $vendorId = $Matches[1].ToUpperInvariant()
    $productId = $Matches[2].ToUpperInvariant()
    $key = $vendorId + ':' + $productId
    if ($candidates.ContainsKey($key)) { continue }

    $service = $null
    try {
        $service = (Get-PnpDeviceProperty -InstanceId $instanceId -KeyName 'DEVPKEY_Device_Service' -ErrorAction Stop).Data
    } catch {}
    if ($service -eq 'WinUSB') {
        $candidates[$key] = [pscustomobject]@{
            InstanceId = $instanceId
            HardwareId = "VID_$vendorId&PID_$productId"
        }
    }
}
if ($candidates.Count -eq 0) { throw 'No connected WinUSB USB device was found.' }
if ($candidates.Count -gt 1) { throw 'Multiple WinUSB USB devices are connected. Disconnect unrelated devices and retry.' }

$device = @($candidates.Values)[0]
$publishedInf = (Get-PnpDeviceProperty -InstanceId $device.InstanceId -KeyName 'DEVPKEY_Device_DriverInfPath').Data
if ($publishedInf -notmatch '^oem[0-9]+\.inf$') { throw 'The connected device has an unexpected published driver package.' }
$infPath = Join-Path $env:windir ("INF\$publishedInf")
if (-not (Test-Path -LiteralPath $infPath)) { throw 'The connected device driver INF was not found.' }
if ((Get-Content -LiteralPath $infPath -Raw) -notmatch [regex]::Escape($device.HardwareId)) {
    throw 'The installed INF does not match the connected device; refusing removal.'
}

if ($PSCmdlet.ShouldProcess("the connected phone's matching WinUSB package", 'Remove the driver package and rescan devices')) {
    & pnputil.exe /delete-driver $publishedInf /uninstall
    if ($LASTEXITCODE -ne 0) { throw 'Windows could not remove the driver package.' }
    & pnputil.exe /scan-devices
    if ($LASTEXITCODE -ne 0) { throw 'Windows removed the package but the device rescan failed.' }
    Write-Output 'WinUSB package removed. Reconnect the phone if MTP does not return.'
}
