{ lib, ... }:
# FIXME: Remove when https://github.com/maralorn/nix-output-monitor/pull/321 lands in nixpkgs.
# Fixes https://github.com/maralorn/nix-output-monitor/issues/320 (unknown activity type 10113
# from Determinate Nix 3.23.0), including when nom is invoked via nh's PATH wrapper.
lib.singleton (
  final: prev: {
    nix-output-monitor = prev.nix-output-monitor.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [
        ./patches/handle-unknown-activity-types.patch
      ];
    });

    # Re-wrap so nh's PATH points at the patched nom, not the prev one.
    nh = prev.nh.override {
      inherit (final) nix-output-monitor;
    };
  }
)
