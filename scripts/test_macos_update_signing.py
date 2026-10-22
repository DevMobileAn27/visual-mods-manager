import base64
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parent.parent


@unittest.skipUnless(sys.platform == "darwin" and shutil.which("swiftc"), "Requires macOS CryptoKit")
class MacOSSigningTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tools = tempfile.TemporaryDirectory()
        cls.addClassCleanup(cls.tools.cleanup)
        tools = Path(cls.tools.name)
        cls.signer = tools / "sign"
        cls.generator = tools / "generate"
        cls.verifier = tools / "verify"
        verifier_source = tools / "verify.swift"
        verifier_source.write_text('''import CryptoKit
import Foundation
let data = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))
let publicKey = try Curve25519.Signing.PublicKey(rawRepresentation:
    Data(base64Encoded: String(contentsOfFile: CommandLine.arguments[2], encoding: .utf8)
        .trimmingCharacters(in: .whitespacesAndNewlines))!)
let signature = Data(base64Encoded: CommandLine.arguments[3])!
exit(publicKey.isValidSignature(signature, for: data) ? 0 : 1)
''', encoding="utf-8")
        for source, output in ((ROOT / "scripts/sign_macos_update.swift", cls.signer),
                               (ROOT / "scripts/generate_macos_update_key.swift", cls.generator),
                               (verifier_source, cls.verifier)):
            subprocess.run(["swiftc", "-module-cache-path", str(tools / "module-cache"),
                            str(source), "-o", str(output)], capture_output=True, check=True)

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        result = subprocess.run([str(self.generator)], cwd=self.root, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        # These are disposable test keys, not the repository's private key.
        self.private = self.root / ".local-keys/macos-update/ed25519.key"
        self.public = self.root / "updates/macos_ed25519.pub"
        self.archive = self.root / "test.zip"
        self.archive.write_bytes(b"PK\x03\x04Disposable signing fixture\x00\xff")

    def sign(self, key):
        return subprocess.run([str(self.signer), str(self.archive), str(self.public)],
                              input=key, capture_output=True)

    def test_signature_validates_and_modified_archive_is_rejected(self):
        result = self.sign(self.private.read_bytes())
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        signature = result.stdout.decode("ascii").strip()
        self.assertEqual(len(base64.b64decode(signature)), 64)
        command = [str(self.verifier), str(self.archive), str(self.public), signature]
        self.assertEqual(subprocess.run(command, capture_output=True).returncode, 0)
        self.archive.write_bytes(b"tampered update")
        self.assertNotEqual(subprocess.run(command, capture_output=True).returncode, 0)

    def test_rejects_wrong_or_invalid_private_key_without_outputting_it(self):
        for key in (base64.b64encode(bytes(32)), b"invalid-base64", b""):
            with self.subTest(length=len(key)):
                result = self.sign(key)
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(result.stdout, b"")
                if key:
                    self.assertNotIn(key, result.stderr)

    def test_signature_interoperates_with_sparkle_when_its_official_tool_is_available(self):
        sparkle = ROOT / "macos/Pods/Sparkle/bin/sign_update"
        if not sparkle.is_file():
            self.skipTest("Official Sparkle tool not installed")
        # Use only disposable fixture keys to check Sparkle compatibility.
        signed = subprocess.run([str(sparkle), "--ed-key-file", "-", "-p", str(self.archive)],
                                input=self.private.read_bytes() + b"\n", capture_output=True)
        self.assertEqual(signed.returncode, 0, (signed.stderr + signed.stdout).decode())
        verify = [str(self.verifier), str(self.archive), str(self.public), signed.stdout.decode().strip()]
        self.assertEqual(subprocess.run(verify, capture_output=True).returncode, 0)
        signature = self.sign(self.private.read_bytes()).stdout.decode().strip()
        checked = subprocess.run([str(sparkle), "--ed-key-file", "-", "--verify", str(self.archive), signature],
                                 input=self.private.read_bytes() + b"\n", capture_output=True)
        self.assertEqual(checked.returncode, 0, (checked.stderr + checked.stdout).decode())

    def test_provisioning_is_idempotent_and_private_key_is_restricted(self):
        private, public = self.private.read_bytes(), self.public.read_bytes()
        self.assertEqual(subprocess.run([str(self.generator)], cwd=self.root, capture_output=True).returncode, 0)
        self.assertEqual(self.private.read_bytes(), private)
        self.assertEqual(self.public.read_bytes(), public)
        self.assertEqual(os.stat(self.private).st_mode & 0o777, 0o600)

    def test_provisioning_never_rotates_a_published_key_when_private_backup_is_missing(self):
        public = self.public.read_bytes()
        self.private.unlink()
        result = subprocess.run([str(self.generator)], cwd=self.root, capture_output=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(self.private.exists())
        self.assertEqual(self.public.read_bytes(), public)


if __name__ == "__main__":
    unittest.main()
