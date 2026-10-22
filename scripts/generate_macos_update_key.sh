#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
umask 077
swift scripts/generate_macos_update_key.swift
python3 - <<'PY'
from pathlib import Path
import re

public = Path('updates/macos_ed25519.pub').read_text(encoding='utf-8').strip()
plist = Path('macos/Runner/Info.plist')
source, count = re.subn(
    r'(<key>SUPublicEDKey</key>\s*<string>)[^<]*(</string>)',
    lambda match: match[1] + public + match[2],
    plist.read_text(encoding='utf-8'),
)
if count != 1:
    raise SystemExit('Expected one SUPublicEDKey in macOS Info.plist')
plist.write_text(source, encoding='utf-8')
PY
