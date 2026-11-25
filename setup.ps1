param(
    [string]$VendorDirectory = (Join-Path $PSScriptRoot 'vendor')
)

$ErrorActionPreference = 'Stop'
$scrcpyVersion = 'v5.0.1'
$scrcpyArchiveName = 'scrcpy-win64-v5.0.1.zip'
$scrcpyArchiveUrl = 'https://github.com/Genymobile/scrcpy/releases/download/v5.0.1/scrcpy-win64-v5.0.1.zip'
$scrcpySha256 = 'b12a2c4ee8be317422451fc7dcf8ee20a71b5ea7ef9ad73ddd825a25316227a5'
$zadigUrl = 'https://github.com/pbatard/libwdi/releases/download/v1.5.1/zadig-2.9.exe'

if ($env:OS -ne 'Windows_NT') { throw 'This setup script requires Windows.' }
New-Item -ItemType Directory -Path $VendorDirectory -Force | Out-Null
$archivePath = Join-Path $VendorDirectory $scrcpyArchiveName
if (-not (Test-Path -LiteralPath $archivePath)) {
    Invoke-WebRequest -Uri $scrcpyArchiveUrl -OutFile $archivePath -UseBasicParsing
}
$actualHash = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash.ToLowerInvariant()
if ($actualHash -ne $scrcpySha256) { throw "scrcpy archive SHA-256 mismatch: $actualHash" }

$extractRoot = Join-Path $VendorDirectory 'scrcpy-win64-v5.0.1'
Expand-Archive -LiteralPath $archivePath -DestinationPath $extractRoot -Force
$releaseRoot = Join-Path $extractRoot 'scrcpy-win64-v5.0.1'
$libusbPath = Join-Path $releaseRoot 'libusb-1.0.dll'
$licensePath = Join-Path $releaseRoot 'LICENSE.txt'
if (-not (Test-Path -LiteralPath $libusbPath)) { throw 'libusb-1.0.dll was not found in the pinned scrcpy release.' }
if (-not (Test-Path -LiteralPath $licensePath)) { throw 'The scrcpy release license file was not found.' }
Copy-Item -LiteralPath $libusbPath -Destination (Join-Path $PSScriptRoot 'scripts\libusb-1.0.dll') -Force
Copy-Item -LiteralPath $licensePath -Destination (Join-Path $PSScriptRoot 'references\scrcpy-LICENSE.txt') -Force

$zadigPath = Join-Path $VendorDirectory 'zadig-2.9.exe'
if (-not (Test-Path -LiteralPath $zadigPath)) {
    Invoke-WebRequest -Uri $zadigUrl -OutFile $zadigPath -UseBasicParsing
}
$signature = Get-AuthenticodeSignature -LiteralPath $zadigPath
if ($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch 'Akeo Consulting') {
    throw 'Zadig signature verification failed; do not run this download.'
}

Write-Output "Verified scrcpy $scrcpyVersion archive SHA-256: $actualHash"
Write-Output "Verified Zadig publisher: $($signature.SignerCertificate.Subject)"
Write-Output 'Setup is ready. Use Zadig to bind the phone accessory interface to WinUSB, then run scripts\wake-phone-hid.ps1 for automatic detection.'
