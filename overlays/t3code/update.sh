#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq nix-prefetch-github python3
#shellcheck shell=bash
set -euo pipefail

OWNER="pingdotgg"
REPO="t3code"
FAKE_HASH="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="

cd -- "$(dirname "${BASH_SOURCE[0]}")"
FILE="$(pwd)/default.nix"
REPO_ROOT="$(git -C "$(pwd)" rev-parse --show-toplevel)"

replace_literal() {
  local old="$1" new="$2"
  if [[ "$old" == "$new" ]]; then
    return 0
  fi
  python3 - "$FILE" "$old" "$new" <<'PY'
import pathlib, sys

path = pathlib.Path(sys.argv[1])
old, new = sys.argv[2], sys.argv[3]
text = path.read_text()
if old not in text:
    raise SystemExit(f"error: expected string not found in {path}: {old}")
path.write_text(text.replace(old, new, 1))
PY
}

extract_got_hash() {
  local log="$1"
  # Take the last fixed-output "got:" hash from the build log.
  grep -Eo 'got:[[:space:]]+(sha256-[A-Za-z0-9+/=]+)' "$log" | tail -n1 | awk '{print $2}'
}

build_got_hash() {
  local attr="$1"
  local logfile hash
  logfile="$(mktemp)"
  if nix build --no-link "${REPO_ROOT}#pkgs.${attr}" >"$logfile" 2>&1; then
    echo "error: ${attr} build unexpectedly succeeded while prefetching hash" >&2
    cat "$logfile" >&2
    rm -f "$logfile"
    exit 1
  fi
  hash="$(extract_got_hash "$logfile" || true)"
  rm -f "$logfile"
  if [[ -z "$hash" ]]; then
    echo "error: failed to determine hash for ${attr}" >&2
    exit 1
  fi
  printf '%s\n' "$hash"
}

latest_tag="$(
  curl --silent --show-error --fail \
    --proto '=https' --tlsv1.2 \
    -H "user-agent: nixos-dotfiles overlays/t3code update.sh" \
    "https://api.github.com/repos/${OWNER}/${REPO}/releases/latest" \
    | jq --raw-output --exit-status '.tag_name'
)"
latest_version="${latest_tag#v}"

current_version="$(grep -Po '^\s*version = "\K[^"]+' "$FILE" | head -n1)"
current_src_hash="$(
  awk '
    /src = oldAttrs.src.override/ { in_src = 1 }
    in_src && /hash = "/ {
      if (match($0, /hash = "([^"]+)"/, m)) { print m[1]; exit }
    }
  ' "$FILE"
)"
current_pnpm_hash="$(
  awk '
    /pnpmDeps = oldAttrs.pnpmDeps.override/ { in_pnpm = 1 }
    in_pnpm && /hash = "/ {
      if (match($0, /hash = "([^"]+)"/, m)) { print m[1]; exit }
    }
  ' "$FILE"
)"
current_cargo_hash="$(grep -Po '^\s*cargoHash = "\K[^"]+' "$FILE" | head -n1)"

if [[ -z "$current_version" || -z "$current_src_hash" || -z "$current_pnpm_hash" || -z "$current_cargo_hash" ]]; then
  echo "error: failed to parse current version/hashes from ${FILE}" >&2
  exit 1
fi

if [[ "$latest_version" == "$current_version" ]]; then
  echo "t3code overlay already at ${latest_version}"
  exit 0
fi

echo "Updating t3code overlay: ${current_version} -> ${latest_version}"

src_hash="$(
  nix-prefetch-github "$OWNER" "$REPO" --rev "$latest_tag" \
    | jq --raw-output --exit-status '.hash'
)"

replace_literal "version = \"${current_version}\"" "version = \"${latest_version}\""
replace_literal "$current_src_hash" "$src_hash"
replace_literal "$current_pnpm_hash" "$FAKE_HASH"
replace_literal "$current_cargo_hash" "$FAKE_HASH"

echo "Prefetching pnpmDeps hash..."
pnpm_hash="$(build_got_hash t3code.unwrapped.pnpmDeps)"
replace_literal "$FAKE_HASH" "$pnpm_hash"

echo "Prefetching cargoHash..."
cargo_hash="$(build_got_hash t3code.resourceMonitor.cargoDeps)"
replace_literal "$FAKE_HASH" "$cargo_hash"

echo "Updated overlays/t3code/default.nix to ${latest_version}"
echo "  src:   ${src_hash}"
echo "  pnpm:  ${pnpm_hash}"
echo "  cargo: ${cargo_hash}"
