#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq nurl nix
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
# Public GitHub API via curl — avoids requiring `gh` auth for the version check.
version="$(
  curl -fsSL https://api.github.com/repos/pingdotgg/t3code/releases \
    | jq -r '[.[] | select(.prerelease == true and (.tag_name | contains("nightly")))][0].tag_name' \
    | sed 's/^v//'
)"

if [[ -z "$version" || "$version" == "null" ]]; then
  echo "ERROR: could not determine latest t3code nightly version" >&2
  exit 1
fi

has_placeholder_hash=0
if grep -qE 'nightly(SrcHash|PnpmDepsHash|HyprlandCargoHash|KdeCargoHash) = "sha256-AAAA' "$NIX_DRV"; then
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
  }" | grep -oE 'sha256-[A-Za-z0-9+/=]+' | tail -n1
)"

if [[ -z "$src_hash" ]]; then
  echo "ERROR: could not determine src hash for v${version}" >&2
  exit 1
fi

fake_hash="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="

# Use '|' delimiters so base64 '/' in SRI hashes cannot break sed.
sed -i \
  -e "s|nightlyVersion = \"${old_version}\"|nightlyVersion = \"${version}\"|" \
  -e "s|nightlySrcHash = \"sha256-[^\"]*\"|nightlySrcHash = \"${src_hash}\"|" \
  -e "s|nightlyPnpmDepsHash = \"sha256-[^\"]*\"|nightlyPnpmDepsHash = \"${fake_hash}\"|" \
  -e "s|nightlyHyprlandCargoHash = \"sha256-[^\"]*\"|nightlyHyprlandCargoHash = \"${fake_hash}\"|" \
  -e "s|nightlyKdeCargoHash = \"sha256-[^\"]*\"|nightlyKdeCargoHash = \"${fake_hash}\"|" \
  "$NIX_DRV"

build_log="$(mktemp)"
trap 'rm -f "$build_log"' EXIT

prefetch_got_hash() {
  local attr="$1"
  local label="$2"

  # Progress must go to stderr: stdout is captured into the hash variable.
  echo "Prefetching ${label} (this may take a while)..." >&2
  set +e
  nix build --impure --no-link "${REPO_ROOT}#pkgs.${attr}" >"$build_log" 2>&1
  local build_status=$?
  set -e

  if [[ $build_status -eq 0 ]]; then
    echo "ERROR: ${attr} built successfully with the fake hash" >&2
    exit 1
  fi

  local got_hash
  got_hash="$(grep -oE 'got:[[:space:]]+sha256-[A-Za-z0-9+/=]+' "$build_log" | head -n1 | awk '{print $2}' || true)"

  if [[ -z "$got_hash" ]]; then
    cat "$build_log" >&2
    echo "ERROR: failed to extract ${label} hash from nix build output" >&2
    exit 1
  fi

  printf '%s\n' "$got_hash"
}

pnpm_hash="$(prefetch_got_hash "t3code-nightly.unwrapped.pnpmDeps" "pnpmDeps")"
sed -i "s|nightlyPnpmDepsHash = \"${fake_hash}\"|nightlyPnpmDepsHash = \"${pnpm_hash}\"|" "$NIX_DRV"

hyprland_hash="$(prefetch_got_hash "t3-hyprland-snap-shot" "hyprland capture helper cargoHash")"
sed -i "s|nightlyHyprlandCargoHash = \"${fake_hash}\"|nightlyHyprlandCargoHash = \"${hyprland_hash}\"|" "$NIX_DRV"

kde_hash="$(prefetch_got_hash "t3-kde-snap-shot" "kde capture helper cargoHash")"
sed -i "s|nightlyKdeCargoHash = \"${fake_hash}\"|nightlyKdeCargoHash = \"${kde_hash}\"|" "$NIX_DRV"

echo "Updated t3code-nightly to ${version}"
echo "  src hash:       ${src_hash}"
echo "  pnpm hash:      ${pnpm_hash}"
echo "  hyprland cargo: ${hyprland_hash}"
echo "  kde cargo:      ${kde_hash}"
