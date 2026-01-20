{ lib, ... }:
lib.singleton (
  final: _: {
    gitbutler =
      let
        inherit (final)
          stdenv
          rustPlatform
          fetchFromGitHub
          fetchPnpmDeps
          rust
          turbo
          dart-sass
          nix-update-script
          ;

        excludeSpec = spec: [
          "--exclude"
          spec
        ];
      in

      rustPlatform.buildRustPackage (finalAttrs: {
        pname = "gitbutler";
        version = "0.18.3";

        src = fetchFromGitHub {
          owner = "gitbutlerapp";
          repo = "gitbutler";
          tag = "release/${finalAttrs.version}";
          hash = "sha256-N/xs63QjqEgDXAOEZpzBRl1QrwDlcYyFWSyNlku6tKw=";
        };

        # Workaround for https://github.com/NixOS/nixpkgs/issues/359340
        cargoPatches = [ ./dedupe-cargo-lock.patch ];

        # Let Tauri know what version we're building
        #
        # Remove references to non-existent workspaces in `gix` crates
        #
        # Deactivate the built-in updater
        postPatch = ''
          tauriConfRelease="crates/gitbutler-tauri/tauri.conf.release.json"
          jq '.version = "${finalAttrs.version}" | .bundle.createUpdaterArtifacts = false | .bundle.externalBin = ["gitbutler-git-setsid", "gitbutler-git-askpass", "but"]' "$tauriConfRelease" | sponge "$tauriConfRelease"

          tomlq -ti 'del(.lints) | del(.workspace.lints)' "$cargoDepsCopy"/gix*/Cargo.toml

          substituteInPlace apps/desktop/src/lib/backend/tauri.ts \
            --replace-fail 'checkUpdate = tauriCheck;' 'checkUpdate = () => null;'

          # Use crates.io version of file-id instead of git dependency
          substituteInPlace crates/gitbutler-git/Cargo.toml \
            --replace-fail \
              'file-id = { git = "https://github.com/notify-rs/notify", rev = "978fe719b066a8ce76b9a9d346546b1569eecfb6", version = "0.2.3" }' \
              'file-id = "0.2.3"'
        '';

        cargoHash = "sha256-4Choio1gjUNdiQbvAe/r7jYElRRzKiGGxpkjsw5VjTI=";

        pnpmDeps = fetchPnpmDeps {
          inherit (finalAttrs) pname version src;
          fetcherVersion = 2;
          hash = "sha256-R1EYyMy0oVX9G6GYrjIsWx7J9vfkdM4fLlydteVsi7E=";
        };

        nativeBuildInputs =
          with final;
          [
            pnpm_10
            cacert # Required by turbo
            cargo-tauri.hook
            cmake # Required by `zlib-sys` crate
            dart-sass # Required for sass-embedded (bundled binary doesn't work in Nix sandbox)
            desktop-file-utils
            jq
            moreutils
            nodejs
            pkg-config
            pnpmConfigHook
            turbo
            wrapGAppsHook4
            yq # For `tomlq`
          ]
          ++ lib.optional stdenv.hostPlatform.isDarwin makeBinaryWrapper;

        buildInputs =
          (with final; [
            libgit2
            openssl
          ])
          ++ lib.optional stdenv.hostPlatform.isDarwin final.curl
          ++ lib.optionals stdenv.hostPlatform.isLinux (
            with final;
            [
              glib-networking
              webkitgtk_4_1
            ]
          );

        tauriBuildFlags = [
          "--config"
          "crates/gitbutler-tauri/tauri.conf.release.json"
        ];

        nativeCheckInputs = with final; [ git ];

        # `gitbutler-git`'s checks do not support release mode
        checkType = "debug";
        cargoTestFlags = [
          "--workspace"
        ]
        ++ lib.concatMap excludeSpec [
          # Requires Git directories
          "but"
          "but-core"
          "but-rebase"
          "but-workspace"
          # Fails due to the issues above and below
          "but-hunk-dependency"
          # Errors with "Lazy instance has previously been poisoned"
          "gitbutler-branch-actions"
          "gitbutler-stack"
          # `Expecting driver to be located at "../../target/debug/gitbutler-cli" - we also assume a certain crate location`
          # We're not (usually) building in debug mode and always have a different target directory, so...
          "gitbutler-edit-mode"
          "but-cherry-apply"
          "but-worktrees"
        ];

        env = {
          # Make sure `crates/gitbutler-tauri/inject-git-binaries.sh` can find our
          # target dir
          # https://github.com/gitbutlerapp/gitbutler/blob/56b64d778042d0e93fa362f808c35a7f095ab1d1/crates/gitbutler-tauri/inject-git-binaries.sh#L10C10-L10C26
          TRIPLE_OVERRIDE = rust.envVars.rustHostPlatformSpec;

          # `pnpm`'s `fetchDeps` and `configHook` uses a specific version of pnpm, not upstream's
          COREPACK_ENABLE_STRICT = 0;

          # We depend on nightly features
          RUSTC_BOOTSTRAP = 1;

          # We also need to have `tracing` support in `tokio` for `console-subscriber`
          RUSTFLAGS = "--cfg tokio_unstable";

          TUBRO_BINARY_PATH = lib.getExe turbo;

          OPENSSL_NO_VENDOR = true;
          LIBGIT2_NO_VENDOR = 1;
        };

        preBuild = ''
          # Patch sass-embedded to use Nix-provided dart-sass instead of bundled Dart VM
          # (the bundled binary doesn't work in Nix sandbox)
          substituteInPlace node_modules/.pnpm/sass-embedded@*/node_modules/sass-embedded/dist/lib/src/compiler-path.js \
              --replace-fail \
              'exports.compilerCommand = (() => {' \
              'exports.compilerCommand = (() => { return ["${dart-sass}/bin/sass"];'

          # Build the "but" binary for use by Tauri
          cargo build --release -p but

          # Copy the "but" binary to where Tauri expects it (with platform-specific name)
          cp target/release/but crates/gitbutler-tauri/but-${rust.envVars.rustHostPlatformSpec}

          turbo run --filter @gitbutler/svelte-comment-injector build
          pnpm build:desktop -- --mode production
        '';

        preFixup = lib.optionalString stdenv.hostPlatform.isLinux ''
          gappsWrapperArgs+=(--set WEBKIT_DISABLE_DMABUF_RENDERER 1)
        '';

        postInstall =
          lib.optionalString stdenv.hostPlatform.isDarwin ''
            makeBinaryWrapper $out/Applications/GitButler.app/Contents/MacOS/gitbutler-tauri $out/bin/gitbutler-tauri
          ''
          + lib.optionalString stdenv.hostPlatform.isLinux ''
            desktop-file-edit \
              --set-comment "A Git client for simultaneous branches on top of your existing workflow." \
              --set-key="Keywords" --set-value="git;" \
              --set-key="StartupWMClass" --set-value="GitButler" \
              $out/share/applications/GitButler.desktop
          '';

        passthru = {
          updateScript = nix-update-script {
            extraArgs = [
              "--version-regex"
              "release/(.*)"
            ];
          };
        };

        meta = {
          description = "Git client for simultaneous branches on top of your existing workflow";
          homepage = "https://gitbutler.com";
          changelog = "https://github.com/gitbutlerapp/gitbutler/releases/tag/release/${finalAttrs.version}";
          license = lib.licenses.fsl11Mit;
          maintainers = with lib.maintainers; [
            getchoo
            techknowlogick
          ];
          mainProgram = "gitbutler-tauri";
          platforms = lib.platforms.linux ++ lib.platforms.darwin;
        };
      });
  }
)
