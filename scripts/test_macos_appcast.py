import base64
from pathlib import Path
import plistlib
import tempfile
import unittest
from urllib.parse import unquote
from xml.etree import ElementTree as ET

from create_macos_appcast import ROOT, SPARKLE, feed_xml, sign_archive, validate_public_key


class MacOSAppcastTest(unittest.TestCase):
    def test_each_feed_preserves_full_release_tag_and_numeric_sparkle_build(self):
        # Serialization fixture only; no release file is created by this test.
        signature = base64.b64encode(bytes(range(64))).decode("ascii")
        for arch in ("arm64", "x86_64"):
            filename = f"visual-mods-manager-1.2.0+6-macos-{arch}.zip"
            root = ET.fromstring(feed_xml(
                "1.2.0+6", "v1.2.0+6", "Bản cập nhật", "A & B <example>", filename, 123, signature,
            ))
            item = root.find("channel/item")
            self.assertEqual(item.findtext(f"{{{SPARKLE}}}version"), "6")
            self.assertEqual(item.findtext(f"{{{SPARKLE}}}shortVersionString"), "1.2.0")
            self.assertEqual(item.findtext(f"{{{SPARKLE}}}minimumSystemVersion"), "12.0")
            enclosure = item.find("enclosure")
            self.assertEqual(enclosure.get(f"{{{SPARKLE}}}os"), "macos")
            self.assertEqual(enclosure.get(f"{{{SPARKLE}}}edSignature"), signature)
            self.assertEqual(enclosure.get("length"), "123")
            self.assertTrue(unquote(enclosure.get("url")).endswith(f"/v1.2.0+6/{filename}"))
            self.assertEqual(item.findtext("title"), "Bản cập nhật")
            self.assertIn("A &amp; B &lt;example&gt;", item.findtext("description"))

    def test_rejects_unsigned_empty_archive_and_mismatched_tag(self):
        signature = base64.b64encode(bytes(range(64))).decode("ascii")
        for tag, length, signed in (("v1.1.0+5", 123, signature),
                                    ("v1.2.0+6", 0, signature),
                                    ("v1.2.0+6", 123, "")):
            with self.subTest(tag=tag, length=length), self.assertRaises(ValueError):
                feed_xml("1.2.0+6", tag, "Title", "Notes", "app.zip", length, signed)

    def test_signing_requires_a_secret_before_invoking_swift(self):
        with self.assertRaisesRegex(ValueError, "MACOS_UPDATE_PRIVATE_KEY"):
            sign_archive(Path("unused.zip"), "")

    def test_embedded_public_key_and_sandbox_updater_configuration(self):
        public = validate_public_key()
        self.assertEqual(len(base64.b64decode(public)), 32)
        with (ROOT / "macos/Runner/Info.plist").open("rb") as source:
            info = plistlib.load(source)
        self.assertTrue(info["SUEnableInstallerLauncherService"])
        self.assertTrue(info["SUEnableAutomaticChecks"])
        self.assertFalse(info["SUAutomaticallyUpdate"])
        for name in ("Release", "DebugProfile"):
            with (ROOT / f"macos/Runner/{name}.entitlements").open("rb") as source:
                entitlements = plistlib.load(source)
            self.assertTrue(entitlements["com.apple.security.app-sandbox"])
            self.assertTrue(entitlements["com.apple.security.network.client"])
            self.assertEqual(entitlements["com.apple.security.temporary-exception.mach-lookup.global-name"], [
                "$(PRODUCT_BUNDLE_IDENTIFIER)-spks", "$(PRODUCT_BUNDLE_IDENTIFIER)-spki",
            ])

    def test_public_key_must_match_the_app(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            (root / "updates").mkdir()
            (root / "macos/Runner").mkdir(parents=True)
            (root / "updates/macos_ed25519.pub").write_text(base64.b64encode(bytes(32)).decode("ascii"))
            with (root / "macos/Runner/Info.plist").open("wb") as source:
                plistlib.dump({"SUPublicEDKey": "different-key"}, source)
            with self.assertRaisesRegex(ValueError, "same update public key"):
                validate_public_key(root)


if __name__ == "__main__":
    unittest.main()
