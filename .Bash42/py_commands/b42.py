#!/usr/bin/env python3

from typing import Any
import hashlib
import json
import sys
import urllib.request
import urllib.parse
from pathlib import Path


CURRENT_DIR = Path(__file__).parent
CONFIG_FILE = f"{CURRENT_DIR}/../config.json"


def load_config() -> Any:
    with open(CONFIG_FILE, "r", encoding="utf-8") as f:
        return json.load(f)


def fetch_json(url: str) -> Any:
    with urllib.request.urlopen(url) as response:
        return json.loads(response.read().decode("utf-8"))


def parse_version(version: str) -> tuple[int, int, int]:
    parts: list[int] = [int(part) for part in version.split(".")]

    if len(parts) != 3:
        raise Exception(f"Version number {version} could not be parsed.")

    return (parts[0], parts[1], parts[2])


def sha256_file(file_path: str) -> str:
    with open(file_path, "rb") as f:
        return hashlib.file_digest(f, "sha256").hexdigest()


def download_file(url: str, destination: str) -> None:
    with urllib.request.urlopen(url) as response, open(destination, "wb") as f:
        while chunk := response.read(65536):
            if not chunk:
                break
            f.write(chunk)


def download() -> None:
    config = load_config()

    versions_url = config["versions_url"]
    current_version = config["version"]

    versions = fetch_json(versions_url)

    if not versions:
        raise Exception("No version found.")

    latest = versions[0]

    latest_version = latest["version"]

    if parse_version(current_version) >= parse_version(latest_version):
        print(f"Already up to date ({current_version}).")
        return

    print(f"Update available: {current_version} -> {latest_version}")

    download_url: str = latest["download_url"]
    expected_sha256: str = latest["sha256"].lower()

    # Remove this line for release
    download_url = "http://127.0.0.1:8000/Bash42.zip"

    filename = Path(urllib.parse.urlsplit(download_url).path).name

    download_file(download_url, filename)

    actual_sha256 = sha256_file(filename)

    if actual_sha256 != expected_sha256:
        Path(filename).unlink(missing_ok=True)
        raise Exception("sha256 does not match.")

    print(f"Downloaded update to: {filename}")


def install() -> None:
    pass


def main():
    download()
    install()


if __name__ == "__main__":
    try:
        main()
    except Exception:
        print("Unable to update due to an error.", file=sys.stderr)
