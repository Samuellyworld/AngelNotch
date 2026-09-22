#!/bin/zsh
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

SWIFT_BUILD_ARGS=(--package-path app --scratch-path .build)
if [[ -n "${ANGELNOTCH_SDK_PATH:-}" ]]; then
  SWIFT_BUILD_ARGS+=(--disable-sandbox --sdk "$ANGELNOTCH_SDK_PATH")
fi
swift build "${SWIFT_BUILD_ARGS[@]}"
"$PROJECT_DIR/scripts/lint-app.sh"
npm --prefix chrome-extension run check
npm --prefix chrome-extension run build
node --check chrome-extension/dist/background.js
node --check chrome-extension/dist/content.js
python3 -m json.tool chrome-extension/manifest.json >/dev/null
xmllint --noout resources/app-icon.svg
plutil -lint resources/info.plist
plutil -lint resources/AngelNotch.entitlements
if [[ "$(
  /usr/libexec/PlistBuddy \
    -c "Print :com.apple.security.personal-information.calendars" \
    resources/AngelNotch.entitlements
)" != "true" ]]; then
  echo "Calendar access requires the calendars code-signing entitlement." >&2
  exit 1
fi
if [[ "$(
  /usr/libexec/PlistBuddy \
    -c "Print :com.apple.security.device.camera" \
    resources/AngelNotch.entitlements
)" != "true" ]]; then
  echo "Face Unlock requires the camera code-signing entitlement." >&2
  exit 1
fi
if [[ ! -s app/sources/angelnotch/resources/faceunlock/ArcFace.mlpackage/Data/com.apple.CoreML/weights/weight.bin ]]; then
  echo "Missing Face Unlock Core ML model weights." >&2
  exit 1
fi
for voice_asset in \
  app/resources/media/focus-complete-idera.mp3 \
  app/resources/media/break-complete-idera.mp3
do
  if [[ ! -s "$voice_asset" ]]; then
    echo "Missing Idera voice asset: $voice_asset" >&2
    exit 1
  fi
  afinfo "$voice_asset" | grep -Eq '^File type ID:[[:space:]]+MPG3$'
done
zsh -n scripts/build-app-bundle.sh
zsh -n scripts/create-dmg.sh
zsh -n scripts/package-app.sh
zsh -n scripts/release-app.sh
zsh -n scripts/lint-app.sh
zsh -n scripts/verify-dmg.sh

echo "AngelNotch validation passed."
