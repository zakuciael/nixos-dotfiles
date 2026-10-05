#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p python3 python3.pkgs.packaging python3.pkgs.xmltodict python3.pkgs.requests
"""Minimal JetBrains binary IDE updater for this overlay.

Based on nixpkgs' pkgs/applications/editors/jetbrains/updater, trimmed to
binary packages living under overlays/jetbrains/packages/*/package.nix.
"""

from __future__ import annotations

import argparse
import json
import sys

from jetbrains_nix_updater.config import UpdaterConfig
from jetbrains_nix_updater.fetcher import VersionFetcher
from jetbrains_nix_updater.ides import get_all_ides, get_single_ide
from jetbrains_nix_updater.update_bin import run_bin_update


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "ide",
        nargs="?",
        help="by-name package attr to update (default: all binary IDEs)",
    )
    parser.add_argument(
        "--repo-root",
        help="dotfiles repo root (auto-detected from cwd if omitted)",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="fetch versions/hashes but do not rewrite package.nix files",
    )
    parser.add_argument(
        "--old-version",
        type=str,
        help="if set with a single ide, exit early when the latest version matches",
    )

    config = UpdaterConfig(parser.parse_args())
    print(f"[i] running jetbrains overlay updater with: {config}")

    with open(config.jetbrains_root / "updater" / "updateInfo.json", encoding="utf-8") as f:
        update_info = json.load(f)

    version_fetcher = VersionFetcher()
    ides = (
        [get_single_ide(update_info, config.packages_root, config.ide)]
        if config.ide is not None
        else list(get_all_ides(update_info, config.packages_root))
    )

    print(f"[.] IDEs to update: {', '.join(ide.name for ide in ides)}")
    success = True
    for ide in ides:
        print(f"[@] updating {ide.name}")
        info = version_fetcher.latest_version_info(ide)
        if info is None:
            success = False
            continue

        if config.old_version is not None and config.old_version == info.version:
            print("[o] version unchanged, stopping")
            raise SystemExit(0)

        print(f"[+] {ide.name}: {info.version} ({info.build_number})")
        success &= run_bin_update(ide, info, config)

    raise SystemExit(0 if success else 1)


if __name__ == "__main__":
    main()
