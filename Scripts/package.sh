#!/usr/bin/env bash
# Builds a Release archive, embeds the universal dockwizard CLI, and packages DockWizard.app
# into a DMG and zip under dist/. Signs with Developer ID and notarises when credentials are
# present, else ad-hoc.
#
# Usage: Scripts/package.sh [version]
# Env:   CODE_SIGN_IDENTITY  e.g. "Developer ID Application" (default "-" = ad-hoc)
#        DEVELOPMENT_TEAM    Apple team ID (required with Developer ID)
#        ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_PATH   App Store Connect API key for notarytool
set -euo pipefail

cd "$(dirname "$0")/.."
VERSION="${1:-$(git describe --tags --always)}"
VERSION="${VERSION#v}"
DIST="dist"
ARCHIVE="build/DockWizard.xcarchive"
APP="$ARCHIVE/Products/Applications/DockWizard.app"
PACKAGE="Packages/DockWizardKit"
IDENTITY="${CODE_SIGN_IDENTITY:--}"
SIGNED=false
[[ "$IDENTITY" != "-" ]] && SIGNED=true

rm -rf "$DIST" "$ARCHIVE"
mkdir -p "$DIST"

# The CLI ships inside the app so both halves always carry the same version. Universal,
# because a Developer ID build has to run on Intel too.
echo "Building the dockwizard CLI…"
(cd "$PACKAGE" && swift build -c release --product dockwizard --arch arm64 --arch x86_64)
CLI="$PACKAGE/.build/apple/Products/Release/dockwizard"
[[ -f "$CLI" ]] || CLI="$PACKAGE/.build/release/dockwizard"
[[ -f "$CLI" ]] || { echo "Could not find the built dockwizard binary." >&2; exit 1; }

xcodebuild -project DockWizard.xcodeproj -scheme DockWizard -configuration Release \
  -archivePath "$ARCHIVE" \
  MARKETING_VERSION="$VERSION" \
  CURRENT_PROJECT_VERSION="${GITHUB_RUN_NUMBER:-1}" \
  CODE_SIGN_IDENTITY="$IDENTITY" \
  DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM:-}" \
  CODE_SIGN_STYLE=Manual \
  OTHER_CODE_SIGN_FLAGS="--timestamp" \
  archive | { command -v xcbeautify >/dev/null && xcbeautify || cat; }

# Embed after archiving, then re-sign: modifying a bundle invalidates its signature, and an
# unsigned nested binary fails notarisation.
mkdir -p "$APP/Contents/Helpers"
cp "$CLI" "$APP/Contents/Helpers/dockwizard"
SIGN_FLAGS=(--force --sign "$IDENTITY" --options runtime --timestamp)
if ! $SIGNED; then
  SIGN_FLAGS=(--force --sign "$IDENTITY")
fi
codesign "${SIGN_FLAGS[@]}" "$APP/Contents/Helpers/dockwizard"
codesign "${SIGN_FLAGS[@]}" "$APP"

notarize() {
  local path="$1"
  echo "Notarising $(basename "$path")…"
  xcrun notarytool submit "$path" \
    --key "$ASC_KEY_PATH" --key-id "$ASC_KEY_ID" --issuer "$ASC_ISSUER_ID" \
    --wait --timeout 30m
}

CAN_NOTARIZE=false
if $SIGNED; then
  codesign --verify --deep --strict --verbose=2 "$APP"
  if [[ -n "${ASC_KEY_ID:-}" && -n "${ASC_ISSUER_ID:-}" && -f "${ASC_KEY_PATH:-}" ]]; then
    CAN_NOTARIZE=true
    ditto -c -k --keepParent "$APP" "build/notarize.zip"
    notarize "build/notarize.zip"
    xcrun stapler staple "$APP"
  else
    echo "Signed with Developer ID but no App Store Connect key present; skipping notarisation." >&2
  fi
fi

STAGING="build/dmg"
rm -rf "$STAGING"
mkdir -p "$STAGING"
cp -R "$APP" "$STAGING/"
ln -s /Applications "$STAGING/Applications"
DMG="$DIST/DockWizard-$VERSION.dmg"
hdiutil create -volname "DockWizard" -srcfolder "$STAGING" -ov -format UDZO "$DMG" >/dev/null
if $SIGNED; then
  codesign --sign "$IDENTITY" --timestamp "$DMG"
  if $CAN_NOTARIZE; then
    notarize "$DMG"
    xcrun stapler staple "$DMG"
  fi
fi

ditto -c -k --keepParent "$APP" "$DIST/DockWizard-$VERSION.zip"
(cd "$DIST" && shasum -a 256 ./*.dmg ./*.zip > SHA256SUMS.txt)
if $CAN_NOTARIZE; then
  spctl --assess --type open --context context:primary-signature -v "$DMG"
  echo "notarized=true" >> "${GITHUB_OUTPUT:-/dev/null}"
else
  echo "notarized=false" >> "${GITHUB_OUTPUT:-/dev/null}"
fi
echo "Packaged version $VERSION (signed=$SIGNED notarized=$CAN_NOTARIZE):"
ls -la "$DIST"
