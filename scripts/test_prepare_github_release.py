import os
from pathlib import Path
import subprocess
import tempfile
import unittest

from prepare_github_release import app_version, release_info, version_increased


METADATA = """---
tag: v{version}
title: Visual Mods Manager {version}
---
Cập nhật nhân vật và trang phục.
"""


class ReleaseMetadataTest(unittest.TestCase):
    def test_full_version_required_and_windows_limits(self):
        self.assertEqual(app_version("version: 1.2.0+6\n"), "1.2.0+6")
        for source in ("version: 1.2.0", "version: 1.2.0-beta+6", "version: 1.2.0+65536",
                       "version: 1.2.0+6\nversion: 1.2.0+7"):
            with self.subTest(source=source), self.assertRaises(ValueError):
                app_version(source)

    def test_detects_semantic_and_build_only_updates(self):
        self.assertTrue(version_increased("1.2.0+6", "1.1.0+5"))
        self.assertTrue(version_increased("1.2.0+7", "1.2.0+6"))
        self.assertFalse(version_increased("1.2.0+6", "1.2.0+6"))
        for current in ("1.1.0+7", "1.2.0+5", "1.3.0+6"):
            with self.subTest(current=current), self.assertRaises(ValueError):
                version_increased(current, "1.2.0+6")

    def test_metadata_tracks_pubspec_without_another_version_edit(self):
        tag, title, body = release_info(METADATA, "1.2.0+6")
        self.assertEqual(tag, "v1.2.0+6")
        self.assertEqual(title, "Visual Mods Manager 1.2.0+6")
        self.assertIn("trang phục", body)
        for source in (METADATA.replace("v{version}", "v1.1.0+5"),
                       METADATA.replace("title:", "extra:"),
                       METADATA.replace("---\nCập", "title: duplicate\n---\nCập"),
                       "---\ntag: v{version}\ntitle: App\n---\n"):
            with self.subTest(source=source), self.assertRaises(ValueError):
                release_info(source, "1.2.0+6")


class ReleaseIntegrationTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.script = Path(__file__).with_name("prepare_github_release.py").resolve()
        self.git("init")
        self.write_version("1.1.0+5")
        (self.root / "github_release_info.md").write_text(METADATA, encoding="utf-8")
        self.git("add", ".")
        self.git("-c", "user.name=Test", "-c", "user.email=test@example.invalid",
                 "commit", "-m", "Initial")
        self.before = self.git("rev-parse", "HEAD")
        self.write_version("1.2.0+6")
        self.git("add", ".")
        self.git("-c", "user.name=Test", "-c", "user.email=test@example.invalid",
                 "commit", "-m", "Version")
        self.commit = self.git("rev-parse", "HEAD")

    def git(self, *args):
        return subprocess.check_output(
            ["git", *args], cwd=self.root, encoding="utf-8", stderr=subprocess.STDOUT,
        ).strip()

    def write_version(self, version):
        (self.root / "pubspec.yaml").write_text(f"version: {version}\n", encoding="utf-8")

    def run_prepare(self, **overrides):
        env = dict(os.environ, GITHUB_REF="refs/heads/main", GITHUB_SHA=self.commit,
                   BEFORE_COMMIT=self.before, GITHUB_OUTPUT=str(self.root / "output"),
                   GITHUB_STEP_SUMMARY=str(self.root / "summary"))
        env.update(overrides)
        return subprocess.run(
            [os.sys.executable, str(self.script)], cwd=self.root, env=env,
            capture_output=True, encoding="utf-8", errors="replace",
        )

    def test_push_outputs_and_unicode_notes(self):
        result = self.run_prepare()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("tag=v1.2.0+6", (self.root / "output").read_text(encoding="utf-8"))
        self.assertIn("trang phục", (self.root / "build/release-notes.md").read_text(encoding="utf-8"))

    def test_dependency_only_push_skips_build(self):
        self.write_version("1.1.0+5")
        result = self.run_prepare()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.root / "output").read_text(), "should_release=false\n")
        self.assertFalse((self.root / "build").exists())

    def test_manual_release_on_main(self):
        self.assertEqual(self.run_prepare(BEFORE_COMMIT="").returncode, 0)

    def test_other_branch_fails_before_outputs(self):
        result = self.run_prepare(GITHUB_REF="refs/heads/feature")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("from main", result.stderr)
        self.assertFalse((self.root / "output").exists())

    def test_tag_cannot_be_moved(self):
        self.git("tag", "v1.2.0+6", self.before)
        result = self.run_prepare()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("another commit", result.stderr)
        self.assertEqual(self.git("rev-parse", "v1.2.0+6"), self.before)

    def test_existing_tag_on_current_commit_allowed(self):
        self.git("tag", "v1.2.0+6", self.commit)
        self.assertEqual(self.run_prepare().returncode, 0)


if __name__ == "__main__":
    unittest.main()
