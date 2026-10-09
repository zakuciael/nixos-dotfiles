#! /usr/bin/env nix-shell
#! nix-shell -i bash -p gnused nix nodejs
# shellcheck shell=bash
set -euo pipefail

ROOT="$(dirname "$(readlink -f "$0")")"
cd "$ROOT"

version="$(npm view @withgraphite/graphite-cli version)"
old_version="$(grep -oP 'version = "\K[^"]+' default.nix | head -n1)"

if [[ "${UPDATE_NIX_OLD_VERSION:-$old_version}" == "$version" ]]; then
  echo "Already up to date!"
  exit 0
fi

sed -i "s#version = \"${old_version}\"#version = \"${version}\"#" default.nix

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

# npm platform suffix → Nixpkgs system attr used in default.nix hash map
declare -A systems=(
  [linux-x64]=x86_64-linux
  [linux-arm64]=aarch64-linux
  [darwin-arm64]=aarch64-darwin
)

for platform in "${!systems[@]}"; do
  (
    url="https://registry.npmjs.org/@withgraphite/graphite-cli-${platform}/-/graphite-cli-${platform}-${version}.tgz"
    sha256="$(nix-prefetch-url "$url")"
    nix-hash --to-sri --type sha256 "$sha256" >"$tmpdir/$platform"
  ) &
done
wait

for platform in "${!systems[@]}"; do
  system="${systems[$platform]}"
  hash="$(cat "$tmpdir/$platform")"
  sed -i "/${system} = \"sha256-/s#\"sha256-[^\"]*\"#\"${hash}\"#" default.nix
done

echo "Updated graphite-cli to ${version}"
