# Build a Play Store–signed AAB on Windows.
# Use this when `flutter build appbundle --release` fails on symbol stripping.

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

if (-not (Test-Path "android\key.properties")) {
    Write-Error "Missing android\key.properties. Run scripts\setup_android_release_signing.ps1 first."
}

Write-Host "==> flutter pub get"
flutter pub get

Write-Host "==> Gradle bundleRelease (release signing)"
Set-Location android
.\gradlew.bat bundleRelease
$gradleExit = $LASTEXITCODE
Set-Location $Root

if ($gradleExit -ne 0) {
    Write-Error "Gradle bundleRelease failed (exit $gradleExit)."
}

$Aab = "build\app\outputs\bundle\release\app-release.aab"
if (Test-Path $Aab) {
    $sizeMb = [math]::Round((Get-Item $Aab).Length / 1MB, 1)
    Write-Host ""
    Write-Host "SUCCESS: $Root\$Aab ($sizeMb MB)"
    Write-Host "Upload this file to Google Play Console."
} else {
    Write-Error "AAB not found at $Aab"
}
