#!/bin/zsh
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

swift build --package-path app --scratch-path .build
"$PROJECT_DIR/scripts/lint-app.sh"
npm --prefix chrome-extension run check
npm --prefix chrome-extension run build
node --check chrome-extension/dist/background.js
node --check chrome-extension/dist/content.js
python3 -m json.tool chrome-extension/manifest.json >/dev/null
xmllint --noout resources/app-icon.svg
plutil -lint resources/info.plist
plutil -lint resources/AngelNotch.entitlements
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
