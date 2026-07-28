#!/bin/zsh
set -euo pipefail

if (( $# != 2 )); then
  echo "Usage: ./scripts/verify-dmg.sh DMG_PATH candidate|notarized" >&2
  exit 64
fi

DMG_PATH="$1"
VERIFY_MODE="$2"
WORK_DIR="$(mktemp -d /private/tmp/AngelNotch-dmg-verify.XXXXXX)"
MOUNT_DIR="$WORK_DIR/mount"
COPIED_APP="$WORK_DIR/copied/AngelNotch.app"
MOUNTED=false

cleanup() {
  if [[ "$MOUNTED" == true ]]; then
    hdiutil detach -quiet "$MOUNT_DIR" || true
  fi
  rm -rf -- "$WORK_DIR"
}
trap cleanup EXIT

case "$VERIFY_MODE" in
  candidate|notarized)
    ;;
  *)
    echo "Verification mode must be candidate or notarized." >&2
    exit 64
    ;;
esac

hdiutil verify "$DMG_PATH"
codesign --verify --strict --verbose=2 "$DMG_PATH"

if [[ "$VERIFY_MODE" == notarized ]]; then
  xcrun stapler validate "$DMG_PATH"
  if ! spctl \
    --assess \
    --type open \
    --context context:primary-signature \
    "$DMG_PATH" >/dev/null 2>&1
  then
    echo "Gatekeeper rejected the notarized DMG." >&2
    exit 1
  fi
  echo "Gatekeeper accepted the notarized DMG."
else
  echo "Checking the DMG with Gatekeeper before notarization (rejection is expected)..."
  if spctl \
    --assess \
    --type open \
    --context context:primary-signature \
    "$DMG_PATH" >/dev/null 2>&1
  then
    echo "Gatekeeper accepted the signed DMG candidate."
  else
    echo "Gatekeeper has not accepted the unnotarized DMG candidate."
  fi
fi

mkdir -p "$MOUNT_DIR" "$(dirname "$COPIED_APP")"
hdiutil attach \
  -quiet \
  -readonly \
  -nobrowse \
  -noautoopen \
  -mountpoint "$MOUNT_DIR" \
  "$DMG_PATH"
MOUNTED=true

if [[ ! -L "$MOUNT_DIR/Applications" ]]; then
  echo "The DMG is missing its Applications symlink." >&2
  exit 1
fi
if [[ "$(readlink "$MOUNT_DIR/Applications")" != "/Applications" ]]; then
  echo "The DMG Applications symlink has an unexpected target." >&2
  exit 1
fi

ditto "$MOUNT_DIR/AngelNotch.app" "$COPIED_APP"
codesign --verify --deep --strict --verbose=2 "$COPIED_APP"

for executable in \
  "$COPIED_APP/Contents/MacOS/AngelNotch" \
  "$COPIED_APP/Contents/MacOS/AngelNotchNativeHost"
do
  if LC_ALL=C strings "$executable" \
    | grep -E '/Users/[^/]+/|/home/[^/]+/' >/dev/null
  then
    echo "The DMG contains an executable with a local user path:" >&2
    echo "  $executable" >&2
    exit 1
  fi
done

QUARANTINE_TIME="$(printf '%x' "$(date +%s)")"
xattr -w \
  com.apple.quarantine \
  "0083;$QUARANTINE_TIME;AngelNotchRelease;" \
  "$COPIED_APP"

if [[ "$VERIFY_MODE" == notarized ]]; then
  if ! spctl --assess --type execute "$COPIED_APP" >/dev/null 2>&1; then
    echo "Gatekeeper rejected the app copied from the DMG." >&2
    exit 1
  fi
  echo "The quarantined app copied from the DMG passed Gatekeeper."
else
  echo "Checking the copied app before notarization (rejection is expected)..."
  if spctl --assess --type execute "$COPIED_APP" >/dev/null 2>&1; then
    echo "Gatekeeper accepted the copied app candidate."
  else
    echo "Gatekeeper has not accepted the unnotarized copied app candidate."
  fi
fi

echo "Verified DMG contents and Applications symlink."
