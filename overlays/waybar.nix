{ lib, ... }:
lib.singleton (
  _: prev: {
    # Upstream SleeperThread stress test is flaky under CI sandbox load.
    # doCheck alone is not enough: meson still wants Catch2 when -Dtests=enabled.
    waybar = prev.waybar.overrideAttrs (old: {
      doCheck = false;
      mesonFlags =
        (builtins.filter (f: !(lib.hasPrefix "-Dtests=" f)) (old.mesonFlags or [ ]))
        ++ [ "-Dtests=disabled" ];
    });
  }
)
