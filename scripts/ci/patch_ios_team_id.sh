#!/usr/bin/env bash
# Replaces REPLACE_WITH_TEAM_ID in ios/ExportOptions.plist when APPLE_TEAM_ID is set.
set -euo pipefail

ROOT="${CI_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
PLIST="$ROOT/ios/ExportOptions.plist"
TEAM="${APPLE_TEAM_ID:-}"

if [[ -z "$TEAM" ]]; then
  echo "APPLE_TEAM_ID not set; leave ios/ExportOptions.plist as-is (or set TEAM in repo)."
  exit 0
fi

if [[ ! -f "$PLIST" ]]; then
  echo "Missing $PLIST"
  exit 1
fi

# Works on Linux/macOS CI (sed); Git Bash on Windows also has sed.
sed -i.bak "s/REPLACE_WITH_TEAM_ID/$TEAM/g" "$PLIST" && rm -f "$PLIST.bak"

echo "Patched ExportOptions.plist with team ID."
