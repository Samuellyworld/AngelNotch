#!/bin/zsh
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="$PROJECT_DIR/dist"
APP_DIR="$DIST_DIR/.build/AngelNotch.app"
HOST_PATH="$APP_DIR/Contents/MacOS/AngelNotchNativeHost"
ENTITLEMENTS="$PROJECT_DIR/resources/AngelNotch.entitlements"
INFO_PLIST="$PROJECT_DIR/resources/info.plist"

SIGNING_IDENTITY="${ANGELNOTCH_SIGNING_IDENTITY:-}"
NOTARY_PROFILE="${ANGELNOTCH_NOTARY_PROFILE:-}"
NOTARY_KEYCHAIN="${ANGELNOTCH_NOTARY_KEYCHAIN:-}"
NOTARIZE=false

usage() {
  cat <<'EOF'
Usage: ./scripts/release-app.sh [--notarize]

Without --notarize, builds a Developer ID-signed release candidate and does
not contact Apple's notary service.

With --notarize, submits through the named keychain profile, waits for
acceptance, staples the ticket, validates Gatekeeper, and creates the final DMG.

Environment:
  ANGELNOTCH_SIGNING_IDENTITY  required Developer ID Application identity
  ANGELNOTCH_NOTARY_PROFILE   required with --notarize
  ANGELNOTCH_NOTARY_KEYCHAIN  optional file-based keychain for CI
EOF
}

if (( $# > 1 )); then
  usage >&2
  exit 64
fi

if (( $# == 1 )); then
  case "$1" in
    --notarize)
      NOTARIZE=true
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      exit 64
      ;;
  esac
fi

if [[ -z "$SIGNING_IDENTITY" ]]; then
  echo "Set ANGELNOTCH_SIGNING_IDENTITY before creating a release." >&2
  exit 1
fi
if [[ "$NOTARIZE" == true && -z "$NOTARY_PROFILE" ]]; then
  echo "Set ANGELNOTCH_NOTARY_PROFILE before notarizing a release." >&2
  exit 1
fi

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$INFO_PLIST")"
if [[ ! "$VERSION" =~ '^[0-9]+([.][0-9]+)*([+-][0-9A-Za-z.-]+)?$' ]]; then
  echo "Invalid CFBundleShortVersionString: $VERSION" >&2
  exit 1
fi

AVAILABLE_IDENTITIES="$(security find-identity -v -p codesigning)"
if [[ "$AVAILABLE_IDENTITIES" != *"$SIGNING_IDENTITY"* ]]; then
  echo "The configured Developer ID signing identity is not available." >&2
  exit 1
fi

if [[ "$NOTARIZE" == true ]]; then
  ARTIFACT="$DIST_DIR/AngelNotch-$VERSION-macos.dmg"
  VERIFY_MODE=notarized
else
  ARTIFACT="$DIST_DIR/AngelNotch-$VERSION-macos-signed.dmg"
  VERIFY_MODE=candidate
fi

"$PROJECT_DIR/scripts/build-app-bundle.sh"

echo "Signing nested native messaging helper with Developer ID..."
codesign \
  --force \
  --options runtime \
  --timestamp \
  --identifier com.angelnotch.mac.native-host \
  --sign "$SIGNING_IDENTITY" \
  "$HOST_PATH"

echo "Signing app bundle last with hardened runtime and Apple Events entitlement..."
codesign \
  --force \
  --options runtime \
  --timestamp \
  --entitlements "$ENTITLEMENTS" \
  --sign "$SIGNING_IDENTITY" \
  "$APP_DIR"

echo "Verifying Developer ID signatures..."
codesign --verify --deep --strict --verbose=2 "$APP_DIR"

"$PROJECT_DIR/scripts/create-dmg.sh" \
  "$ARTIFACT" \
  "AngelNotch $VERSION"

echo "Signing the distribution DMG with Developer ID..."
codesign \
  --force \
  --timestamp \
  --identifier com.angelnotch.mac.dmg \
  --sign "$SIGNING_IDENTITY" \
  "$ARTIFACT"

if [[ "$NOTARIZE" == true ]]; then
  # Apple recommends notarizing only the outermost nested container. The
  # service generates tickets for both this DMG and the signed app inside it.

  echo "Submitting to Apple's notary service..."
  NOTARY_CREDENTIALS=(
    --keychain-profile "$NOTARY_PROFILE"
  )
  if [[ -n "$NOTARY_KEYCHAIN" ]]; then
    NOTARY_CREDENTIALS+=(--keychain "$NOTARY_KEYCHAIN")
  fi
  if ! NOTARY_RESULT="$(
    xcrun notarytool submit \
      "$ARTIFACT" \
      "${NOTARY_CREDENTIALS[@]}" \
      --wait \
      --output-format json
  )"; then
    echo "The notarization submission failed." >&2
    exit 1
  fi

  NOTARY_STATUS="$(
    print -r -- "$NOTARY_RESULT" \
      | plutil -extract status raw -o - -
  )"
  if [[ "$NOTARY_STATUS" != "Accepted" ]]; then
    echo "Notarization did not succeed (status: $NOTARY_STATUS)." >&2
    exit 1
  fi
  echo "Apple accepted the notarization submission."

  xcrun stapler staple "$ARTIFACT"
fi

"$PROJECT_DIR/scripts/verify-dmg.sh" "$ARTIFACT" "$VERIFY_MODE"

rm -f -- "$ARTIFACT.sha256"
CHECKSUM="$(shasum -a 256 "$ARTIFACT" | awk '{ print $1 }')"
printf '%s  %s\n' "$CHECKSUM" "$(basename "$ARTIFACT")" > "$ARTIFACT.sha256"

echo "Artifact: $ARTIFACT"
echo "Checksum: $ARTIFACT.sha256"
