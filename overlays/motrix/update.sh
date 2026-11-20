#! /usr/bin/env nix-shell
#! nix-shell -i bash -p curl jq nix gnused python3
# shellcheck shell=bash
set -euo pipefail

ROOT="$(dirname "$(readlink -f "$0")")"
NIX_DRV="$ROOT/package.nix"
REPO_ROOT="$(git -C "$ROOT" rev-parse --show-toplevel)"

if [[ ! -f "$NIX_DRV" ]]; then
  echo "ERROR: cannot find package.nix in $ROOT" >&2
  exit 1
fi

# Stable channel: GitHub "latest" (non-prerelease), matching
# https://motrix.app/download/?channel=stable
version="$(
  curl -fsSL https://api.github.com/repos/agalwood/Motrix/releases/latest \
    | jq -r '.tag_name' \
    | sed 's/^v//'
)"

if [[ -z "$version" || "$version" == "null" ]]; then
  echo "ERROR: could not determine latest stable Motrix version" >&2
  exit 1
fi

old_version="$(grep -oP '^  version = "\K[^"]+' "$NIX_DRV" | head -n1)"

has_placeholder_hash=0
if grep -qE '(hash|cargoHash) = "sha256-AAAA' "$NIX_DRV"; then
  has_placeholder_hash=1
fi

if [[ "${UPDATE_NIX_OLD_VERSION:-$old_version}" == "$version" && "$has_placeholder_hash" -eq 0 ]]; then
  echo "Already up to date!"
  exit 0
fi

echo "Updating motrix: ${old_version} -> ${version}"

fake_hash="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="

sed -i \
  -e "s|^  version = \"${old_version}\"|  version = \"${version}\"|" \
  -e "s|hash = \"sha256-[^\"]*\";|hash = \"${fake_hash}\";|g" \
  -e "s|cargoHash = \"sha256-[^\"]*\";|cargoHash = \"${fake_hash}\";|g" \
  "$NIX_DRV"

build_log="$(mktemp)"
trap 'rm -f "$build_log"' EXIT

pkgs_expr() {
  local attr="$1"
  cat <<EOF
let
  flakeInputs = builtins.getFlake "git+file://${REPO_ROOT}";
  system = "x86_64-linux";
  pkgs = import flakeInputs.inputs.nixpkgs {
    inherit system;
    config.allowUnfree = true;
    overlays = [
      (final: prev: {
        motrix = final.callPackage ${NIX_DRV} { };
      })
    ];
  };
in pkgs.${attr}
EOF
}

prefetch_got_hash() {
  local attr="$1"
  local label="$2"

  echo "Prefetching ${label} (this may take a while)..." >&2
  set +e
  nix build --impure --no-link --expr "$(pkgs_expr "$attr")" >"$build_log" 2>&1
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

replace_first() {
  local pattern="$1"
  local replacement="$2"
  python3 - "$NIX_DRV" "$pattern" "$replacement" <<'PY'
import pathlib, sys
path = pathlib.Path(sys.argv[1])
pattern, replacement = sys.argv[2], sys.argv[3]
text = path.read_text()
idx = text.find(pattern)
if idx < 0:
    raise SystemExit(f"pattern not found: {pattern}")
path.write_text(text[:idx] + replacement + text[idx + len(pattern):])
PY
}

src_hash="$(prefetch_got_hash "motrix.src" "src")"
replace_first "hash = \"${fake_hash}\";" "hash = \"${src_hash}\";"

src_store="$(
  nix build --impure --no-link --print-out-paths --expr "$(pkgs_expr "motrix.src")"
)"

engine_tag="$(jq -r '.tag' "$src_store/scripts/engine.lock.json")"
engine_ver="${engine_tag#v}"
sed -i "s|engineVersion = \"[^\"]*\"|engineVersion = \"${engine_ver}\"|" "$NIX_DRV"

hex_to_sri() {
  nix-hash --to-sri --type sha256 "$1"
}

engine_x64="$(hex_to_sri "$(jq -r '.assets["linux-x64"].archiveSha256' "$src_store/scripts/engine.lock.json")")"
engine_arm64="$(hex_to_sri "$(jq -r '.assets["linux-arm64"].archiveSha256' "$src_store/scripts/engine.lock.json")")"

# Engine hashes live in an attrset keyed by arch; rewrite those two lines only.
sed -i \
  -e "/engine = fetchurl/,/};/ s|x64 = \"sha256-[^\"]*\"|x64 = \"${engine_x64}\"|" \
  -e "/engine = fetchurl/,/};/ s|arm64 = \"sha256-[^\"]*\"|arm64 = \"${engine_arm64}\"|" \
  "$NIX_DRV"

python3 - "$NIX_DRV" "$src_store/scripts/builtins.lock.json" <<'PY'
import json, re, subprocess, sys, pathlib

drv = pathlib.Path(sys.argv[1])
lock = json.load(open(sys.argv[2]))
repo = lock["repo"]

def sri(hexdigest: str) -> str:
    return subprocess.check_output(
        ["nix-hash", "--to-sri", "--type", "sha256", hexdigest], text=True
    ).strip()

def prefetch(url: str) -> str:
    raw = subprocess.check_output(["nix-prefetch-url", url], text=True).strip().splitlines()[-1]
    return subprocess.check_output(
        ["nix-hash", "--to-sri", "--type", "sha256", raw], text=True
    ).strip()

entries = []
for _plugin_id, meta in lock["plugins"].items():
    file = meta["file"]
    tag = meta["tag"]
    base = f"https://github.com/{repo}/releases/download/{tag}/{file}"
    content_hash = sri(meta["sha256"])
    sig_hash = prefetch(base + ".sig")
    entries.append(
        f"""    {{
      file = "{file}";
      src = fetchurl {{
        url = "{base}";
        hash = "{content_hash}";
      }};
      sig = fetchurl {{
        url = "{base}.sig";
        hash = "{sig_hash}";
      }};
    }}"""
    )

text = drv.read_text()
pattern = re.compile(r"builtinList = \[[\s\S]*?\];", re.M)
replacement = "builtinList = [\n" + "\n".join(entries) + "\n  ];"
new_text, n = pattern.subn(replacement, text, count=1)
if n != 1:
    raise SystemExit("failed to rewrite builtinList in package.nix")
drv.write_text(new_text)
PY

pnpm_hash="$(prefetch_got_hash "motrix.pnpmDeps" "pnpmDeps")"
replace_first "hash = \"${fake_hash}\";" "hash = \"${pnpm_hash}\";"

native_hash="$(prefetch_got_hash "motrix.nativeHost" "native-host cargoHash")"
replace_first "cargoHash = \"${fake_hash}\";" "cargoHash = \"${native_hash}\";"

finalize_hash="$(prefetch_got_hash "motrix.finalizeFs" "finalize-fs cargoHash")"
replace_first "cargoHash = \"${fake_hash}\";" "cargoHash = \"${finalize_hash}\";"

echo "Updated motrix to ${version}"
echo "  src hash:           ${src_hash}"
echo "  engine:             ${engine_ver}"
echo "  pnpm hash:          ${pnpm_hash}"
echo "  native-host cargo:  ${native_hash}"
echo "  finalize-fs cargo:  ${finalize_hash}"
