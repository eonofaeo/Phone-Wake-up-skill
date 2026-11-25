---
name: phone-wake-up
description: Wake an Android phone or send a volume key over a configured Windows USB accessory connection when the display or power button is unavailable.
metadata:
  short-description: Wake a phone or send a volume key over USB
---

# Phone Wake Up

Use this skill when the user needs hardware-key input sent to their Android phone over an existing Windows USB connection.

Run `setup.ps1` once, then pass the phone's USB vendor and product IDs as locally supplied four-digit hexadecimal values:

```powershell
.\scripts\wake-phone-hid.ps1 -VendorId '1234' -ProductId 'ABCD' -Action Repeat
```

Ask the user to substitute IDs found on their own PC. Do not request or store a USB serial number, phone number, personally assigned device name, lock-screen PIN, or other identifying phone details. The script checks for exactly one matching USB device and requires WinUSB and Android Open Accessory 2.0 support. See [README.md](README.md) for setup and [the troubleshooting notes](docs/problem-to-solution.md) for context and recovery.

Available actions are `Repeat`, `Wake`, `PowerAndWake`, and `VolumeDown`. The `Repeat` action sends a short Power press, System Wake Up, and one Volume Down press.
