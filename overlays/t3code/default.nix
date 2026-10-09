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
      withNodePtyRpath =
        old:
        (old.postFixup or "")
        + lib.optionalString stdenv.hostPlatform.isLinux ''
          find "$out"/libexec/t3code -name '*.node' -path '*linux-${stdenv.hostPlatform.node.arch}*' \
            -exec patchelf --add-rpath ${lib.makeLibraryPath [ stdenv.cc.cc.lib ]} {} +
        '';

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

        postFixup = withNodePtyRpath old;
      });

      nightlyVersion = "0.0.46-nightly.20261009.2861";
      nightlySrcHash = "sha256-V4wxw9wrWTAoFpNHmtEQhRHsDwlyf2n3RL/Nj+dxXyc=";
      nightlyPnpmDepsHash = "sha256-G3EHVkAEJrl2eOd6dvLjUfwmAurHvq2FZyYM92SFFmE=";

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

        pnpmDeps = old.pnpmDeps.override {
          pname = "t3code-nightly-unwrapped";
          version = nightlyVersion;
          src = nightlySrc;
          hash = nightlyPnpmDepsHash;
        };

        postFixup = withNodePtyRpath old;
      });
    in
    {
      t3code = prev.t3code.override {
        inherit t3code-unwrapped;
      };

      t3code-nightly =
        (prev.t3code.override {
          t3code-unwrapped = t3code-nightly-unwrapped;
        }).overrideAttrs
          {
            pname = "t3code-nightly";
          };
    }
  );
}
