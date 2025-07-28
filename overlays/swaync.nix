{ lib, ... }:
with lib;
singleton (
  final: prev: {
    # More up to date version of this https://github.com/ErikReider/SwayNotificationCenter/pull/262
    swaynotificationcenter = prev.swaynotificationcenter.overrideAttrs (prevAttrs: {
      src = final.fetchFromGitHub {
        inherit (prevAttrs.src) repo;
        owner = "zakuciael";
        rev = "HEAD";
        hash = "sha256-I77SYSQZkhNWgCm1WMPJULYiqQEdH4g0zWhCX547CNs=";
      };

      buildInputs =
        prevAttrs.buildInputs
        ++ (with final; [
          libhandy
          cmake
          pantheon.granite
          gtk-layer-shell
        ]);
    });
  }
)
