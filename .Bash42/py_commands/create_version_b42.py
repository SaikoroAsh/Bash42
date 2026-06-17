#!/usr/bin/env python3

from pathlib import Path
from typing import Any

import sys
import os
import shutil

from utils import (
    parse_version,
    load_json,
    save_json,
    sha256_file
)


INSTALL_PATH = Path(__file__).parent.parent


def ask_version(current: str) -> tuple[int, int, int]:
    version = parse_version(current)
    choices: list[str] = [
        f"{version[0]}.{version[1]}.{version[2] + 1}",
        f"{version[0]}.{version[1] + 1}.{version[2]}",
        f"{version[0] + 1}.{version[1]}.{version[2]}"
    ]
    print(f"Current version is v{current}.")
    for i, c in enumerate(choices):
        print(f"{i}) v{c}")
    index: int = -1
    while index not in range(len(choices)):
        default: str = "0"
        choice: str = input(f"What is the new version ? [{default}] ")
        try:
            index = int(choice if choice else default)
            if index not in range(len(choices)):
                raise ValueError()
        except ValueError:
            print(f"Invalid value: {choice}.")
    return parse_version(choices[index])


def create_zip(bash_dir: str) -> str:
    zip_name: str = "Bash42"
    return shutil.make_archive(zip_name, "zip", base_dir=bash_dir)


def update_versions(version: str, archive: str, dest_dir: Path) -> None:
    versions_filename = str(dest_dir / "versions.json")
    versions: list[Any] = load_json(versions_filename)
    zip_url: str = "https://github.com/"\
        f"SaikoroAsh/Bash42/releases/download/v{version}/Bash42.zip"
    sha256: str = ""

    with open(archive, "rb") as f:
        sha256 = sha256_file(f)

    changelog: list[str] = []
    line: str = " "
    print()
    while line:
        line = input("Add line to changelog (empty to stop): ")
        if line:
            changelog.append(line)

    versions.insert(0, {
        "version": version,
        "download_url": zip_url,
        "sha256": sha256,
        "changelog": changelog
    })

    save_json(versions, str(dest_dir / "versions.json"))


def main():
    cwd: str = os.getcwd()
    print("Creating new Bash42 version...")
    bash_dir = Path(cwd) / ".Bash42"
    print(str(bash_dir / "config.json"))
    config = load_json(str(bash_dir / "config.json"))
    if not bash_dir.is_dir():
        raise Exception(f"Error: {bash_dir.absolute()} does not exist or is "
              "not a directory.")

    new_version = ask_version(config["version"])

    print("Updating config.json...", end="", flush=True)
    config["version"] = ".".join([str(i) for i in new_version])
    save_json(config, str(bash_dir / "config.json"))
    print(" done.")

    print("Creating archive...", end="", flush=True)
    archive: str = create_zip(bash_dir.name)
    print(" done.")

    print("Updating versions.json...", end="", flush=True)
    update_versions(config["version"], archive, bash_dir.parent)
    print(" done.")

    print(f"Successfully created archive {archive}")
    print("You can now push your changes and create a new release "
          f"with the exact tag [v{config['version']}].")


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(e, file=sys.stderr)
