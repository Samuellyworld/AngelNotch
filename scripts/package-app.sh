#!/bin/zsh
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$PROJECT_DIR/dist/.build/AngelNotch.app"
ENTITLEMENTS="$PROJECT_DIR/resources/AngelNotch.entitlements"

"$PROJECT_DIR/scripts/build-app-bundle.sh"

codesign \
  --force \
  --options runtime \
  --timestamp=none \
  --entitlements "$ENTITLEMENTS" \
  --sign - \
  "$APP_DIR"
codesign --verify --deep --strict --verbose=2 "$APP_DIR"

echo "Built local ad-hoc app: $APP_DIR"
