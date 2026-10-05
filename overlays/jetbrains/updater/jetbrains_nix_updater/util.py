from __future__ import annotations

import subprocess
import sys
from pathlib import Path
from typing import Iterable

from jetbrains_nix_updater.config import UpdaterConfig


def run_command(cmd: list[str], **kwargs) -> str:
    result = subprocess.run(cmd, capture_output=True, check=True, text=True, **kwargs)
    return result.stdout.strip()


def convert_hash_to_sri(digest: str) -> str:
    return run_command(["nix-hash", "--to-sri", "--type", "sha256", digest])


def one_or_more(x):
    return x if isinstance(x, list) else [x]


def replace_blocks(
    config: UpdaterConfig, file: Path, blocks: Iterable[tuple[str, str]]
) -> None:
    """Replace `# update-script-start/end: NAME` blocks, then format with nixfmt."""
    lines = file.read_text(encoding="utf-8").splitlines(keepends=True)

    if config.dry_run:
        print(f"[D] --dry-run: not modifying {file}", file=sys.stderr)
        return

    for name, block in blocks:
        old_lines = lines
        lines = []
        found_start = False
        found_end = False
        for line in old_lines:
            if not found_start and line.lstrip().startswith(
                f"# update-script-start: {name}"
            ):
                found_start = True
                lines.append(line)
            elif found_start and not found_end and line.lstrip().startswith(
                f"# update-script-end: {name}"
            ):
                for replacement_line in block.splitlines(True):
                    if replacement_line.strip() == "":
                        continue
                    lines.append(replacement_line)
                found_end = True
                lines.append(line)
            elif not found_start or found_end:
                lines.append(line)
        if not found_start or not found_end:
            raise Exception(f"missing start/end markers for `{name}` in `{file}`")

    file.write_text("".join(lines), encoding="utf-8")
    run_command(["nixfmt", str(file.absolute())])
