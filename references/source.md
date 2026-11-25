# Implementation sources

- [Android Open Accessory 2.0](https://source.android.com/docs/core/interaction/accessories/aoa2) documents the HID registration, report descriptor, and HID event control requests used by the script.
- [scrcpy OTG guide](https://github.com/Genymobile/scrcpy/blob/master/doc/otg.md) describes USB HID control without ADB.
- The setup script downloads the [official scrcpy v5.0.1 Windows release](https://github.com/Genymobile/scrcpy/releases/tag/v5.0.1), pinned to SHA-256 `b12a2c4ee8be317422451fc7dcf8ee20a71b5ea7ef9ad73ddd825a25316227a5`.
- The setup script downloads [Zadig 2.9](https://github.com/pbatard/libwdi/releases/tag/v1.5.1) and accepts it only when Windows validates its Authenticode signature as signed by Akeo Consulting.
- The scrcpy release's Apache 2.0 license is included in `references/scrcpy-LICENSE.txt` after setup.
