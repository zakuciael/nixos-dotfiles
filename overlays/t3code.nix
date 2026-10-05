{ lib, ... }:
lib.singleton (
  final: prev:
  let
    inherit (final) stdenv;
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

      # node-pty 1.2.0 ships Linux prebuilds. With dontPatchELF, those *.node
      # addons get no RUNPATH for libstdc++, and Nixpkgs' Electron does not load
      # it either — so the desktop backend dies under ELECTRON_RUN_AS_NODE with
      # NodePtyModuleLoadError / libstdc++.so.6 missing. Patch only host-platform
      # addons; leave foreign-platform vendored binaries alone.
      # https://github.com/NixOS/nixpkgs/pull/570343
      # https://github.com/NixOS/nixpkgs/pull/569702
      postFixup =
        (old.postFixup or "")
        + lib.optionalString stdenv.hostPlatform.isLinux ''
          find "$out"/libexec/t3code -name '*.node' -path '*linux-${stdenv.hostPlatform.node.arch}*' \
            -exec patchelf --add-rpath ${lib.makeLibraryPath [ stdenv.cc.cc.lib ]} {} +
        '';
    });
  in
  {
    t3code = prev.t3code.override {
      inherit t3code-unwrapped;
    };
  }
)
