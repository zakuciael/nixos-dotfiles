#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p python3

from enum import StrEnum
from typing import List, Tuple
from subprocess import PIPE, Popen
import json
import urllib.request
import re
import os.path
import tempfile
import zipfile

SRC_NAME = "source"

VERSION_REGEX = re.compile(r"\/([\d.]+)\/")

# pmovmskb %xmm0, %eax + cmp $0xffff, %eax
KRISP_PATCH_SIGNATURE = b"\x66\x0f\xd7\xc0\x3d\xff\xff\x00\x00"
# Apple Security framework API used as the anchor for Mach-O call-chain tracing
ANCHOR_IMPORT = b"_SecStaticCodeCreateWithPath"


class Platform(StrEnum):
    LINUX = "linux"
    MACOS = "osx"

    def format_type(self):
        if self.value == Platform.LINUX.value:
            return "tar.gz"
        elif self.value == Platform.MACOS.value:
            return "dmg"
        raise RuntimeError("Invalid platform")


class Branch(StrEnum):
    STABLE = "stable"
    PTB = "ptb"
    CANARY = "canary"
    DEVELOPMENT = "development"


Variant = Tuple[Platform, Branch]


def serialize_variant(variant: Variant) -> str:
    platform, branch = variant
    return f"{platform}-{branch}"


def url_for_variant(variant: Variant) -> str:
    platform, branch = variant

    return f"https://discord.com/api/download/{branch.value}?platform={platform.value}&format={platform.format_type()}"


def fetch_redirect_url(url: str) -> str:
    headers = {"user-agent": "Nixpkgs-Discord-Update-Script/0.0.0"}
    # note that urllib follows redirects by default. So we can extract the final url from the response object
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req) as response:
        return response.url


def version_from_url(url: str) -> str:
    matches = VERSION_REGEX.search(url)
    assert matches, f"Url {url} must contain version number"
    version = matches.group(1)
    assert version
    return version


def prefetch(url: str) -> str:
    with Popen(["nix-prefetch-url", "--name", "source", url], stdout=PIPE) as p:
        assert p.stdout
        b32_hash = p.stdout.read().decode("utf-8").strip()
    with Popen(
        ["nix-hash", "--to-sri", "--type", "sha256", b32_hash], stdout=PIPE
    ) as p:
        assert p.stdout
        sri_hash = p.stdout.read().decode("utf-8").strip()
    return sri_hash


def fetch_krisp_module_url(branch, version, platform):
    """Return the krisp module download URL, or None if unavailable."""
    headers = {"user-agent": "Nixpkgs-Discord-Update-Script/0.0.0"}
    url = f"https://discord.com/api/modules/{branch.value}/versions.json?host_version={version}&platform={platform.value}"
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req) as response:
        modules = json.loads(response.read())

    if "discord_krisp" not in modules:
        return None

    krisp_ver = modules["discord_krisp"]
    download_url = f"https://discord.com/api/modules/{branch.value}/discord_krisp/{krisp_ver}?host_version={version}&platform={platform.value}"
    return fetch_redirect_url(download_url)


def verify_krisp_patchable(url):
    """Download krisp and check it contains the expected patchable target."""
    headers = {"user-agent": "Nixpkgs-Discord-Update-Script/0.0.0"}
    with tempfile.TemporaryDirectory() as tmpdir:
        zip_path = os.path.join(tmpdir, "krisp.zip")
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req) as resp, open(zip_path, "wb") as f:
            f.write(resp.read())

        with zipfile.ZipFile(zip_path) as zf:
            if "discord_krisp.node" not in zf.namelist():
                print("  WARNING: discord_krisp.node not found in zip")
                return False
            zf.extract("discord_krisp.node", tmpdir)

        with open(os.path.join(tmpdir, "discord_krisp.node"), "rb") as f:
            data = f.read()

        # ELF: check for MD5 comparison byte pattern (exactly 1 match)
        if data[:4] == b"\x7fELF":
            count = data.count(KRISP_PATCH_SIGNATURE)
            if count != 1:
                print(f"  WARNING: found {count} ELF signature matches (expected 1)")
                return False
            print("  Verified: ELF signature pattern found (1 unique match)")
            return True

        if ANCHOR_IMPORT in data:
            print("  Verified: Mach-O contains _SecStaticCodeCreateWithPath import")
            return True

        print("  WARNING: no patchable target found")
        return False


def main():
    variants: List[Variant] = [
        (Platform.LINUX, Branch.STABLE),
        (Platform.LINUX, Branch.PTB),
        (Platform.LINUX, Branch.CANARY),
        (Platform.LINUX, Branch.DEVELOPMENT),
        (Platform.MACOS, Branch.STABLE),
        (Platform.MACOS, Branch.PTB),
        (Platform.MACOS, Branch.CANARY),
        (Platform.MACOS, Branch.DEVELOPMENT),
    ]

    sources = {}

    for v in variants:
        url = url_for_variant(v)
        url = fetch_redirect_url(url)
        version = version_from_url(url)
        sri_hash = prefetch(url)

        sources[serialize_variant(v)] = {
            "url": url,
            "version": version,
            "hash": sri_hash,
        }

    for v in variants:
        platform, branch = v
        version = sources[serialize_variant(v)]["version"]
        print(
            f"Fetching krisp module for {platform.value}/{branch.value} (v{version})..."
        )

        try:
            krisp_url = fetch_krisp_module_url(branch, version, platform)
            if krisp_url is None:
                print(
                    f"  No krisp module available for {platform.value}/{branch.value}"
                )
                continue

            if not verify_krisp_patchable(krisp_url):
                print(
                    f"  WARNING: Krisp for {platform.value}/{branch.value} is NOT patchable, skipping"
                )
                continue

            krisp_hash = prefetch(krisp_url)
            sources[f"{serialize_variant(v)}-krisp"] = {
                "url": krisp_url,
                "version": krisp_url
                .rsplit("/", 1)[-1]
                .split("?")[0]
                .replace("discord_krisp-", "")
                .replace(".zip", ""),
                "hash": krisp_hash,
            }
            print(f"  OK: krisp for {platform.value}/{branch.value}")

        except Exception as exc:
            print(f"  Failed to fetch krisp for {platform.value}/{branch.value}: {exc}")

    with open(os.path.join(os.path.dirname(__file__), "sources.json"), "w") as f:
        json.dump(sources, f, indent=2, sort_keys=True)
        f.write("\n")


if __name__ == "__main__":
    main()
