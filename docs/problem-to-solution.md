# From an inaccessible phone to USB wake controls

## The problem

An Android phone was connected to a Windows PC. Its power button did not work and its display could not be viewed, so the user could not unlock it, change its USB mode, or approve debugging. The immediate need was to wake the screen and silence a ringing alarm if possible.

## What Windows and ADB showed

Windows detected a portable-device connection for file transfer. That did not grant Android input control. ADB was initially unavailable on PATH; after locating the Android SDK tools, `adb devices -l` showed no authorized device. Without USB debugging or an on-screen approval prompt, ordinary scrcpy screen mirroring and ADB shell commands could not control the phone.

Charging, calling the phone, the fingerprint sensor, double-tap-to-wake, and pressing a volume button during the alarm were tried or considered, but did not solve the inaccessible-screen problem. A setting such as double-tap wake must already be enabled and cannot be changed through MTP alone.

## The USB input route

The official scrcpy documentation describes OTG mode, which sends keyboard and mouse HID reports without USB debugging. The first Windows attempt could not open the phone through its MTP driver. This was a Windows USB driver binding issue, not a missing lock-screen password.

The working approach was:

1. Use Zadig to bind the phone's appropriate USB accessory interface to WinUSB. Confirm the correct interface in Zadig first; this can temporarily interrupt MTP file transfer.
2. Use the official scrcpy OTG build to confirm the USB input route. OTG sends input without screen video.
3. Use a PowerShell script with the official scrcpy release's libusb library and Android Open Accessory 2.0 HID protocol to send precise key reports.
4. The user confirmed the Power, Wake, and Volume Down sequence worked.

## Run the script

Run setup once to fetch the pinned, checksum-verified scrcpy release and signed Zadig utility. If the phone currently uses MTP, bind its accessory interface to WinUSB using Zadig. Then run:

```powershell
.\scripts\wake-phone-hid.ps1 -Action Repeat
```

The script scans connected WinUSB USB devices, queries their AOA protocol version, and proceeds only if exactly one confirms AOA 2.0 support. It does not ask for device IDs and does not request or print the USB serial descriptor.

Available actions are `Repeat`, `Wake`, `PowerAndWake`, and `VolumeDown`. A lock-screen PIN is not needed or used. Because OTG provides no screen video, it cannot confirm what appeared on the display.

## Restore MTP

The phone's MTP driver may have been replaced by WinUSB during setup. From an elevated PowerShell window, run:

```powershell
.\scripts\restore-phone-mtp.ps1
```

The recovery script discovers the connected WinUSB device, verifies its installed INF against the hardware IDs Windows provides locally, asks for confirmation before removing the package, then rescans devices. Disconnect unrelated WinUSB devices if the script reports ambiguity. Reconnect the phone if MTP does not return.

## Privacy

This account omits the phone's model, personal name, USB serial, and model-specific USB identifiers. The scripts do not contain fixed device IDs. Windows Plug and Play supplies vendor/product IDs locally at runtime for automatic discovery; the HID script does not request the USB serial descriptor or print device IDs. Do not publish personally identifying device information in documentation or command transcripts.

## Sources

- [Android Open Accessory 2.0](https://source.android.com/docs/core/interaction/accessories/aoa2)
- [scrcpy OTG guide](https://github.com/Genymobile/scrcpy/blob/master/doc/otg.md)
- [scrcpy release and license](https://github.com/Genymobile/scrcpy/releases/tag/v5.0.1)
- [Zadig releases](https://github.com/pbatard/libwdi/releases)
