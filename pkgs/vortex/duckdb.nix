{ fetchurl }:
let
  # Matches @duckdb/node-api version in pnpm-workspace.yaml catalog.
  duckdbVersion = "1.5.1";
  extDir = "duckdb-extensions/v${duckdbVersion}/linux_amd64";
  extRelPath = "${extDir}/level_pivot.duckdb_extension";

  # download-duckdb-extensions.ts skips the download when the file already
  # exists, so we pre-populate it in configurePhase to avoid a network fetch.
  levelPivotExtension = fetchurl {
    url = "https://nexus-mods.github.io/duckdb-level-pivot/current_release/v${duckdbVersion}/linux_amd64/level_pivot.duckdb_extension.gz";
    hash = "sha256-AThZxVr2SnbkegSTpoKhIdKfzh9lyR4863qgYRzLpDo=";
  };
in
{
  # Run before pnpmConfigHook fires (i.e. inside configurePhase, before postConfigure).
  configureScript = ''
    mkdir -p src/main/build/${extDir}
    gunzip -c ${levelPivotExtension} > src/main/build/${extRelPath}
  '';

  # autoPatchelf appends RPATH bytes to the end of every ELF it processes.
  # For the DuckDB extension this shifts the metadata footer past the last
  # 512 bytes, causing DuckDB to reject the file with "metadata at end of
  # file is invalid". The extension only links against libstdc++/libc which
  # are already in-process via libduckdb.so, so it needs no RPATH at all.
  # auto-patchelf.py has no per-file exclusion flag, so the only fix is to
  # move the extension aside before autoPatchelf runs, then restore the
  # pristine copy from the original gz.
  #
  # Requires dontAutoPatchelf = true in the derivation.
  postFixupScript = ''
    _ext=$out/opt/vortex/resources/app.asar.unpacked/${extRelPath}
    _tmp=$(mktemp)
    mv "$_ext" "$_tmp"

    autoPatchelf -- $(for output in $(getAllOutputNames); do
      [ -e "''${!output}" ] || continue
      [ "$output" = debug ] && continue
      echo "''${!output}"
    done)

    gunzip -c ${levelPivotExtension} > "$_ext"
    rm "$_tmp"
  '';
}
