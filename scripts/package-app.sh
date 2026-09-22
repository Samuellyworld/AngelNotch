#!/bin/zsh
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$PROJECT_DIR/dist/.build/AngelNotch.app"
HOST_PATH="$APP_DIR/Contents/MacOS/AngelNotchNativeHost"
ENTITLEMENTS="$PROJECT_DIR/resources/AngelNotch.entitlements"
LOCAL_REQUIREMENTS="$PROJECT_DIR/resources/AngelNotch.local.requirements"

"$PROJECT_DIR/scripts/build-app-bundle.sh"

codesign \
  --force \
  --options runtime \
  --timestamp=none \
  --identifier com.angelnotch.mac.native-host \
  --sign - \
  "$HOST_PATH"
codesign \
  --force \
  --options runtime \
  --timestamp=none \
  --entitlements "$ENTITLEMENTS" \
  --requirements "$LOCAL_REQUIREMENTS" \
  --sign - \
  "$APP_DIR"
codesign --verify --deep --strict --verbose=2 "$APP_DIR"

echo "Built local ad-hoc app: $APP_DIR"
