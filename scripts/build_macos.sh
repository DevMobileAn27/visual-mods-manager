#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

# Build an explicit architecture, as in Flutter Network Viewer, to avoid
# Flutter universal-framework lipo verification failures with newer Xcode.
vmm_arch="${1:-$(uname -m)}"
case "$vmm_arch" in
  arm64|x86_64) ;;
  *) echo 'Expected arm64 or x86_64' >&2; exit 1 ;;
esac
flutter build macos --release --config-only
(cd macos && pod install)
xcodebuild -workspace macos/Runner.xcworkspace -scheme Runner \
  -configuration Release -derivedDataPath build/macos \
  -destination "platform=macOS,arch=$vmm_arch" \
  "ARCHS=$vmm_arch" ONLY_ACTIVE_ARCH=YES build

vmm_app='build/macos/Build/Products/Release/Visual Mods Manager.app'
lipo "$vmm_app/Contents/MacOS/Visual Mods Manager" -verify_arch "$vmm_arch"
lipo "$vmm_app/Contents/Frameworks/App.framework/App" -verify_arch "$vmm_arch"
