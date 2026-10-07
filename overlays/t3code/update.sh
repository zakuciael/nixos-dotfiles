#!/usr/bin/env nix-shell
#!nix-shell -i bash -p gh nurl nix
# shellcheck shell=bash
set -euo pipefail

ROOT="$(dirname "$(readlink -f "$0")")"
NIX_DRV="$ROOT/default.nix"
REPO_ROOT="$(git -C "$ROOT" rev-parse --show-toplevel)"

if [[ ! -f "$NIX_DRV" ]]; then
  echo "ERROR: cannot find default.nix in $ROOT" >&2
  exit 1
fi

old_version="$(grep -oP 'nightlyVersion = "\K[^"]+' "$NIX_DRV")"
version="$(
  gh api repos/pingdotgg/t3code/releases \
    --jq '[.[] | select(.prerelease == true and (.tag_name | contains("nightly")))][0].tag_name' \
    | sed 's/^v//'
)"

if [[ -z "$version" || "$version" == "null" ]]; then
  echo "ERROR: could not determine latest t3code nightly version" >&2
  exit 1
fi

has_placeholder_hash=0
if grep -q 'nightlySrcHash = "sha256-AAAA' "$NIX_DRV" || grep -q 'nightlyPnpmDepsHash = "sha256-AAAA' "$NIX_DRV"; then
  has_placeholder_hash=1
fi

if [[ "${UPDATE_NIX_OLD_VERSION:-$old_version}" == "$version" && "$has_placeholder_hash" -eq 0 ]]; then
  echo "Already up to date!"
  exit 0
fi

echo "Updating t3code-nightly: ${old_version} -> ${version}"

src_hash="$(
  nurl --hash --expr "(import <nixpkgs> { }).fetchFromGitHub {
    owner = \"pingdotgg\";
    repo = \"t3code\";
    tag = \"v${version}\";
  }"
)"

fake_hash="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="

sed -i \
  -e "s/nightlyVersion = \"${old_version}\"/nightlyVersion = \"${version}\"/" \
  -e "s#nightlySrcHash = \"sha256-[^\"]*\"#nightlySrcHash = \"${src_hash}\"#" \
  -e "s#nightlyPnpmDepsHash = \"sha256-[^\"]*\"#nightlyPnpmDepsHash = \"${fake_hash}\"#" \
  "$NIX_DRV"

echo "Prefetching pnpmDeps (this may take a while)..."
build_log="$(mktemp)"
trap 'rm -f "$build_log"' EXIT

set +e
nix build --impure --no-link "${REPO_ROOT}#pkgs.t3code-nightly.unwrapped.pnpmDeps" >"$build_log" 2>&1
build_status=$?
set -e

if [[ $build_status -eq 0 ]]; then
  echo "ERROR: pnpmDeps built successfully with the fake hash" >&2
  exit 1
fi

pnpm_hash="$(grep -oE 'got:[[:space:]]+sha256-[A-Za-z0-9+/=]+' "$build_log" | head -n1 | awk '{print $2}' || true)"

if [[ -z "$pnpm_hash" ]]; then
  cat "$build_log" >&2
  echo "ERROR: failed to extract pnpmDeps hash from nix build output" >&2
  exit 1
fi

sed -i "s#nightlyPnpmDepsHash = \"${fake_hash}\"#nightlyPnpmDepsHash = \"${pnpm_hash}\"#" "$NIX_DRV"

echo "Updated t3code-nightly to ${version}"
echo "  src hash:  ${src_hash}"
echo "  pnpm hash: ${pnpm_hash}"
