#!/usr/bin/env python3

from typing import Any, IO
from pathlib import Path

import os
import sys
import urllib.request
import zipfile
import shutil
import tempfile

from utils import load_config, fetch_json, parse_version, sha256_file


CURRENT_DIR = Path(__file__).parent
INSTALL_PATH = CURRENT_DIR.parent


def download_file(url: str, dest: IO[bytes]) -> None:
    with urllib.request.urlopen(url) as response:
        while chunk := response.read(65536):
            if not chunk:
                break
            dest.write(chunk)


def download(dest: IO[bytes], config: Any) -> bool:
    versions_url = config["versions_url"]
    current_version = config["version"]

    versions = fetch_json(versions_url)

    if not versions:
        raise Exception("No version found.")

    latest = versions[0]

    latest_version = latest["version"]

    if parse_version(current_version) >= parse_version(latest_version):
        print(f"Already up to date ({current_version}).")
        return False

    print(f"Update available: {current_version} -> {latest_version}")

    download_url: str = latest["download_url"]
    expected_sha256: str = latest["sha256"].lower()

    download_file(download_url, dest)

    actual_sha256 = sha256_file(dest)

    if actual_sha256 != expected_sha256:
        dest.close()
        raise Exception("sha256 does not match. "
                        f"(Expected: {expected_sha256}, Got: {actual_sha256}")

    if latest["changelog"]:
        print("Changelog:")
        for line in latest["changelog"]:
            print(f" - {line}")
    else:
        print("No changelog")

    return True


def install(zip_path: str, config: Any) -> None:
    install_dir = Path(os.path.expanduser(INSTALL_PATH))
    install_dir.mkdir(exist_ok=True)

    with (zipfile.ZipFile(zip_path, "r") as z,
          tempfile.TemporaryDirectory() as tmp_dirname):
        tmp_dir = Path(tmp_dirname)
        z.extractall(tmp_dir)

        extracted = list(tmp_dir.iterdir())
        if not extracted:
            raise Exception("ZIP file is empty.")

        source = extracted[0]

        for item in source.iterdir():
            dest = install_dir / item.name
            if dest.exists():
                if dest.is_dir():
                    shutil.rmtree(dest)
                else:
                    dest.unlink()
            shutil.move(str(item), str(dest))

    print("Installation complete.")


def main():
    config = load_config()
    with tempfile.NamedTemporaryFile() as zipfile:
        if download(zipfile, config):
            install(zipfile.name, config)


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"Unable to update due to an error: {e}", file=sys.stderr)
