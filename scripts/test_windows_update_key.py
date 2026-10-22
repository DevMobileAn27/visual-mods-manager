import base64
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

from windows_update_key import decode_private_key, SECRET_NAME


# Format fixtures only: no repository signing key is read or included.
PEM = "-----BEGIN DSA PRIVATE KEY-----\nMAMCAQE=\n-----END DSA PRIVATE KEY-----\n"


class WindowsUpdateKeyTest(unittest.TestCase):
    def test_accepts_raw_pem_and_base64_of_entire_file(self):
        encoded = base64.b64encode(PEM.encode()).decode()
        for value in (PEM, encoded, "\n " + encoded + "\r\n",
                      "\n".join(encoded[i:i+20] for i in range(0, len(encoded), 20)),
                      PEM.replace("\n", "\r\n"), "\ufeff" + PEM):
            with self.subTest(format="PEM" if value.lstrip().startswith("-") else "Base64"):
                self.assertEqual(decode_private_key(value), PEM.encode())
        pkcs8 = PEM.replace("DSA PRIVATE KEY", "PRIVATE KEY")
        self.assertEqual(decode_private_key(pkcs8), pkcs8.encode())

    def test_rejects_invalid_wrong_and_incomplete_secrets_without_echoing_them(self):
        invalid = ["", "not_base64-secret", "C:/secure/key.pem",
                   "-----BEGIN PUBLIC KEY-----\nMAMCAQE=\n-----END PUBLIC KEY-----",
                   PEM.replace("END DSA", "END RSA"), PEM.replace("MAMCAQE=", "%%%%"),
                   PEM.replace("DSA PRIVATE KEY", "ENCRYPTED PRIVATE KEY"),
                   base64.b64encode(b"not a PEM file").decode(),
                   base64.b64encode(b"\xff").decode(), PEM + "unexpected"]
        for value in invalid:
            with self.subTest(length=len(value)), self.assertRaises(ValueError) as caught:
                decode_private_key(value)
            if value:
                self.assertNotIn(value, str(caught.exception))

    def test_cli_checks_without_writing_or_logging_key_and_preserves_existing_file(self):
        script = Path(__file__).with_name("windows_update_key.py").resolve()
        with tempfile.TemporaryDirectory() as folder:
            output = Path(folder) / "private.pem"
            env = dict(os.environ, **{SECRET_NAME: PEM})

            def run(*args):
                return subprocess.run([sys.executable, str(script), *args], env=env,
                                      capture_output=True, text=True)

            self.assertEqual(run("--check").returncode, 0)
            self.assertFalse(output.exists())
            result = run("--output", str(output))
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(result.stdout, "")
            self.assertEqual(output.read_bytes(), PEM.encode())
            self.assertNotEqual(run("--output", str(output)).returncode, 0)
            self.assertEqual(output.read_bytes(), PEM.encode())
            env[SECRET_NAME] = "private-invalid-secret"
            result = run("--check")
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("complete unencrypted PEM", result.stderr)
            self.assertNotIn(env[SECRET_NAME], result.stderr + result.stdout)


if __name__ == "__main__":
    unittest.main()
