#!@pythonInterpreter@
"""Deploy pre-patched Krisp module to Discord's user-data directory."""

import hashlib
import json
import os
import shutil
import sys
from pathlib import Path

KRISP_STORE = Path("@krispPath@")
VERSION = "@discordVersion@"
CONFIG_DIR = "@configDirName@"

# Marker file written alongside the deployed krisp to track which nix store
# path it came from. On case-insensitive filesystems (macOS APFS) another
# Discord install can silently overwrite our files, so a content hash alone
# isn't enough
MARKER = ".nix-krisp-source"


def modules_dir():
    if sys.platform == "darwin":
        base = Path.home() / "Library" / "Application Support"
        return base / CONFIG_DIR.replace(" ", "") / VERSION / "modules"
    home = Path(os.environ.get("XDG_CONFIG_HOME") or Path.home() / ".config")
    return home / CONFIG_DIR / VERSION / "modules"


def _file_hash(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 16), b""):
            h.update(chunk)
    return h.hexdigest()


def needs_deploy(dest):
    node = dest / "discord_krisp.node"
    marker = dest / MARKER
    if not node.exists() or not marker.exists():
        return True
    try:
        stored_hash = marker.read_text().strip()
    except OSError:
        return True
    return stored_hash != _file_hash(node)


def main():
    mdir = modules_dir()
    dest = mdir / "discord_krisp"
    manifest = mdir / "installed.json"

    if not needs_deploy(dest):
        print("[Nix] Krisp already deployed")
    else:
        print("[Nix] Deploying pre-patched Krisp module")
        mdir.mkdir(parents=True, exist_ok=True)
        if dest.exists():
            # Fix read-only permissions inherited from the nix store before removing
            for p in dest.rglob("*"):
                p.chmod(0o755 if p.is_dir() else 0o644)
            dest.chmod(0o755)
            shutil.rmtree(dest)
        shutil.copytree(KRISP_STORE, dest)
        dest.chmod(0o755)
        for p in dest.rglob("*"):
            p.chmod(0o755 if p.is_dir() or p.suffix == ".node" else 0o644)
        # Write marker with hash of the deployed binary so we can detect
        # overwrites by other Discord installs (e.g. case-insensitive FS)
        node = dest / "discord_krisp.node"
        (dest / MARKER).write_text(_file_hash(node) + "\n")

    # Register krisp in Discord's module manifest so it recognises the module
    # Skip this on fresh installs (no existing manifest) writing installed.json
    # before Discord bootstraps tricks it into thinking modules are already set up,
    # causing it to skip downloading discord_desktop_core and friends
    if manifest.exists():
        try:
            data = json.loads(manifest.read_text())
        except (json.JSONDecodeError, OSError):
            data = {}
        if data.get("discord_krisp", {}).get("installedVersion") != 1:
            data["discord_krisp"] = {"installedVersion": 1}
            manifest.write_text(json.dumps(data, indent=2))


if __name__ == "__main__":
    main()
