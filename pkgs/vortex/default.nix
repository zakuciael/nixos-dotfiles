{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchurl,
  makeWrapper,
  makeDesktopItem,
  copyDesktopItems,
  writeShellScript,
  electron_39,
  nodejs_22, # npm_config_nodedir — node-gyp ABI must match electron's Node 22
  pnpm_10,
  fetchPnpmDeps,
  pnpmConfigHook,
  python3,
  pkg-config,
  jq,
  libsecret,
  autoPatchelfHook,
  fontconfig,
  lz4,
  zlib,
}:
let
  # Override pnpm to run under Node 22 so the engines.node=22 check passes in
  # both fetchPnpmDeps (FOD) and the main build without disabling engine-strict.
  pnpm = pnpm_10.override { nodejs = nodejs_22; };

  nativeAddons = import ./native-addons.nix { inherit lib; };
  duckdb = import ./duckdb.nix { inherit fetchurl; };

  # Native AOT handles FOMOD without a .NET runtime — probe always succeeds.
  dotnetprobeStub = writeShellScript "dotnetprobe" "exit 0";

  # Glob patterns for cross-platform native modules to strip from output
  stripPatterns = [
    "*-musl"
    "*-arm64*"
    "*-arm-*"
    "*-arm*-*"
    "*-freebsd*"
    "*-android*"
    "*-win32*"
    "*-darwin*"
    "*-ia32*"
    "fsevents"
  ];

  stripFindArgs = lib.concatStringsSep " -o " (map (p: "-name '${p}'") stripPatterns);

  runScript = writeShellScript "run-vortex" ''
    # Only pass --download when a parameter %u is provided (nxm:// links from browser).
    if [ -n "$1" ]; then
      exec vortex --download "$@"
    else
      exec vortex
    fi
  '';
in
stdenv.mkDerivation (finalAttrs: {
  pname = "vortex";
  version = "2.0.2";

  src = fetchFromGitHub {
    owner = "Nexus-Mods";
    repo = "Vortex";
    rev = "v${finalAttrs.version}";
    hash = "sha256-B/B7glpHkVP5sk3vHUaLNsICYZ3eAYw+VZt42VlGwAI=";
    fetchSubmodules = true;
  };

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    pnpm = pnpm;
    fetcherVersion = 3;
    hash = "sha256-WNXhNOmFC/+DS4cXztm5ybgfO3KPyzFPywxksoeSE6I=";
  };

  nativeBuildInputs = [
    nodejs_22
    pnpm
    pnpmConfigHook
    jq
    # node-gyp 9.x (used by some addons) needs distutils, removed in Python 3.12+
    (python3.withPackages (ps: [ ps.setuptools ]))
    pkg-config
    autoPatchelfHook
    copyDesktopItems
    makeWrapper
  ];

  buildInputs = [
    libsecret
    (lib.getLib stdenv.cc.cc)
    fontconfig
    lz4
    zlib
  ];

  # Musl-linked prebuilds ship in the asar but can't be satisfied on glibc
  autoPatchelfIgnoreMissingDeps = [ "libc.musl-x86_64.so.1" ];

  patches = [
    # Two fixes for broken game-path validation on Linux:
    #
    # 1. Case-insensitive stat (statCaseInsensitive): on case-sensitive Linux
    #    filesystems (ext4, btrfs) the requiredFiles declared by a game extension
    #    may differ in casing from what Wine/Proton actually wrote to disk, causing
    #    verifyGamePath to reject a valid game path with ENOENT.
    #    Upstream: https://github.com/Nexus-Mods/Vortex/issues/20439
    #
    # 2. Filter nulls from getGameStores(): EpicGamesLauncher.ts returns `undefined`
    #    on non-Windows platforms and that value propagates into getGameStores().
    #    manualGameStoreSelection iterated the result and accessed .id on the
    #    undefined entry, throwing a TypeError that caused the whole path-browse
    #    flow to silently fail. The fix adds a `.filter(s => s != null)` guard.
    ./fix-browse-path-issues.patch
  ];

  postPatch = ''
    # Patch package.json with jq so each change targets a key by name rather
    # than an exact string value — safe across version bumps.
    tmp=$(mktemp)
    ${lib.getExe jq} '
      # Remove the packageManager field so pnpm does not try to bootstrap
      # itself via corepack (which would attempt a network fetch).
      del(.packageManager) |

      # Remove the preinstall hook ("npx only-allow pnpm") — npx would reach
      # the network to download the tool.
      del(.scripts.preinstall) |

      # Strip the leading typecheck step from the dist script.  The shared/
      # paths build steps that follow are sufficient prerequisites; running
      # tsc validation is not needed for packaging.
      .scripts.dist |= (
        split(" && ") |
        map(select(startswith("pnpm run typecheck") | not)) |
        join(" && ")
      ) |

      # Remove two network-dependent steps from dist:assets:
      #   - tsx invocation: tsx is not in the workspace deps; npx would try to
      #     download it.  The DuckDB extension is pre-populated in
      #     configurePhase so the download is moot anyway.
      #   - dependency-report.mjs: calls `pnpm licenses list` which needs
      #     integrity.json files absent from the extracted offline store.
      #     Non-critical for packaging — modules.json is stubbed to [] below.
      .scripts["dist:assets"] |= (
        split(" && ") |
        map(select(
          (startswith("npx tsx scripts/download-duckdb-extensions") | not) and
          (startswith("node ./scripts/dependency-report.mjs") | not)
        )) |
        join(" && ")
      )
    ' package.json > "$tmp" && mv "$tmp" package.json

    # Remove use-node-version — pnpm would download Node from nodejs.org.
    # npm_config_nodedir in env already points node-gyp at local Electron headers,
    # so disturl is also redundant and can stay in .npmrc without harm.
    sed -i '/^use-node-version=/d' .npmrc
  '';

  env = {
    ELECTRON_SKIP_BINARY_DOWNLOAD = "1";
    VORTEX_SKIP_SUBMODULES = "1";
    VORTEX_SKIP_PREINSTALL = "1";
    npm_config_nodedir = "${nodejs_22}";
    VORTEX_VERSION = finalAttrs.version;
  };

  configurePhase = ''
    runHook preConfigure

    export HOME=$(mktemp -d)

    ${duckdb.configureScript}

    # pnpmConfigHook fires here: it extracts the offline store, sets store-dir,
    # and runs `pnpm install --offline --ignore-scripts --frozen-lockfile`.
    runHook postConfigure

    # Build native addons after pnpm has installed everything
    # (--ignore-scripts skipped their install hooks)
    ${nativeAddons.buildScript}
  '';

  preBuild = ''
    # Prepare electron dist for electron-builder
    cp -r ${electron_39.dist} electron-dist
    chmod -R u+w electron-dist
  '';

  buildPhase = ''
    runHook preBuild

    # Build shared prereqs first (typecheck script would do this, but we skip typecheck)
    pnpm -F @vortex/shared run build
    pnpm -F @vortex/paths run build

    # Dist all workspace packages, extensions, and assets
    pnpm --filter "@vortex/*" -r run dist
    # Some extensions may fail (e.g. collections references generated API code that
    # isn't available in the release tarball). Non-fatal — same pattern as v1.
    pnpm run dist:extensions || true
    pnpm run dist:assets

    # dependency-report.mjs (disabled above) normally generates assets/modules.json
    # before InstallAssets.mjs copies it to dist. Write the stub directly to dist so
    # electron-builder packages it into app.asar.
    echo '[]' > src/main/dist/assets/modules.json

    # Create dist/package.json (resolves catalog: entries and workspace: paths to real paths).
    node src/main/prepare-dist-package.mjs

    # pnpm deploy reads the existing workspace lockfile to resolve exact versions — it does
    # NOT need registry metadata (avoids ERR_PNPM_NO_OFFLINE_META from a fresh install).
    # Pass node-linker=hoisted so ALL transitive deps are flattened into the top-level
    # node_modules/. Without this pnpm uses its isolated linker (default) and only direct
    # deps get a top-level symlink; transitive deps (e.g. @babel/runtime required by
    # i18next) stay only in node_modules/.pnpm/ and are not found by require() at runtime.
    # inject-workspace-packages is passed here (not in .npmrc) to avoid a config/lockfile
    # mismatch that would require patching pnpm-lock.yaml.
    deploy_dir=$(mktemp -d)
    pnpm deploy --filter @vortex/main --prod "$deploy_dir" --ignore-scripts \
      --config.node-linker=hoisted --config.shamefully-hoist=true \
      --config.inject-workspace-packages=true
    mv "$deploy_dir/node_modules" src/main/dist/node_modules

    # Copy compiled native addon build/ dirs into dist node_modules
    ${nativeAddons.copyToDistScript}

    # Run electron-builder from src/main where its config lives
    pushd src/main
    pnpm electron-builder \
      --config ./electron-builder.config.json \
      --publish never \
      --linux dir \
      -c.electronDist=../../electron-dist \
      -c.electronVersion=${electron_39.version}
    popd

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt/vortex
    cp -r dist/linux*-unpacked/resources $out/opt/vortex/

    install -Dm644 assets/images/vortex.png \
      $out/share/icons/hicolor/256x256/apps/vortex.png

    # Install dotnetprobe stub — Native AOT FOMOD doesn't need a .NET runtime
    # at runtime, so the probe always succeeds. Installed directly to
    # app.asar.unpacked so execFile() can find it outside the asar archive.
    install -Dm755 ${dotnetprobeStub} \
      $out/opt/vortex/resources/app.asar.unpacked/assets/dotnetprobe

    makeWrapper ${electron_39}/bin/electron $out/bin/vortex \
      --add-flags $out/opt/vortex/resources/app.asar \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}" \
      --set GTK_USE_PORTAL 0 \
      --set IGNORE_UPDATES yes

    # Strip unused cross-platform native modules
    # maxdepth 2 catches scoped packages like @parcel/watcher-darwin-x64
    find $out/opt/vortex/resources/app.asar.unpacked/node_modules -maxdepth 2 -type d \
      \( ${stripFindArgs} \) \
      -exec rm -rf {} +

    runHook postInstall
  '';

  # See duckdb.nix for why dontAutoPatchelf is needed.
  dontAutoPatchelf = true;

  postFixup = duckdb.postFixupScript;

  desktopItems = [
    (makeDesktopItem {
      name = "com.nexusmods.vortex";
      desktopName = "Vortex";
      comment = "Mod manager from Nexus Mods";
      exec = "${runScript} %u";
      icon = "vortex";
      startupWMClass = "Vortex";
      categories = [ "Game" ];
      mimeTypes = [ "x-scheme-handler/nxm" ];
    })
  ];

  meta = {
    description = "Open-source mod manager from Nexus Mods";
    homepage = "https://www.nexusmods.com/about/vortex/";
    changelog = "https://github.com/Nexus-Mods/Vortex/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ caniko ];
    mainProgram = "vortex";
    platforms = [ "x86_64-linux" ];
  };
})
