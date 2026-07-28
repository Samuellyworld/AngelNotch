#!/bin/zsh
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$PROJECT_DIR/dist/.build/AngelNotch.app"
CONTENTS_DIR="$APP_DIR/Contents"
SWIFT_PACKAGE_DIR="$PROJECT_DIR/app"
SWIFT_BUILD_DIR="$PROJECT_DIR/.build"

cd "$PROJECT_DIR"

# Build products are not installed applications, so keep them in a hidden
# staging directory that Spotlight does not present as a second AngelNotch.
mkdir -p "$PROJECT_DIR/dist/.build"

swift build \
  --package-path "$SWIFT_PACKAGE_DIR" \
  --scratch-path "$SWIFT_BUILD_DIR" \
  -c release

if [[ "$APP_DIR" != "$PROJECT_DIR/dist/.build/AngelNotch.app" ]]; then
  echo "Refusing to replace unexpected app path: $APP_DIR" >&2
  exit 1
fi

rm -rf -- "$APP_DIR"
mkdir -p \
  "$CONTENTS_DIR/MacOS" \
  "$CONTENTS_DIR/Resources/media"
install -m 755 \
  "$SWIFT_BUILD_DIR/release/AngelNotch" \
  "$CONTENTS_DIR/MacOS/AngelNotch"
install -m 755 \
  "$SWIFT_BUILD_DIR/release/AngelNotchNativeHost" \
  "$CONTENTS_DIR/MacOS/AngelNotchNativeHost"
install -m 644 "resources/info.plist" "$CONTENTS_DIR/Info.plist"
install -m 644 \
  "resources/app-icon.icns" \
  "$CONTENTS_DIR/Resources/AngelNotchMark.icns"
install -m 644 \
  app/resources/media/focus-complete-idera.mp3 \
  app/resources/media/break-complete-idera.mp3 \
  "$CONTENTS_DIR/Resources/media/"

for executable in \
  "$CONTENTS_DIR/MacOS/AngelNotch" \
  "$CONTENTS_DIR/MacOS/AngelNotchNativeHost"
do
  strip -x -S "$executable"
  if LC_ALL=C strings "$executable" \
    | grep -E '/Users/[^/]+/|/home/[^/]+/' >/dev/null
  then
    echo "Refusing to package an executable containing a local user path:" >&2
    echo "  $executable" >&2
    exit 1
  fi
done

echo "Assembled unsigned app: $APP_DIR"
