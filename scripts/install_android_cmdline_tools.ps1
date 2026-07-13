# Installs Android SDK Command-line Tools (required for `flutter build appbundle` on Windows).
# Without this, Gradle may succeed but Flutter fails with:
#   "Release app bundle failed to strip debug symbols from native libraries"

$ErrorActionPreference = "Stop"

$sdk = $env:ANDROID_HOME
if (-not $sdk) { $sdk = "$env:LOCALAPPDATA\Android\Sdk" }
if (-not (Test-Path $sdk)) {
    Write-Error "Android SDK not found. Set ANDROID_HOME or install Android Studio."
}

$latestDir = Join-Path $sdk "cmdline-tools\latest"
if (Test-Path (Join-Path $latestDir "bin\sdkmanager.bat")) {
    Write-Host "cmdline-tools already installed at $latestDir"
    exit 0
}

$zipUrl = "https://dl.google.com/android/repository/commandlinetools-win-13114758_latest.zip"
$stamp = Get-Date -Format "yyyyMMddHHmmss"
$tempZip = Join-Path $env:TEMP "commandlinetools-win-$stamp.zip"
$tempExtract = Join-Path $env:TEMP "android-cmdline-tools-$stamp"

Write-Host "Downloading Android command-line tools..."
Invoke-WebRequest -Uri $zipUrl -OutFile $tempZip -UseBasicParsing

if (Test-Path $tempExtract) { Remove-Item $tempExtract -Recurse -Force }
Expand-Archive -Path $tempZip -DestinationPath $tempExtract -Force

$parent = Join-Path $sdk "cmdline-tools"
New-Item -ItemType Directory -Force -Path $parent | Out-Null
if (Test-Path $latestDir) { Remove-Item $latestDir -Recurse -Force }

# Zip contains a single `cmdline-tools` folder; contents go into `latest`.
Move-Item (Join-Path $tempExtract "cmdline-tools") $latestDir

Remove-Item $tempZip -Force -ErrorAction SilentlyContinue
Remove-Item $tempExtract -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Installed: $latestDir"
Write-Host ""
Write-Host "Next:"
Write-Host "  flutter doctor --android-licenses"
Write-Host "  flutter build appbundle --release"
