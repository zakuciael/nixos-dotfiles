#! /usr/bin/env nix-shell
#! nix-shell -i bash -p nodejs nix prefetch-npm-deps curl jq findutils
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

url="https://registry.npmjs.org/@withgraphite/graphite-cli/-/graphite-cli-${version}.tgz"
src_hash="$(nix store prefetch-file --json --hash-type sha256 "$url" | jq -r .hash)"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

curl -fsSL "$url" | tar xz -C "$tmpdir"
pkgdir="$(find "$tmpdir" -mindepth 1 -maxdepth 1 -type d | head -n1)"

pushd "$pkgdir" >/dev/null
npm install --package-lock-only --ignore-scripts
cp package-lock.json "$ROOT/package-lock.json"
npm_deps_hash="$(prefetch-npm-deps package-lock.json)"
popd >/dev/null

sed -i "s/version = \"${old_version}\"/version = \"${version}\"/" default.nix
sed -i "s#hash = \"sha256-[^\"]*\"#hash = \"${src_hash}\"#" default.nix
sed -i "s#npmDepsHash = \"sha256-[^\"]*\"#npmDepsHash = \"${npm_deps_hash}\"#" default.nix

echo "Updated graphite-cli to ${version}"
