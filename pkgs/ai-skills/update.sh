#!/usr/bin/env nix-shell
#!nix-shell -i bash -p jq nix-prefetch-github
# shellcheck shell=bash
set -euo pipefail

ROOT="$(dirname "$(readlink -f "$0")")"
SOURCES="$ROOT/sources.json"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

mapfile -t entries < <(jq -r 'to_entries[] | "\(.key)\t\(.value.owner)\t\(.value.repo)"' "$SOURCES")

if [[ ${#entries[@]} -eq 0 ]]; then
  echo "No sources to update in $SOURCES" >&2
  exit 1
fi

pids=()
for entry in "${entries[@]}"; do
  IFS=$'\t' read -r name owner repo <<<"$entry"
  (
    echo "Prefetching ${owner}/${repo} (${name})..."
    nix-prefetch-github --quiet --json "$owner" "$repo" >"$tmpdir/${name}.json"
  ) &
  pids+=("$!")
done

failed=0
for pid in "${pids[@]}"; do
  if ! wait "$pid"; then
    failed=1
  fi
done

if [[ "$failed" -ne 0 ]]; then
  echo "One or more prefetches failed" >&2
  exit 1
fi

updated="$(cat "$SOURCES")"
for entry in "${entries[@]}"; do
  IFS=$'\t' read -r name _owner _repo <<<"$entry"
  prefetch="$tmpdir/${name}.json"
  if [[ ! -f "$prefetch" ]]; then
    echo "Missing prefetch result for ${name}" >&2
    exit 1
  fi

  rev="$(jq -r '.rev' "$prefetch")"
  hash="$(jq -r '.hash' "$prefetch")"
  if [[ -z "$rev" || "$rev" == "null" || -z "$hash" || "$hash" == "null" ]]; then
    echo "Invalid prefetch result for ${name}:" >&2
    cat "$prefetch" >&2
    exit 1
  fi

  updated="$(
    jq --arg name "$name" --arg rev "$rev" --arg hash "$hash" '
      .[$name].rev = $rev | .[$name].hash = $hash
    ' <<<"$updated"
  )"

  echo "Updated ${name}: ${rev}"
done

jq . <<<"$updated" >"$SOURCES"
echo "Wrote $SOURCES"
