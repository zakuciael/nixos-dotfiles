from __future__ import annotations

import dataclasses
import os
from pathlib import Path

SUPPORTED_SYSTEMS = ["x86_64-linux", "aarch64-linux", "aarch64-darwin"]


def find_repo_root(current_path: Path) -> Path:
    if (current_path / "flake.nix").exists() and (current_path / "overlays").is_dir():
        return current_path
    parent = current_path.parent
    if parent == current_path:
        raise Exception("repo root not found; pass --repo-root")
    return find_repo_root(parent)


@dataclasses.dataclass(slots=True)
class UpdaterConfig:
    repo_root: Path
    jetbrains_root: Path
    packages_root: Path
    ide: str | None
    old_version: str | None
    dry_run: bool

    def __init__(self, argparse_result):
        self.repo_root = (
            Path(argparse_result.repo_root)
            if argparse_result.repo_root is not None
            else find_repo_root(Path.cwd())
        )
        self.jetbrains_root = self.repo_root / "overlays" / "jetbrains"
        self.packages_root = self.jetbrains_root / "packages"
        self.ide = argparse_result.ide or os.environ.get("UPDATE_NIX_PNAME")
        self.old_version = argparse_result.old_version or os.environ.get(
            "UPDATE_NIX_OLD_VERSION"
        )
        self.dry_run = argparse_result.dry_run
