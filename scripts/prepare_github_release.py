"""Validate release metadata and prepare Actions outputs using only stdlib."""

import os
from pathlib import Path
import re
import subprocess


def app_version(source):
    versions = re.findall(r"^version:\s*(\d+\.\d+\.\d+\+\d+)\s*$", source, re.M)
    if len(versions) != 1:
        raise ValueError("Expected one version: MAJOR.MINOR.PATCH+BUILD")
    if any(int(part) > 65535 for part in re.split(r"[.+]", versions[0])):
        raise ValueError("Windows version components must not exceed 65535")
    return versions[0]


def version_increased(current, previous):
    current_parts = tuple(map(int, re.split(r"[.+]", current)))
    previous_parts = tuple(map(int, re.split(r"[.+]", previous)))
    if current_parts == previous_parts:
        return False
    if current_parts[:3] < previous_parts[:3]:
        raise ValueError(f"Version decreased from {previous} to {current}")
    if current_parts[3] <= previous_parts[3]:
        raise ValueError("Increase the Flutter build number for app updates")
    return True


def release_info(source, version):
    lines = source.splitlines()
    if not lines or lines[0] != "---":
        raise ValueError("github_release_info.md must start with ---")
    try:
        end = lines.index("---", 1)
    except ValueError as error:
        raise ValueError("Missing closing --- in release metadata") from error
    fields = {}
    for line in lines[1:end]:
        key, separator, value = line.partition(":")
        key, value = key.strip(), value.strip()
        if not separator or key not in ("tag", "title") or key in fields or not value:
            raise ValueError("Release metadata requires exactly tag: and title:")
        fields[key] = value.replace("{version}", version)
    if set(fields) != {"tag", "title"}:
        raise ValueError("Both tag: and title: are required")
    if fields["tag"] != f"v{version}":
        raise ValueError(f"Release tag must match v{version}")
    body = "\n".join(lines[end + 1:]).strip()
    if not body:
        raise ValueError("Release description cannot be empty")
    return fields["tag"], fields["title"], body + "\n"


def verify_tag_commit(tag, commit):
    result = subprocess.run(
        ["git", "rev-parse", "--verify", "--quiet", f"refs/tags/{tag}^{{commit}}"],
        capture_output=True, text=True, check=False,
    )
    if result.returncode not in (0, 1):
        raise ValueError(f"Cannot check tag {tag}: {result.stderr.strip()}")
    if result.returncode == 0 and result.stdout.strip() != commit:
        raise ValueError(f"Tag {tag} points to another commit; use a new version")


def main():
    if os.environ.get("GITHUB_REF") != "refs/heads/main":
        raise ValueError("Run release builds from main")
    version = app_version(Path("pubspec.yaml").read_text(encoding="utf-8"))
    before = os.environ.get("BEFORE_COMMIT", "")
    if before and set(before) != {"0"}:
        if not re.fullmatch(r"[0-9a-fA-F]{40}", before):
            raise ValueError("Invalid previous commit")
        previous_source = subprocess.check_output(
            ["git", "show", f"{before}:pubspec.yaml"], encoding="utf-8",
        )
        if not version_increased(version, app_version(previous_source)):
            with open(os.environ["GITHUB_OUTPUT"], "a", encoding="utf-8") as output:
                output.write("should_release=false\n")
            print(f"Version remains {version}; skip release build")
            return
    tag, title, body = release_info(
        Path("github_release_info.md").read_text(encoding="utf-8"), version,
    )
    commit = os.environ["GITHUB_SHA"]
    verify_tag_commit(tag, commit)
    notes = Path("build/release-notes.md")
    notes.parent.mkdir(parents=True, exist_ok=True)
    notes.write_text(body, encoding="utf-8")
    with open(os.environ["GITHUB_OUTPUT"], "a", encoding="utf-8") as output:
        output.write(f"should_release=true\nversion={version}\ntag={tag}\ntitle={title}\n")
    with open(os.environ["GITHUB_STEP_SUMMARY"], "a", encoding="utf-8") as summary:
        summary.write(f"## {tag}\n\nCommit: `{commit}`\n\n")
        summary.write("Build macOS arm64, macOS Intel and Windows x64, then create a draft release.\n")


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, subprocess.CalledProcessError) as error:
        raise SystemExit(f"Release preparation failed: {error}") from error
