#!/usr/bin/env bash
# Writes android/upload-keystore.jks and android/key.properties from GitLab CI variables.
# Required (for signed release): ANDROID_KEYSTORE_BASE64, ANDROID_KEYSTORE_PASSWORD,
# ANDROID_KEY_ALIAS. Optional: ANDROID_KEY_PASSWORD (defaults to ANDROID_KEYSTORE_PASSWORD).
set -euo pipefail

ROOT="${CI_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
ANDROID_DIR="$ROOT/android"

if [[ -z "${ANDROID_KEYSTORE_BASE64:-}" ]]; then
  echo "ANDROID_KEYSTORE_BASE64 not set; skipping Android signing setup."
  exit 0
fi

mkdir -p "$ANDROID_DIR"
echo "$ANDROID_KEYSTORE_BASE64" | base64 -d > "$ANDROID_DIR/upload-keystore.jks"

STORE_PW="${ANDROID_KEYSTORE_PASSWORD:?ANDROID_KEYSTORE_PASSWORD is required when ANDROID_KEYSTORE_BASE64 is set}"
KEY_PW="${ANDROID_KEY_PASSWORD:-$STORE_PW}"
ALIAS="${ANDROID_KEY_ALIAS:?ANDROID_KEY_ALIAS is required when ANDROID_KEYSTORE_BASE64 is set}"

cat > "$ANDROID_DIR/key.properties" <<EOF
storePassword=$STORE_PW
keyPassword=$KEY_PW
keyAlias=$ALIAS
storeFile=upload-keystore.jks
EOF

echo "Android release signing files written under android/."
