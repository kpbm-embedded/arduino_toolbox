#!/usr/bin/env python3
"""Core facts for arduino-box (32_13_arduino) that need JSON parsing.

Called by lib/arduino.bash, never by hand:
  arduino_cores.py installed-version --core esp32:esp32 < "$(arduino-cli core list --json)"
  arduino_cores.py download-size --data install/arduino15 --package esp32 --downloads cache/arduino-downloads/packages
Prints one value (empty / 0 when unknown) and exits 0; exit 2 on bad arguments (argparse).
Standard library only.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


def installed_version(core_list_json: str, core: str) -> str:
    """Version of `core` in `arduino-cli core list --json` output, or '' if absent/unparsable."""
    try:
        data = json.loads(core_list_json)
    except json.JSONDecodeError:
        return ""
    for platform in data.get("platforms", []):
        if platform.get("id") == core:
            return str(platform.get("installed_version", ""))
    return ""


def archive_names(data_dir: Path, package: str) -> set[str]:
    """Archive file names of every platform and tool that `package` lists in the package indexes."""
    names: set[str] = set()
    for index in data_dir.glob("package_*index.json"):
        try:
            content = json.loads(index.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            continue
        for pkg in content.get("packages", []):
            if pkg.get("name") != package:
                continue
            for platform in pkg.get("platforms", []):
                names.add(platform.get("archiveFileName", ""))
            for tool in pkg.get("tools", []):
                for system in tool.get("systems", []):
                    names.add(system.get("archiveFileName", ""))
    names.discard("")
    return names


def download_size(data_dir: Path, package: str, downloads_dir: Path) -> int:
    """Bytes in `downloads_dir` that belong to `package` (its cores and tools)."""
    if not downloads_dir.is_dir():
        return 0
    wanted = archive_names(data_dir, package)
    return sum(f.stat().st_size for f in downloads_dir.iterdir() if f.is_file() and f.name in wanted)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    sub = parser.add_subparsers(dest="command", required=True)
    p_inst = sub.add_parser("installed-version", help="read `arduino-cli core list --json` on stdin, print one core's version")
    p_inst.add_argument("--core", required=True, help="core id, e.g. esp32:esp32")
    p_size = sub.add_parser("download-size", help="print the bytes of a package's archives in the downloads dir")
    p_size.add_argument("--data", required=True, type=Path, help="arduino-cli data dir (holds package_*index.json)")
    p_size.add_argument("--package", required=True, help="package name, e.g. esp32 (the part before ':')")
    p_size.add_argument("--downloads", required=True, type=Path, help="downloads dir with the archives (…/packages)")
    args = parser.parse_args(argv)
    if args.command == "installed-version":
        print(installed_version(sys.stdin.read(), args.core))
    else:
        print(download_size(args.data, args.package, args.downloads))
    return 0


if __name__ == "__main__":
    sys.exit(main())
