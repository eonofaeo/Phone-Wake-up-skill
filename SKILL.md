---
name: phone-wake-up
description: Automatically detect a connected Android phone over a configured Windows USB accessory connection and send a wake or volume key when the display or power button is unavailable.
metadata:
  short-description: Wake a phone or send a volume key over USB
---

# Phone Wake Up

Use this skill when the user needs hardware-key input sent to their Android phone over an existing Windows USB connection.

Run `setup.ps1` once, then run the HID script without requesting device IDs or serial numbers:

```powershell
.\scripts\wake-phone-hid.ps1 -Action Repeat
```

The script checks connected WinUSB devices for Android Open Accessory 2.0 support and proceeds only when it finds one compatible device. If the phone is still using MTP, bind its accessory interface to WinUSB with Zadig first. Do not request or store a USB serial number, phone number, personally assigned device name, lock-screen PIN, or other identifying phone details. See [README.md](README.md) for setup and [the troubleshooting notes](docs/problem-to-solution.md) for recovery.

Available actions are `Repeat`, `Wake`, `PowerAndWake`, and `VolumeDown`. The `Repeat` action sends a short Power press, System Wake Up, and one Volume Down press.
