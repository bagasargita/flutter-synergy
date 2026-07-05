# One-time setup for Play Store release signing (Windows).
# Creates android/upload-keystore.jks and android/key.properties (both gitignored).

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$AndroidDir = Join-Path $Root "android"
$Keystore = Join-Path $AndroidDir "upload-keystore.jks"
$Props = Join-Path $AndroidDir "key.properties"

if (Test-Path $Keystore) {
    Write-Host "Keystore already exists: $Keystore"
} else {
    $storePass = Read-Host "Enter keystore password (storePassword)"
    $keyPass = if ($storePass) { $storePass } else { Read-Host "Enter key password (keyPassword)" }
    keytool -genkeypair -v `
        -keystore $Keystore `
        -alias upload `
        -keyalg RSA -keysize 2048 -validity 10000 `
        -storepass $storePass -keypass $keyPass `
        -dname "CN=Flutter Synergy, OU=Mobile, O=Synergy Engineering, L=Jakarta, ST=Jakarta, C=ID"
    Write-Host "Created $Keystore"
}

if (-not (Test-Path $Props)) {
    $storePass = Read-Host "storePassword for key.properties"
    $keyPass = Read-Host "keyPassword for key.properties"
    @"
storePassword=$storePass
keyPassword=$keyPass
keyAlias=upload
storeFile=upload-keystore.jks
"@ | Set-Content -Path $Props -Encoding UTF8
    Write-Host "Created $Props"
}

Write-Host ""
Write-Host "Done. Build release AAB with:"
Write-Host "  flutter build appbundle --release"
