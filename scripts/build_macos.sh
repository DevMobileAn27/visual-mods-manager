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
test -d "$vmm_app/Contents/Frameworks/Sparkle.framework/Versions/B/XPCServices/Installer.xpc"
python3 - "$vmm_app" <<'PY'
from pathlib import Path
import plistlib
import sys

sys.path.insert(0, 'scripts')
from create_macos_appcast import validate_public_key
from prepare_github_release import app_version

public = validate_public_key()
version, build = app_version(Path('pubspec.yaml').read_text(encoding='utf-8')).split('+')
with (Path(sys.argv[1]) / 'Contents/Info.plist').open('rb') as source:
    info = plistlib.load(source)
if info.get('SUPublicEDKey') != public:
    raise SystemExit('Built app does not embed the macOS update public key')
if info.get('CFBundleVersion') != build or info.get('CFBundleShortVersionString') != version:
    raise SystemExit('Built app version does not match pubspec.yaml')
if not info.get('SUEnableInstallerLauncherService'):
    raise SystemExit('Sparkle installer launcher must be enabled')
PY
