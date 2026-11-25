# Phone Wake Up

A Windows PowerShell tool and reusable Codex skill for sending wake and hardware-key input to an Android phone over USB when its display or power button is unavailable.

## What worked

The phone was connected to a Windows PC, but Android Debug Bridge (ADB) was unavailable and the display could not be used to approve debugging. The solution used Android Open Accessory 2.0 (AOA 2.0) HID input over USB. After binding the phone's accessory interface to WinUSB with Zadig, a PowerShell script sent Power, Wake, and Volume Down reports. The user confirmed the method worked. See [the troubleshooting notes](docs/problem-to-solution.md).

## Requirements

- Windows 10 or 11, PowerShell, and a data-capable USB cable.
- A phone that supports Android Open Accessory 2.0 HID.
- The phone's USB vendor ID and product ID, entered locally when running the scripts.
- ADB access is not required. A lock-screen PIN is not used or requested.

## Setup

From the repository folder, run:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\setup.ps1
```

Setup downloads the pinned scrcpy release, checks its SHA-256, and downloads Zadig only if its Authenticode signature is valid.

If the phone is using MTP, use Zadig's **Options → List All Devices** to select its accessory interface and bind that interface to **WinUSB**. Check the selected device in Zadig before replacing its driver; this can temporarily interrupt MTP file transfer.

Find the phone's USB vendor and product IDs in Windows Device Manager under the relevant USB device's **Properties → Details → Hardware Ids**. Enter those values locally; do not add serial numbers or personally identifying details to the repository.

## Send input

Pass the four-digit hexadecimal vendor and product IDs you found on your own PC:

```powershell
.\scripts\wake-phone-hid.ps1 -VendorId '1234' -ProductId 'ABCD' -Action Repeat
```

Replace the example IDs with the values shown on your PC. Available actions are `Repeat`, `Wake`, `PowerAndWake`, and `VolumeDown`. `Repeat` sends a short Power press, System Wake Up, and one Volume Down press.

## Restore MTP

If you replaced the phone's driver with WinUSB, run the recovery script from an elevated PowerShell window with the same local IDs:

```powershell
.\scripts\restore-phone-mtp.ps1 -VendorId '1234' -ProductId 'ABCD'
```

The script checks the connected device and driver INF, then asks before removing the matching WinUSB package and rescanning devices.

## Privacy

The repository contains no device serial number, phone number, personally assigned device name, or model-specific USB identifiers. The scripts require USB vendor/product IDs as command-line inputs. They do not contain a fixed serial or request the USB serial descriptor; Windows Plug and Play device paths are used at runtime for device lookup. Avoid sharing command history or logs if they contain device IDs.

## Files

- `SKILL.md`: reusable Codex skill instructions.
- `setup.ps1`: downloads and verifies local tools.
- `scripts/wake-phone-hid.ps1`: sends AOA 2.0 HID input.
- `scripts/restore-phone-mtp.ps1`: guarded driver recovery.
- `docs/problem-to-solution.md`: troubleshooting account and recovery notes.
- `references/`: implementation sources and license.
