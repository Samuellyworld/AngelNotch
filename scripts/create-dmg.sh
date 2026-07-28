#!/bin/zsh
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$PROJECT_DIR/dist/.build/AngelNotch.app"
ICON_PATH="$PROJECT_DIR/resources/app-icon.icns"

if (( $# != 2 )); then
  echo "Usage: ./scripts/create-dmg.sh OUTPUT_PATH VOLUME_NAME" >&2
  exit 64
fi

OUTPUT_PATH="$1"
VOLUME_NAME="$2"
WORK_DIR="$(mktemp -d /private/tmp/AngelNotch-dmg.XXXXXX)"
STAGING_DIR="$WORK_DIR/root"
MOUNT_DIR="$WORK_DIR/mount"
READ_WRITE_DMG="$WORK_DIR/AngelNotch-read-write.dmg"
MOUNTED=false

cleanup() {
  if [[ "$MOUNTED" == true ]]; then
    hdiutil detach -quiet "$MOUNT_DIR" || true
  fi
  rm -rf -- "$WORK_DIR"
}
trap cleanup EXIT

if [[ ! -d "$APP_DIR" ]]; then
  echo "Missing app bundle: $APP_DIR" >&2
  exit 1
fi

mkdir -p "$STAGING_DIR" "$MOUNT_DIR" "$(dirname "$OUTPUT_PATH")"
ditto "$APP_DIR" "$STAGING_DIR/AngelNotch.app"
ln -s /Applications "$STAGING_DIR/Applications"

# Give the mounted volume a branded icon without relying on third-party tools.
install -m 644 "$ICON_PATH" "$STAGING_DIR/.VolumeIcon.icns"
"$(xcrun -f SetFile)" -a V "$STAGING_DIR/.VolumeIcon.icns"

rm -f -- "$OUTPUT_PATH"
hdiutil create \
  -quiet \
  -srcfolder "$STAGING_DIR" \
  -volname "$VOLUME_NAME" \
  -fs HFS+ \
  -format UDRW \
  "$READ_WRITE_DMG"
hdiutil attach \
  -quiet \
  -readwrite \
  -nobrowse \
  -noautoopen \
  -mountpoint "$MOUNT_DIR" \
  "$READ_WRITE_DMG"
MOUNTED=true
"$(xcrun -f SetFile)" -a C "$MOUNT_DIR"
hdiutil detach -quiet "$MOUNT_DIR"
MOUNTED=false

hdiutil convert \
  -quiet \
  "$READ_WRITE_DMG" \
  -format UDZO \
  -imagekey zlib-level=9 \
  -o "$OUTPUT_PATH"
hdiutil verify "$OUTPUT_PATH"

echo "Created disk image: $OUTPUT_PATH"
