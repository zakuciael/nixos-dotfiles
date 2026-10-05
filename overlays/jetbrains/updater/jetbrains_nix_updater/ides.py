from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, TypedDict


class UpdateInfo(TypedDict):
    channel: str
    urls: dict[str, str]


@dataclass(slots=True)
class Ide:
    name: str
    drv_path: Path
    update_info: UpdateInfo | None


def package_path(packages_root: Path, name: str) -> Path:
    return packages_root / name / "package.nix"


def get_single_ide(
    update_info: dict[str, UpdateInfo], packages_root: Path, name: str
) -> Ide:
    drv_path = package_path(packages_root, name)
    if not drv_path.exists():
        raise Exception(f"IDE package not found at {drv_path}")
    if name not in update_info:
        raise Exception(f"IDE {name!r} missing from updateInfo.json")
    return Ide(name=name, drv_path=drv_path, update_info=update_info[name])


def get_all_ides(
    update_info: dict[str, UpdateInfo], packages_root: Path
) -> Iterable[Ide]:
    for name in sorted(update_info):
        yield get_single_ide(update_info, packages_root, name)
