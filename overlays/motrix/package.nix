{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchurl,
  fetchPnpmDeps,
  pnpmConfigHook,
  pnpm_12,
  nodejs_22,
  electron_44,
  makeBinaryWrapper,
  copyDesktopItems,
  makeDesktopItem,
  python3,
  pkg-config,
  rustPlatform,
  autoPatchelfHook,
  ffmpeg,
}:

let
  pname = "motrix";
  version = "2.4.1";

  # Upstream currently pins Electron 45.x; nixpkgs for this flake provides 44.x.
  # Match the AUR packaging approach and rebuild native modules against system Electron.
  electron = electron_44;
  pnpm = pnpm_12;
  nodejs = nodejs_22;

  electronArch =
    if stdenv.hostPlatform.parsed.cpu.name == "x86_64" then
      "x64"
    else if stdenv.hostPlatform.parsed.cpu.name == "aarch64" then
      "arm64"
    else
      throw "Unsupported architecture: ${stdenv.hostPlatform.system}";

  src = fetchFromGitHub {
    owner = "agalwood";
    repo = "Motrix";
    tag = "v${version}";
    hash = "sha256-PneNIfJgnTyHq+hV0whTn3s6KPiGQcRk7OJmNBksbEw=";
  };

  # Pinned by scripts/engine.lock.json for this Motrix release.
  engineVersion = "1.37.0-motrix.24";
  engine = fetchurl {
    url = "https://github.com/motrixapp/aria2/releases/download/v${engineVersion}/aria2c-${engineVersion}-linux-${electronArch}.tar.gz";
    hash =
      {
        x64 = "sha256-+Ufuhyv6KU2ViRNQPcRwFAwkfJfMLoO3XRluemutFV4=";
        arm64 = "sha256-rbcsu+smPqxnlTkjCT4W1MklH+86NkiqeUthW2BSebs=";
      }
      .${electronArch};
  };

  builtinList = [
    {
      file = "motrix.filename-template-1.1.1.moext";
      src = fetchurl {
        url = "https://github.com/motrixapp/builtin-plugins/releases/download/motrix.filename-template@1.1.1/motrix.filename-template-1.1.1.moext";
        hash = "sha256-O4jkt5rjoBnx7+wIzNab9vgwiIh/fBMgXx1Y6iK/xNo=";
      };
      sig = fetchurl {
        url = "https://github.com/motrixapp/builtin-plugins/releases/download/motrix.filename-template@1.1.1/motrix.filename-template-1.1.1.moext.sig";
        hash = "sha256-W2v8x04Nkj7TfE8jQL/cTNrDD2QZGhXOXEbdyGWQvG0=";
      };
    }
    {
      file = "motrix.url-resolver-1.0.0.moext";
      src = fetchurl {
        url = "https://github.com/motrixapp/builtin-plugins/releases/download/motrix.url-resolver@1.0.0/motrix.url-resolver-1.0.0.moext";
        hash = "sha256-MI39DOhjMvQ6627oT602o31x+Pt+8esbeaDmvrWOSp4=";
      };
      sig = fetchurl {
        url = "https://github.com/motrixapp/builtin-plugins/releases/download/motrix.url-resolver@1.0.0/motrix.url-resolver-1.0.0.moext.sig";
        hash = "sha256-cWr4frKtu0eW7WrGAMmxSEDLg1TrnM6/5hImFbqIwXw=";
      };
    }
  ];

  # Pinned by scripts/builtins.lock.json (+ detached .sig sidecars) for this release.
  builtinArtifacts = stdenv.mkDerivation {
    name = "motrix-builtin-artifacts-${version}";
    dontUnpack = true;
    installPhase = ''
      runHook preInstall
      mkdir -p $out
      ${lib.concatMapStringsSep "\n" (a: ''
        cp ${a.src} $out/${a.file}
        cp ${a.sig} $out/${a.file}.sig
      '') builtinList}
      runHook postInstall
    '';
  };

  nativeHost = rustPlatform.buildRustPackage {
    pname = "motrix-native-host";
    inherit version src;
    sourceRoot = "${src.name}/packages/native-host";
    cargoHash = "sha256-rzaIufbzO+BpgFkZ3jRLc+vT3HfYbzIrnT3PAqRXyyo=";
    # Flatpak companion tests assert on filesystem ownership that the Nix
    # sandbox does not satisfy.
    doCheck = false;
    meta.mainProgram = "motrix-native-host";
  };

  finalizeFs = rustPlatform.buildRustPackage {
    pname = "motrix-finalize-fs";
    inherit version src;
    sourceRoot = "${src.name}/packages/finalize-fs";
    cargoHash = "sha256-l7rjen9REjrymq22h3kP+T0t/M8KewNNXyOpTgiEc3M=";
    meta.mainProgram = "motrix-finalize-fs";
  };
in
stdenv.mkDerivation (finalAttrs: {
  inherit pname version src;

  patches = [ ./patches/system-electron.patch ];

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    inherit pnpm;
    fetcherVersion = 4;
    hash = "sha256-CiMNZW/vx5jkGsZhEy9LiQ8wfTzn5Tt5f2XZDqbBHk4=";
  };

  nativeBuildInputs = [
    nodejs
    pnpm
    pnpmConfigHook
    makeBinaryWrapper
    copyDesktopItems
    python3
    pkg-config
    autoPatchelfHook
  ];

  buildInputs = [
    electron
    stdenv.cc.cc.lib
  ];

  # Match AUR `options=('!strip')` — leave unpacked native helpers intact.
  dontStrip = true;

  env = {
    ELECTRON_SKIP_BINARY_DOWNLOAD = "1";
    MOTRIX_SKIP_ELECTRON_REBUILD = "1";
    MOTRIX_SKIP_ENGINE_FETCH = "1";
    npm_config_nodedir = electron.headers;
    npm_config_build_from_source = "true";
  };

  desktopItems = [
    (makeDesktopItem {
      name = "motrix";
      desktopName = "Motrix";
      genericName = "Download Manager";
      comment = "A full-featured download manager";
      exec = "motrix %U";
      icon = "motrix";
      terminal = false;
      startupWMClass = "Motrix";
      mimeTypes = [
        "application/x-bittorrent"
        "x-scheme-handler/magnet"
        "x-scheme-handler/mo"
        "x-scheme-handler/motrix"
        "x-scheme-handler/thunder"
      ];
      categories = [
        "Network"
        "FileTransfer"
      ];
      keywords = [
        "download"
        "bittorrent"
        "magnet"
        "aria2"
      ];
    })
  ];

  postPatch = ''
    # Prefer the Nix-provided pnpm over Corepack's packageManager pin.
    export COREPACK_ENABLE_AUTO_PIN=0
  '';

  buildPhase = ''
    runHook preBuild

    export HOME=$TMPDIR
    export ELECTRON_OVERRIDE_DIST_PATH=${electron.dist}

    # Hydrate the electron npm package so ensure-electron-runtime / ABI probes work.
    mkdir -p node_modules/electron/dist
    cp -r ${electron.dist}/. node_modules/electron/dist/
    chmod -R u+w node_modules/electron/dist
    printf 'electron' > node_modules/electron/path.txt
    # Keep package.json version in sync with the system Electron we ship against.
    ${nodejs}/bin/node <<'EOF'
    const fs = require('fs');
    const pkgPath = 'node_modules/electron/package.json';
    const pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));
    pkg.version = process.env.ELECTRON_VERSION;
    fs.writeFileSync(pkgPath, JSON.stringify(pkg, null, 2) + '\n');
    EOF

    # Stage the pinned aria2 engine where fetch-engine would place it.
    mkdir -p extra/linux/${electronArch}
    tar -xzf ${engine} -C extra/linux/${electronArch}
    chmod +x extra/linux/${electronArch}/aria2c

    # Stage signed builtin plugins for an offline build:builtin.
    export MOTRIX_BUILTIN_ARTIFACT_DIR=${builtinArtifacts}
    pnpm run build:builtin

    # Install prebuilt Rust helpers into the paths electron-builder expects.
    mkdir -p packages/native-host/dist/linux-${electronArch}
    mkdir -p packages/finalize-fs/dist/linux-${electronArch}
    install -Dm755 ${lib.getExe nativeHost} \
      packages/native-host/dist/linux-${electronArch}/motrix-native-host
    install -Dm755 ${lib.getExe finalizeFs} \
      packages/finalize-fs/dist/linux-${electronArch}/motrix-finalize-fs

    # Rebuild better-sqlite3 against system Electron, then build/stage the app.
    unset MOTRIX_SKIP_ELECTRON_REBUILD
    pnpm exec electron-rebuild --force --only better-sqlite3
    pnpm run build:electron
    pnpm run stage:electron -- --platform linux --arch ${electronArch}

    rm -rf release
    cp -r ${electron.dist} electron-dist
    chmod -R u+w electron-dist
    pnpm exec electron-builder --linux dir --${electronArch} --publish never \
      -c.electronDist=$PWD/electron-dist \
      -c.electronVersion=${electron.version}

    runHook postBuild
  '';

  # electron package.json rewrite needs the concrete version in the env of the
  # heredoc above; set it for the whole derivation as well.
  preBuild = ''
    export ELECTRON_VERSION=${electron.version}
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/motrix
    cp -r release/linux-unpacked/resources/. $out/lib/motrix/
    rm -f $out/lib/motrix/app-update.yml $out/lib/motrix/package-type

    install -Dm644 build/256x256.png $out/share/icons/hicolor/512x512/apps/motrix.png

    makeWrapper ${lib.getExe electron} $out/bin/motrix \
      --set ELECTRON_IS_DEV 0 \
      --set ELECTRON_FORCE_IS_PACKAGED true \
      --set MOTRIX_RESOURCES_PATH $out/lib/motrix \
      --set MOTRIX_FFMPEG_BIN ${lib.getExe ffmpeg} \
      --add-flags $out/lib/motrix/app.asar \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ stdenv.cc.cc.lib ]} \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}" \
      --inherit-argv0

    runHook postInstall
  '';

  passthru = {
    inherit electron nativeHost finalizeFs;
    updateScript = ./update.sh;
  };

  meta = {
    description = "Full-featured download manager";
    homepage = "https://motrix.app";
    changelog = "https://github.com/agalwood/Motrix/releases/tag/v${version}";
    downloadPage = "https://motrix.app/download/?channel=stable";
    license = lib.licenses.mit;
    mainProgram = "motrix";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    maintainers = [ ];
  };
})
