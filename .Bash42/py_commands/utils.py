from typing import Any, IO
from pathlib import Path

import json
import urllib.request
import hashlib

CURRENT_DIR = Path(__file__).parent
CONFIG_FILE = f"{CURRENT_DIR}/../config.json"


def load_json(filename: str) -> Any:
    with open(filename, "r", encoding="utf-8") as f:
        return json.load(f)


def save_json(data: Any, filename: str) -> None:
    with open(filename, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=4)


def load_config() -> Any:
    return load_json(CONFIG_FILE)


def save_config(config: Any) -> None:
    save_json(config, CONFIG_FILE)


def fetch_json(url: str) -> Any:
    with urllib.request.urlopen(url) as response:
        return json.loads(response.read().decode("utf-8"))


def parse_version(version: str) -> tuple[int, int, int]:
    parts: list[int] = [int(part) for part in version.split(".")]

    if len(parts) != 3:
        raise Exception(f"Version number {version} could not be parsed.")

    return (parts[0], parts[1], parts[2])


def sha256_file(file: IO[bytes]) -> str:
    file.seek(0)
    return hashlib.file_digest(file, "sha256").hexdigest()  # pyright: ignore
