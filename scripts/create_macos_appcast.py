"""Sign a macOS ZIP with Ed25519 and create its architecture-specific feed."""

import argparse
import base64
from datetime import datetime, timezone
from email.utils import format_datetime
import html
import os
from pathlib import Path
import plistlib
import subprocess
from urllib.parse import quote
from xml.etree import ElementTree as ET

from prepare_github_release import app_version, release_info


ROOT = Path(__file__).resolve().parent.parent
PUBLIC_KEY = ROOT / "updates/macos_ed25519.pub"
SPARKLE = "http://www.andymatuschak.org/xml-namespaces/sparkle"
REPOSITORY = "https://github.com/DevMobileAn27/visual-mods-manager"
ET.register_namespace("sparkle", SPARKLE)


def validate_public_key(root=ROOT):
    public = (root / "updates/macos_ed25519.pub").read_text(encoding="utf-8").strip()
    if len(base64.b64decode(public, validate=True)) != 32:
        raise ValueError("Expected a 32-byte macOS Ed25519 public key")
    with (root / "macos/Runner/Info.plist").open("rb") as source:
        info = plistlib.load(source)
    if info.get("SUPublicEDKey") != public:
        raise ValueError("macOS Info.plist must embed the same update public key")
    return public


def sign_archive(archive, private_key):
    if not private_key.strip():
        raise ValueError("Missing MACOS_UPDATE_PRIVATE_KEY secret")
    validate_public_key()
    signed = subprocess.run(
        ["swift", str(ROOT / "scripts/sign_macos_update.swift"), str(archive), str(PUBLIC_KEY)],
        input=private_key.encode("utf-8"), capture_output=True, check=False,
    )
    if signed.returncode:
        raise ValueError(signed.stderr.decode("utf-8", errors="replace").strip())
    signature = signed.stdout.decode("ascii").strip()
    if len(base64.b64decode(signature, validate=True)) != 64:
        raise ValueError("Invalid Ed25519 signature returned by signing tool")
    return signature


def feed_xml(version, tag, title, description, filename, length, signature):
    # Validate before writing a feed; this is the numeric CFBundleVersion used
    # by Sparkle, distinct from the human-readable semantic version.
    version = app_version(f"version: {version}\n")
    if tag != f"v{version}":
        raise ValueError("Tag must match the full app version")
    if length <= 0 or len(base64.b64decode(signature, validate=True)) != 64:
        raise ValueError("Expected a nonempty signed update archive")
    semantic_version, build = version.split("+")
    rss = ET.Element("rss", version="2.0")
    channel = ET.SubElement(rss, "channel")
    ET.SubElement(channel, "title").text = "Visual Mods Manager updates"
    ET.SubElement(channel, "link").text = REPOSITORY
    item = ET.SubElement(channel, "item")
    ET.SubElement(item, "title").text = title
    ET.SubElement(item, "pubDate").text = format_datetime(datetime.now(timezone.utc))
    ET.SubElement(item, "description").text = "<pre>" + html.escape(description) + "</pre>"
    ET.SubElement(item, f"{{{SPARKLE}}}version").text = build
    ET.SubElement(item, f"{{{SPARKLE}}}shortVersionString").text = semantic_version
    ET.SubElement(item, f"{{{SPARKLE}}}minimumSystemVersion").text = "12.0"
    ET.SubElement(item, "enclosure", {
        "url": f"{REPOSITORY}/releases/download/{quote(tag, safe='')}/{quote(filename, safe='')}",
        "length": str(length),
        "type": "application/octet-stream",
        f"{{{SPARKLE}}}os": "macos",
        f"{{{SPARKLE}}}version": build,
        f"{{{SPARKLE}}}shortVersionString": semantic_version,
        f"{{{SPARKLE}}}edSignature": signature,
    })
    ET.indent(rss)
    return ET.tostring(rss, encoding="utf-8", xml_declaration=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--arch", required=True, choices=("arm64", "x86_64"))
    parser.add_argument("--archive", required=True, type=Path)
    args = parser.parse_args()
    version = app_version((ROOT / "pubspec.yaml").read_text(encoding="utf-8"))
    tag, title, body = release_info(
        (ROOT / "github_release_info.md").read_text(encoding="utf-8"), version,
    )
    expected = f"visual-mods-manager-{version}-macos-{args.arch}.zip"
    if args.archive.name != expected or not args.archive.is_file():
        parser.error(f"Expected archive {expected}")
    signature = sign_archive(args.archive.resolve(), os.environ.get("MACOS_UPDATE_PRIVATE_KEY", ""))
    output = args.archive.parent / f"appcast-macos-{args.arch}.xml"
    output.write_bytes(feed_xml(version, tag, title, body, expected, args.archive.stat().st_size, signature))
    print(f"Signed macOS update feed: {output.name}")


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError) as error:
        raise SystemExit(f"macOS appcast generation failed: {error}") from error
