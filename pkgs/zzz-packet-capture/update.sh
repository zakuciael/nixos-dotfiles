#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq nix-prefetch-github
# shellcheck shell=bash
set -euo pipefail

ROOT="$(dirname "$(readlink -f "$0")")"
SOURCES="$ROOT/sources.json"
BRANCH="master"

owner="$(jq -r '."zzz-packet-capture".owner' "$SOURCES")"
repo="$(jq -r '."zzz-packet-capture".repo' "$SOURCES")"

echo "Fetching ${BRANCH} tip for ${owner}/${repo}..."
commit="$(curl -fsSL "https://api.github.com/repos/${owner}/${repo}/commits/${BRANCH}")"
rev="$(jq -r '.sha' <<<"$commit")"
date="$(jq -r '.commit.committer.date' <<<"$commit" | cut -c1-10)"
version="0-unstable-${date}"

old_version="$(jq -r '."zzz-packet-capture".version' "$SOURCES")"
old_rev="$(jq -r '."zzz-packet-capture".rev' "$SOURCES")"
if [[ "${UPDATE_NIX_OLD_VERSION:-$old_version}" == "$version" && "$old_rev" == "$rev" ]]; then
  echo "Already up to date at ${BRANCH} (${rev})"
  exit 0
fi

echo "Prefetching ${owner}/${repo}@${rev} (${version})..."
main_json="$(nix-prefetch-github --quiet --json --rev "$rev" "$owner" "$repo")"
main_hash="$(jq -r '.hash' <<<"$main_json")"

echo "Resolving glt submodule for ${rev}..."
glt_rev="$(
  curl -fsSL "https://api.github.com/repos/${owner}/${repo}/contents/glt?ref=${rev}" \
    | jq -r '.sha'
)"
glt_owner="$(jq -r '.glt.owner' "$SOURCES")"
glt_repo="$(jq -r '.glt.repo' "$SOURCES")"

echo "Prefetching ${glt_owner}/${glt_repo}@${glt_rev}..."
glt_json="$(nix-prefetch-github --quiet --json --rev "$glt_rev" "$glt_owner" "$glt_repo")"
glt_hash="$(jq -r '.hash' <<<"$glt_json")"

jq \
  --arg version "$version" \
  --arg rev "$rev" \
  --arg hash "$main_hash" \
  --arg glt_rev "$glt_rev" \
  --arg glt_hash "$glt_hash" \
  '
    ."zzz-packet-capture".version = $version
    | ."zzz-packet-capture".rev = $rev
    | ."zzz-packet-capture".hash = $hash
    | .glt.rev = $glt_rev
    | .glt.hash = $glt_hash
  ' \
  "$SOURCES" >"${SOURCES}.tmp"
mv "${SOURCES}.tmp" "$SOURCES"

echo "Updated zzz-packet-capture to ${version} (${rev})"
echo "Updated glt to ${glt_rev}"
echo "Wrote $SOURCES"
