{ lib, ... }:
{
  updateScript = "overlays/t3code/update.sh";

  overlays = lib.singleton (
    final: prev:
    let
      inherit (final) stdenv;

      # node-pty 1.2.0 ships Linux prebuilds. With dontPatchELF, those *.node
      # addons get no RUNPATH for libstdc++, and Nixpkgs' Electron does not load
      # it either — so the desktop backend dies under ELECTRON_RUN_AS_NODE with
      # NodePtyModuleLoadError / libstdc++.so.6 missing. Patch only host-platform
      # addons; leave foreign-platform vendored binaries alone.
      # https://github.com/NixOS/nixpkgs/pull/570343
      # https://github.com/NixOS/nixpkgs/pull/569702
      #
      # @cursor/sdk-linux-* ships cursorsandbox without the executable bit under
      # pnpm; T3's Cursor SDK text-generation walk-up then hits EACCES.
      # PATH exposure is handled by the cursor-cli overlay; chmod covers in-tree lookup.
      withLinuxFixes =
        old:
        (old.postFixup or "")
        + lib.optionalString stdenv.hostPlatform.isLinux ''
          find "$out"/libexec/t3code -name '*.node' -path '*linux-${stdenv.hostPlatform.node.arch}*' \
            -exec patchelf --add-rpath ${lib.makeLibraryPath [ stdenv.cc.cc.lib ]} {} +
          find "$out"/libexec/t3code -path '*/@cursor/sdk-linux-*/bin/cursorsandbox' \
            -exec chmod +x {} +
        '';

      # T3 downloads an unpatched chrome-headless-shell under ~/.t3/tools; `t3 browser
      # setup` only installs Debian packages via apt. Prefix the wrapper so the
      # server (and the chrome child it spawns) can resolve the shell's .so deps.
      browserLibraryPath = lib.makeLibraryPath (
        with final;
        [
          alsa-lib
          at-spi2-atk
          at-spi2-core
          atk
          cairo
          cups
          dbus
          expat
          glib
          gtk3
          libdrm
          libgbm
          libx11
          libxcb
          libxcomposite
          libxdamage
          libxext
          libxfixes
          libxkbcommon
          libxrandr
          nspr
          nss
          pango
        ]
      );

      # SnapShot helpers are only staged by upstream's electron-builder pipeline.
      # The Nix build launches Electron unpackaged, so the desktop app looks under
      # libexec/t3code/native/<backend>-snap-shot/target/release/. Helpers must be
      # regular files (not symlinks): install copies their bytes into ~/.local/share.
      installCaptureHelpers =
        {
          src,
          hyprlandSnapShot,
          kdeSnapShot,
        }:
        lib.optionalString stdenv.hostPlatform.isLinux ''
          install -Dm755 ${lib.getExe hyprlandSnapShot} \
            "$out"/libexec/t3code/native/hyprland-snap-shot/target/release/t3-hyprland-snap-shot
          # BSD protocol XML must ship with the binary distribution.
          rm -rf "$out"/libexec/t3code/native/hyprland-snap-shot/target/release/protocols
          cp -R ${src}/native/hyprland-snap-shot/protocols \
            "$out"/libexec/t3code/native/hyprland-snap-shot/target/release/protocols
          install -Dm755 ${lib.getExe kdeSnapShot} \
            "$out"/libexec/t3code/native/kde-snap-shot/target/release/t3-kde-snap-shot
        '';

      mkCaptureHelpers =
        {
          src,
          version,
          hyprlandCargoHash,
          kdeCargoHash,
        }:
        rec {
          hyprlandSnapShot = final.callPackage ./hyprland-snap-shot.nix {
            inherit src version;
            cargoHash = hyprlandCargoHash;
          };
          kdeSnapShot = final.callPackage ./kde-snap-shot.nix {
            inherit src version;
            cargoHash = kdeCargoHash;
          };
          # Bake helpers into unwrapped so __dirname realpath lookups succeed.
          installUnwrapped =
            old: (old.postInstall or "") + installCaptureHelpers { inherit src hyprlandSnapShot kdeSnapShot; };
          # symlinkJoin would otherwise leave store symlinks; SnapShot rejects those.
          installJoined = installCaptureHelpers {
            inherit
              src
              hyprlandSnapShot
              kdeSnapShot
              ;
          };
        };

      withDesktopFixes =
        captureHelpers: pkg:
        pkg.overrideAttrs (old: {
          nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ final.makeBinaryWrapper ];
          # nixpkgs' t3code uses symlinkJoin with __structuredAttrs; its wrap lives in
          # buildCommand (postBuild is already inlined), so append here.
          buildCommand =
            (old.buildCommand or "")
            + lib.optionalString stdenv.hostPlatform.isLinux ''
              for program in "$out/bin"/*; do
                # Drop ELECTRON_RUN_AS_NODE so t3code-desktop is not forced into
                # Node mode when launched from an Electron/agent shell (which then
                # hits require("electron") and tries to download into the store).
                wrapProgram "$program" \
                  --prefix LD_LIBRARY_PATH : ${lib.escapeShellArg browserLibraryPath} \
                  --unset ELECTRON_RUN_AS_NODE
              done
              ${captureHelpers.installJoined}
            '';
        });

      version = "0.0.45";

      src = final.fetchFromGitHub {
        owner = "pingdotgg";
        repo = "t3code";
        tag = "v${version}";
        hash = "sha256-8drTHjFqa2vJ96jhpRZXmNbtbXtKk1q40jOEp9dohNc=";
      };

      # Shared across current stable/nightly; update.sh refreshes nightly hashes.
      hyprlandCargoHash = "sha256-oki1DAzUJ/8YIFhaJlw2wOukiQMcAaexdJqxDcFXFW4=";
      kdeCargoHash = "sha256-ZbetrRAvnNLLS51IwR9xLb1NhnpFQB4J1ahn4CthJy0=";

      captureHelpers = mkCaptureHelpers {
        inherit
          src
          version
          hyprlandCargoHash
          kdeCargoHash
          ;
      };

      t3code-unwrapped = prev.t3code.unwrapped.overrideAttrs (old: {
        inherit version src;

        pnpmDeps = old.pnpmDeps.override {
          inherit version src;
          hash = "sha256-2dGEHOQrnidTei54NlZTJh5u5/i810hb2LddK4XfUNQ=";
        };

        postInstall = captureHelpers.installUnwrapped old;
        postFixup = withLinuxFixes old;
      });

      nightlyVersion = "0.1.1-nightly.20261017.3272";
      nightlySrcHash = "sha256-x3QdfuaqhT64RUhXWuBNFzPow77tTvWRC4tyg/I/Z/E=";
      nightlyPnpmDepsHash = "sha256-OUbKUtz+5qKxzjwXqn1eheRaKs/wZZv4U0hEK/uO2Aw=";

      nightlySrc = final.fetchFromGitHub {
        owner = "pingdotgg";
        repo = "t3code";
        tag = "v${nightlyVersion}";
        hash = nightlySrcHash;
      };

      nightlyCaptureHelpers = mkCaptureHelpers {
        src = nightlySrc;
        version = nightlyVersion;
        hyprlandCargoHash = nightlyHyprlandCargoHash;
        kdeCargoHash = nightlyKdeCargoHash;
      };

      t3code-nightly-unwrapped = prev.t3code.unwrapped.overrideAttrs (old: {
        pname = "t3code-nightly-unwrapped";
        version = nightlyVersion;
        src = nightlySrc;

        # Cursor SDK text gen used mode:"plan", so CreatePlan ate the JSON and
        # generateCommitMessage failed with "invalid structured output".
        patches = (old.patches or [ ]) ++ [ ./patches/cursor-text-gen-agent-mode.patch ];

        pnpmDeps = old.pnpmDeps.override {
          pname = "t3code-nightly-unwrapped";
          version = nightlyVersion;
          src = nightlySrc;
          hash = nightlyPnpmDepsHash;
        };

        postInstall = nightlyCaptureHelpers.installUnwrapped old;
        postFixup = withLinuxFixes old;
      });
    in
    {
      t3code = withDesktopFixes captureHelpers (
        prev.t3code.override {
          inherit t3code-unwrapped;
        }
      );

      t3code-nightly = withDesktopFixes nightlyCaptureHelpers (
        (prev.t3code.override {
          t3code-unwrapped = t3code-nightly-unwrapped;
        }).overrideAttrs
          {
            pname = "t3code-nightly";
          }
      );

      t3-hyprland-snap-shot = nightlyCaptureHelpers.hyprlandSnapShot;
      t3-kde-snap-shot = nightlyCaptureHelpers.kdeSnapShot;
    }
  );
}
