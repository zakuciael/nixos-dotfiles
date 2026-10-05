from __future__ import annotations

import sys
from dataclasses import dataclass
from urllib import request
from urllib.error import HTTPError

import requests
import xmltodict
from packaging import version

from jetbrains_nix_updater.config import SUPPORTED_SYSTEMS
from jetbrains_nix_updater.ides import Ide
from jetbrains_nix_updater.util import one_or_more

UPDATES_URL = "https://www.jetbrains.com/updates/updates.xml"


@dataclass(slots=True)
class VersionInfo:
    version: str
    build_number: str
    urls: dict[str, str]

    def download_sha256(self, system: str) -> str:
        url = f"{self.urls[system]}.sha256"
        print(f"[.] downloading sha256 for {self.urls[system]}")
        response = requests.get(url, timeout=60)
        response.raise_for_status()
        return response.content.decode("UTF-8").split(" ")[0]


class VersionFetcher:
    _channels: dict | None = None

    @property
    def channels(self) -> dict:
        if self._channels is None:
            self._channels = self.download_channels()
        return self._channels

    def latest_version_info(self, ide: Ide) -> VersionInfo | None:
        if ide.update_info is None:
            print(f"[!] no update info for {ide.name}", file=sys.stderr)
            return None

        channel_name = ide.update_info["channel"]
        channel = self.channels.get(channel_name)
        if channel is None:
            print(f"[!] channel {channel_name} not found for {ide.name}", file=sys.stderr)
            return None

        try:
            build = self.latest_build(channel)
            new_version = build["@version"]
            new_build_number = build.get("@fullNumber", build["@number"])
            version_or_build_number = (
                new_version if "EAP" not in channel["@id"] else new_build_number
            )
            version_number = new_version.split(" ")[0]

            download_urls: dict[str, str] = {}
            for system in SUPPORTED_SYSTEMS:
                template = ide.update_info["urls"].get(system)
                download_url = self.make_url(
                    template, version_or_build_number, version_number
                )
                if download_url is None:
                    print(
                        f"[!] no URL for {ide.name} on {system}; check updateInfo.json",
                        file=sys.stderr,
                    )
                    continue
                download_urls[system] = download_url

            if not download_urls:
                print(f"[!] no download URLs resolved for {ide.name}", file=sys.stderr)
                return None

            return VersionInfo(
                version=new_version,
                build_number=new_build_number,
                urls=download_urls,
            )
        except Exception as exc:
            print(f"[!] fetch failed for {ide.name}: {exc}", file=sys.stderr)
            return None

    @classmethod
    def latest_build(cls, channel: dict) -> dict:
        return max(one_or_more(channel["build"]), key=cls.build_version)

    @staticmethod
    def download_channels() -> dict:
        print(f"[-] checking updates from {UPDATES_URL}")
        response = requests.get(UPDATES_URL, timeout=60)
        response.raise_for_status()
        root = xmltodict.parse(response.text)
        products = root["products"]["product"]
        return {
            channel["@id"]: channel
            for product in products
            if "channel" in product
            for channel in one_or_more(product["channel"])
        }

    @staticmethod
    def build_version(build: dict):
        build_number = build.get("@fullNumber", build["@number"])
        return version.parse(build_number)

    @staticmethod
    def make_url(
        template: str | None, version_or_build_number: str, version_number: str
    ) -> str | None:
        if template is None:
            return None
        release = [str(n) for n in version.parse(version_number).release]
        for length in range(len(release), 0, -1):
            major_minor = ".".join(release[:length])
            url = template.format(
                version=version_or_build_number, versionMajorMinor=major_minor
            )
            try:
                if request.urlopen(url, timeout=30).getcode() == 200:
                    return url
            except HTTPError:
                continue
        return None
