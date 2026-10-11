#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p python3 brotli

from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import asdict, dataclass, field
from enum import StrEnum
from typing import Optional
import hashlib
import json
import os.path
import subprocess
import tarfile
import tempfile
import urllib.request

# pmovmskb %xmm0, %eax + cmp $0xffff, %eax
KRISP_PATCH_SIGNATURE = b"\x66\x0f\xd7\xc0\x3d\xff\xff\x00\x00"

BRANCHES = ("stable", "ptb", "canary", "development")

# The distributions API rejects requests that don't send a Discord-Updater
# User-Agent, so we can't identify ourselves as Nixpkgs here
DISTRO_USER_AGENT = "Discord-Updater/1"
HTTP_USER_AGENT = "Nixpkgs-Discord-Update-Script/0.0.0"


class Branch(StrEnum):
    STABLE = "stable"
    PTB = "ptb"
    CANARY = "canary"
    DEVELOPMENT = "development"


@dataclass
class DistroRef:
    url: str
    sha256: str


@dataclass
class DistroModule:
    version: int
    url: str
    sha256: str


@dataclass
class DistroSource:
    version: str
    distro: DistroRef
    modules: dict[str, DistroModule] = field(default_factory=dict)
    kind: str = "distro"


def sha256_file_hex(path: str) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def distro_manifest_url(branch: Branch) -> str:
    return (
        "https://updates.discord.com/distributions/app/manifests/latest"
        f"?channel={branch.value}&platform=linux&arch=x64"
    )


def fetch_json(url: str, user_agent: str) -> dict:
    req = urllib.request.Request(url, headers={"User-Agent": user_agent})
    with urllib.request.urlopen(req) as response:
        return json.loads(response.read())


def version_triple_to_str(triple: list) -> str:
    return ".".join(str(x) for x in triple)


def load_existing_sources() -> dict:
    path = os.path.join(os.path.dirname(__file__), "sources.json")
    if not os.path.exists(path):
        return {}
    with open(path) as f:
        return json.load(f)


def existing_entry_matches(existing: Optional[dict], url: str, version) -> Optional[str]:
    """Return the existing sha256 if url (+ optional version) already match."""
    if not existing:
        return None
    if existing.get("url") != url:
        return None
    if version is not None and existing.get("version") != version:
        return None
    h = existing.get("sha256")
    return h if isinstance(h, str) else None


def fetch_distro_source(branch: Branch, existing: dict) -> DistroSource:
    manifest = fetch_json(distro_manifest_url(branch), DISTRO_USER_AGENT)
    host = manifest["full"]
    version = version_triple_to_str(host["host_version"])
    distro_url = host["url"]

    prev = existing.get(f"linux-{branch.value}", {})
    prev_distro = prev.get("distro") if isinstance(prev, dict) else None
    prev_modules = prev.get("modules") if isinstance(prev, dict) else {}

    # Host version lives on the parent source entry, not on distro itself
    reused = (
        existing_entry_matches(prev_distro, distro_url, None)
        if isinstance(prev, dict) and prev.get("version") == version
        else None
    )
    if reused:
        distro_sha256 = reused
        print(f"  [{branch.value}] reusing host sha256 (unchanged URL/version)")
    else:
        distro_sha256 = host["package_sha256"]
        print(f"  [{branch.value}] host sha256 from package_sha256")

    modules: dict[str, DistroModule] = {}
    reused_mods = 0
    for name, mod in manifest["modules"].items():
        full = mod["full"]
        mod_url = full["url"]
        mod_version = full["module_version"]
        prev_mod = prev_modules.get(name) if isinstance(prev_modules, dict) else None
        reused_mod = existing_entry_matches(prev_mod, mod_url, mod_version)
        if reused_mod:
            reused_mods += 1
            mod_sha256 = reused_mod
        else:
            mod_sha256 = full["package_sha256"]
        modules[name] = DistroModule(
            version=mod_version, url=mod_url, sha256=mod_sha256
        )

    print(
        f"  [{branch.value}] {len(modules)} modules"
        f" ({reused_mods} reused, {len(modules) - reused_mods} from package_sha256)"
    )

    return DistroSource(
        version=version,
        distro=DistroRef(url=distro_url, sha256=distro_sha256),
        modules=modules,
    )


def download_to(path: str, url: str) -> None:
    req = urllib.request.Request(url, headers={"user-agent": HTTP_USER_AGENT})
    with urllib.request.urlopen(req) as resp, open(path, "wb") as f:
        while True:
            chunk = resp.read(1024 * 1024)
            if not chunk:
                break
            f.write(chunk)


def extract_krisp_node(distro_path: str, dest_dir: str) -> Optional[str]:
    """Extract discord_krisp.node from a brotli-compressed distro tar."""
    decompressed = os.path.join(dest_dir, "krisp.tar")
    with open(distro_path, "rb") as inp, open(decompressed, "wb") as out:
        subprocess.run(["brotli", "-d"], stdin=inp, stdout=out, check=True)

    with tarfile.open(decompressed, "r:") as tf:
        member = next(
            (m for m in tf.getmembers() if os.path.basename(m.name) == "discord_krisp.node"),
            None,
        )
        if member is None:
            return None
        tf.extract(member, dest_dir)
        return os.path.join(dest_dir, member.name)


def verify_krisp_patchable_from_file(node_path: str) -> bool:
    with open(node_path, "rb") as f:
        data = f.read()

    if data[:4] != b"\x7fELF":
        print("  WARNING: discord_krisp.node is not an ELF binary")
        return False

    count = data.count(KRISP_PATCH_SIGNATURE)
    if count != 1:
        print(f"  WARNING: found {count} ELF signature matches (expected 1)")
        return False
    print("  Verified: ELF signature pattern found (1 unique match)")
    return True


def verify_and_hash_krisp(url: str) -> Optional[str]:
    """Download Krisp once, verify patchability, return hex sha256 of the archive."""
    with tempfile.TemporaryDirectory() as tmpdir:
        archive_path = os.path.join(tmpdir, "krisp.distro")
        download_to(archive_path, url)
        node_path = extract_krisp_node(archive_path, tmpdir)
        if node_path is None:
            print("  WARNING: discord_krisp.node not found in distro")
            return None
        if not verify_krisp_patchable_from_file(node_path):
            return None
        return sha256_file_hex(archive_path)


def process_branch(branch: Branch, existing: dict) -> tuple[str, DistroSource, Optional[str]]:
    """Return (key, source, optional warning about krisp)."""
    print(f"Fetching linux/{branch.value} distro manifest...")
    source = fetch_distro_source(branch, existing)

    krisp = source.modules.get("discord_krisp")
    if krisp is None:
        return (
            f"linux-{branch.value}",
            source,
            f"no discord_krisp module for linux/{branch.value}",
        )

    prev = existing.get(f"linux-{branch.value}", {})
    prev_mod = (
        prev.get("modules", {}).get("discord_krisp") if isinstance(prev, dict) else None
    )
    # Skip verify when content is unchanged. CDN hostnames can rotate while
    # package_sha256 stays the same, so match on version + digest, not URL.
    if (
        isinstance(prev_mod, dict)
        and prev_mod.get("version") == krisp.version
        and prev_mod.get("sha256") == krisp.sha256
    ):
        print(
            f"  [{branch.value}] krisp unchanged"
            f" (v{krisp.version}); skipping patchability download"
        )
        return f"linux-{branch.value}", source, None

    print(
        f"  [{branch.value}] verifying krisp patchability"
        f" (v{krisp.version}, single download)..."
    )
    local_sha256 = verify_and_hash_krisp(krisp.url)
    if local_sha256 is None:
        return (
            f"linux-{branch.value}",
            source,
            f"krisp for linux/{branch.value} is NOT patchable",
        )

    if local_sha256 != krisp.sha256:
        print(
            f"  [{branch.value}] WARNING: local krisp sha256 differs from"
            f" package_sha256; using local sha256"
        )
        krisp.sha256 = local_sha256
    else:
        print(f"  [{branch.value}] krisp sha256 matches package_sha256")

    return f"linux-{branch.value}", source, None


def main():
    existing = load_existing_sources()
    branches = [Branch(b) for b in BRANCHES]
    sources: dict = {}
    warnings: list[str] = []

    with ThreadPoolExecutor(max_workers=len(branches)) as pool:
        futures = [pool.submit(process_branch, branch, existing) for branch in branches]
        for fut in as_completed(futures):
            key, source, warning = fut.result()
            sources[key] = asdict(source)
            if warning:
                warnings.append(warning)
                print(f"  WARNING: {warning}")

    out_path = os.path.join(os.path.dirname(__file__), "sources.json")
    with open(out_path, "w") as f:
        json.dump(sources, f, indent=2, sort_keys=True)
        f.write("\n")

    print(f"Wrote {len(sources)} linux sources to {out_path}")
    if warnings:
        print(f"{len(warnings)} warning(s) during update")


if __name__ == "__main__":
    main()
