# Phone Wake Up

A Windows PowerShell tool and reusable Codex skill for sending wake and hardware-key input to an Android phone over USB when its display or power button is unavailable.

## What worked

ADB was unavailable and the phone's display could not be used to approve debugging. The working route used Android Open Accessory 2.0 HID input over USB. After binding the phone's accessory interface to WinUSB with Zadig, a PowerShell script sent Power, Wake, and Volume Down reports. The user confirmed the method worked. See [the troubleshooting notes](docs/problem-to-solution.md).

## Requirements

- Windows 10 or 11, PowerShell, and a data-capable USB cable.
- A phone that supports Android Open Accessory 2.0 HID.
- WinUSB bound to the phone's USB accessory interface.
- ADB access is not required. A lock-screen PIN is not used or requested.

## Setup

From the repository folder, run:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\setup.ps1
```

Setup downloads the pinned scrcpy release, checks its SHA-256, and downloads Zadig only if its Authenticode signature is valid.

If the phone is still using MTP, use Zadig's **Options → List All Devices** to select its accessory interface and bind that interface to **WinUSB**. Check the selected device in Zadig before replacing its driver; this can temporarily interrupt MTP file transfer. This driver selection is the only device-specific setup step.

## Send input

Run the script without entering device IDs:

```powershell
.\scripts\wake-phone-hid.ps1 -Action Repeat
```

The script scans connected WinUSB devices, checks which one confirms Android Open Accessory 2.0 support, and proceeds only when it finds exactly one. It does not print device IDs or read the USB serial descriptor. Available actions are `Repeat`, `Wake`, `PowerAndWake`, and `VolumeDown`. `Repeat` sends a short Power press, System Wake Up, and one Volume Down press.

## Restore MTP

If you replaced the phone's driver with WinUSB, open an elevated PowerShell window and run:

```powershell
.\scripts\restore-phone-mtp.ps1
```

The recovery script finds the connected WinUSB device automatically, checks its driver INF, and asks before removing the matching package and rescanning devices. Disconnect other WinUSB USB devices first if the script reports ambiguity.

## Privacy

The repository contains no device serial number, personally assigned device name, or model-specific USB identifiers. At runtime, Windows Plug and Play supplies the USB vendor/product IDs needed for device discovery; these are not hard-coded, printed, or saved. The HID script does not request the USB serial descriptor. Avoid sharing system logs or screenshots that might show device details.

## Files

- `SKILL.md`: reusable Codex skill instructions.
- `setup.ps1`: downloads and verifies local tools.
- `scripts/wake-phone-hid.ps1`: auto-detects an AOA 2.0 phone and sends HID input.
- `scripts/restore-phone-mtp.ps1`: guarded automatic driver recovery.
- `docs/problem-to-solution.md`: troubleshooting account and recovery notes.
- `references/`: implementation sources and license.
