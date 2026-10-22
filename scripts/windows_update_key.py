"""Read the existing Windows signing secret without logging its contents."""

import argparse
import base64
import binascii
import os
from pathlib import Path
import re


SECRET_NAME = "WINDOWS_DSA_PRIVATE_KEY_BASE64"
INVALID_SECRET = (
    f"{SECRET_NAME} must contain the complete unencrypted PEM private key "
    "or Base64 of the complete PEM file. Copy the value using docs/windows-release.md."
)


def decode_private_key(value):
    text = value.strip().lstrip("\ufeff")
    if not text:
        raise ValueError(f"Missing {SECRET_NAME}")
    if not text.startswith("-----BEGIN "):
        try:
            encoded = re.sub(r"[\t\r\n ]", "", text)
            text = base64.b64decode(encoded, validate=True).decode("utf-8-sig").strip()
        except (ValueError, binascii.Error, UnicodeError):
            raise ValueError(INVALID_SECRET) from None
    match = re.fullmatch(
        r"-----BEGIN (DSA PRIVATE KEY|PRIVATE KEY)-----\s+"
        r"([A-Za-z0-9+/=\s]+)\s+-----END \1-----", text,
    )
    if not match:
        raise ValueError(INVALID_SECRET)
    try:
        der = base64.b64decode(re.sub(r"\s", "", match[2]), validate=True)
    except (ValueError, binascii.Error):
        raise ValueError(INVALID_SECRET) from None
    if not der:
        raise ValueError(INVALID_SECRET)
    return (text.replace("\r\n", "\n") + "\n").encode("ascii")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    target = parser.add_mutually_exclusive_group(required=True)
    target.add_argument("--check", action="store_true")
    target.add_argument("--output", type=Path)
    args = parser.parse_args()
    try:
        key = decode_private_key(os.environ.get(SECRET_NAME, ""))
        if args.output:
            # Never print the decoded key; openssl verifies it against dsa_pub.pem.
            with args.output.open("xb") as output:
                output.write(key)
    except (ValueError, OSError) as error:
        # Do not echo the secret, traceback or a decoder's input in Actions logs.
        message = str(error) if isinstance(error, ValueError) else "Could not write the temporary Windows signing key"
        raise SystemExit(message) from None


if __name__ == "__main__":
    main()
