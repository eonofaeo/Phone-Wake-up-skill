param(
    [ValidateSet('Repeat', 'Wake', 'PowerAndWake', 'VolumeDown')]
    [string]$Action = 'Repeat'
)

$ErrorActionPreference = 'Stop'
$libraryPath = Join-Path $PSScriptRoot 'libusb-1.0.dll'
if (-not (Test-Path -LiteralPath $libraryPath)) { throw 'Run setup.ps1 first to download libusb-1.0.dll.' }
$escapedLibraryPath = $libraryPath.Replace('\', '\\')
if (-not ('PhoneAccessoryUsb' -as [type])) {
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class PhoneAccessoryUsb {
    [DllImport("$escapedLibraryPath", CallingConvention=CallingConvention.Cdecl)] public static extern int libusb_init(out IntPtr context);
    [DllImport("$escapedLibraryPath", CallingConvention=CallingConvention.Cdecl)] public static extern void libusb_exit(IntPtr context);
    [DllImport("$escapedLibraryPath", CallingConvention=CallingConvention.Cdecl)] public static extern IntPtr libusb_open_device_with_vid_pid(IntPtr context, ushort vid, ushort pid);
    [DllImport("$escapedLibraryPath", CallingConvention=CallingConvention.Cdecl)] public static extern void libusb_close(IntPtr device);
    [DllImport("$escapedLibraryPath", CallingConvention=CallingConvention.Cdecl)] public static extern int libusb_control_transfer(IntPtr handle, byte requestType, byte request, ushort value, ushort index, [In, Out] byte[] data, ushort length, uint timeout);
    [DllImport("$escapedLibraryPath", CallingConvention=CallingConvention.Cdecl)] public static extern IntPtr libusb_error_name(int error);
    public static string Error(int error) { return Marshal.PtrToStringAnsi(libusb_error_name(error)); }
}
"@
}

$usbContext = [IntPtr]::Zero
$usbHandle = [IntPtr]::Zero
$hidRegistered = $false
$hidId = [uint16]0x52

function Send-Control([byte]$request, [uint16]$value, [uint16]$index, [byte[]]$payload) {
    $payloadLength = if ($null -eq $payload) { 0 } else { $payload.Length }
    $result = [PhoneAccessoryUsb]::libusb_control_transfer($usbHandle, 0x40, $request, $value, $index, $payload, $payloadLength, 3000)
    if ($result -lt 0) { throw ('USB request ' + $request + ' failed: ' + [PhoneAccessoryUsb]::Error($result)) }
    if ($result -ne $payloadLength) { throw ('USB request ' + $request + ' transferred an unexpected number of bytes: ' + $result) }
}

function Send-HidPress([byte[]]$report, [string]$name) {
    Send-Control 57 $hidId 0 $report
    try { Start-Sleep -Milliseconds 120 }
    finally { Send-Control 57 $hidId 0 ([byte[]]::new($report.Length)) }
    Write-Output ('Sent and released: ' + $name)
}

try {
    $initResult = [PhoneAccessoryUsb]::libusb_init([ref]$usbContext)
    if ($initResult -ne 0) { throw ('libusb initialization failed: ' + $initResult) }

    # Read candidate vendor/product pairs from Windows at runtime. Nothing is hard-coded,
    # and no USB serial descriptor is requested or printed.
    $usbCandidates = @{}
    foreach ($pnpDevice in (Get-PnpDevice -PresentOnly)) {
        $instanceId = [string]$pnpDevice.InstanceId
        if ($instanceId -notmatch '^USB\\VID_([0-9A-Fa-f]{4})&PID_([0-9A-Fa-f]{4})\\') { continue }
        $vendorId = [Convert]::ToUInt16($Matches[1], 16)
        $productId = [Convert]::ToUInt16($Matches[2], 16)
        $key = '{0:X4}:{1:X4}' -f $vendorId, $productId
        if ($usbCandidates.ContainsKey($key)) { continue }

        $service = $null
        try {
            $service = (Get-PnpDeviceProperty -InstanceId $instanceId -KeyName 'DEVPKEY_Device_Service' -ErrorAction Stop).Data
        } catch {}
        if ($service -eq 'WinUSB') {
            $usbCandidates[$key] = [pscustomobject]@{ VendorId = $vendorId; ProductId = $productId }
        }
    }
    if ($usbCandidates.Count -eq 0) {
        throw 'No connected WinUSB USB devices were found. Connect the phone and bind its accessory interface to WinUSB with Zadig.'
    }

    $aoaCandidates = @()
    foreach ($candidate in $usbCandidates.Values) {
        $candidateHandle = [PhoneAccessoryUsb]::libusb_open_device_with_vid_pid($usbContext, $candidate.VendorId, $candidate.ProductId)
        if ($candidateHandle -eq [IntPtr]::Zero) { continue }

        $protocol = [byte[]]::new(2)
        $probeResult = [PhoneAccessoryUsb]::libusb_control_transfer($candidateHandle, 0xC0, 51, 0, 0, $protocol, 2, 750)
        if ($probeResult -eq 2 -and [BitConverter]::ToUInt16($protocol, 0) -ge 2) {
            $aoaCandidates += [pscustomobject]@{
                Handle = $candidateHandle
                Version = [BitConverter]::ToUInt16($protocol, 0)
            }
        } else {
            [PhoneAccessoryUsb]::libusb_close($candidateHandle)
        }
    }

    if ($aoaCandidates.Count -eq 0) {
        throw 'No connected WinUSB device confirmed Android Open Accessory 2.0 support. Check the cable, driver, and phone compatibility.'
    }
    if ($aoaCandidates.Count -gt 1) {
        foreach ($candidate in $aoaCandidates) { [PhoneAccessoryUsb]::libusb_close($candidate.Handle) }
        throw 'More than one connected device supports Android Open Accessory 2.0. Disconnect other accessory devices and retry.'
    }

    $usbHandle = $aoaCandidates[0].Handle
    Write-Output ('Automatically detected one Android accessory device. Protocol version: ' + $aoaCandidates[0].Version)

    if ($Action -eq 'VolumeDown') {
        $reportDescriptor = [byte[]]@(0x05,0x0C,0x09,0x01,0xA1,0x01,0x15,0x00,0x26,0xFF,0x03,0x19,0x00,0x2A,0xFF,0x03,0x75,0x10,0x95,0x01,0x81,0x00,0xC0)
    } else {
        $reportDescriptor = [byte[]]@(0x05,0x01,0x09,0x80,0xA1,0x01,0x15,0x00,0x25,0x01,0x75,0x01,0x95,0x03,0x09,0x81,0x09,0x82,0x09,0x83,0x81,0x02,0x75,0x05,0x95,0x01,0x81,0x03,0xC0)
    }

    Send-Control 54 $hidId $reportDescriptor.Length $null
    $hidRegistered = $true
    Send-Control 56 $hidId 0 $reportDescriptor
    Start-Sleep -Milliseconds 750

    if ($Action -in @('Repeat', 'PowerAndWake')) {
        Send-HidPress ([byte[]]@(0x01)) 'Power (short press)'
        Start-Sleep -Milliseconds 1000
    }
    if ($Action -in @('Repeat', 'Wake', 'PowerAndWake')) {
        Send-HidPress ([byte[]]@(0x04)) 'System Wake Up'
        Start-Sleep -Milliseconds 750
    }
    if ($Action -in @('Repeat', 'VolumeDown')) {
        Send-HidPress ([byte[]]@(0xEA,0x00)) 'Volume Down (one press)'
    }
} finally {
    if ($hidRegistered) {
        try { Send-Control 55 $hidId 0 $null } catch { Write-Warning ('Could not unregister USB HID: ' + $_.Exception.Message) }
    }
    if ($usbHandle -ne [IntPtr]::Zero) { [PhoneAccessoryUsb]::libusb_close($usbHandle) }
    if ($usbContext -ne [IntPtr]::Zero) { [PhoneAccessoryUsb]::libusb_exit($usbContext) }
}
