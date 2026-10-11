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

      withBrowserLibraries =
        pkg:
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
            '';
        });

      version = "0.0.45";

      src = final.fetchFromGitHub {
        owner = "pingdotgg";
        repo = "t3code";
        tag = "v${version}";
        hash = "sha256-8drTHjFqa2vJ96jhpRZXmNbtbXtKk1q40jOEp9dohNc=";
      };

      t3code-unwrapped = prev.t3code.unwrapped.overrideAttrs (old: {
        inherit version src;

        pnpmDeps = old.pnpmDeps.override {
          inherit version src;
          hash = "sha256-2dGEHOQrnidTei54NlZTJh5u5/i810hb2LddK4XfUNQ=";
        };

        postFixup = withLinuxFixes old;
      });

      nightlyVersion = "0.0.46-nightly.20261011.2967";
      nightlySrcHash = "sha256-1TUSFoLJIBXfr8ZvOdArI07NjNdLU9W7hPXlrPm9CHQ=";
      nightlyPnpmDepsHash = "sha256-reXWayWahyOJKTDp6GyOq9n5TsS4BpAMclWycpIxygo=";

      nightlySrc = final.fetchFromGitHub {
        owner = "pingdotgg";
        repo = "t3code";
        tag = "v${nightlyVersion}";
        hash = nightlySrcHash;
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

        postFixup = withLinuxFixes old;
      });
    in
    {
      t3code = withBrowserLibraries (
        prev.t3code.override {
          inherit t3code-unwrapped;
        }
      );

      t3code-nightly = withBrowserLibraries (
        (prev.t3code.override {
          t3code-unwrapped = t3code-nightly-unwrapped;
        }).overrideAttrs
          {
            pname = "t3code-nightly";
          }
      );
    }
  );
}
