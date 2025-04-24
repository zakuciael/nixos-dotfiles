{
  lib,
  pkgs,
  ...
}: let
  inherit (lib.my.mapper) toRasi;
  inherit (lib.my.utils) mkLiteral;
in
  pkgs.writeTextFile {
    name = "theme.rasi";
    text = toRasi {} {
      "*" = {
        # Font
        font = "JetBrains Mono 10";

        # Color Scheme
        background = mkLiteral "#1E2127FF";
        background-alt = mkLiteral "#282B31FF";
        foreground = mkLiteral "#FFFFFFFF";
        selected = mkLiteral "#61AFEFFF";
        active = mkLiteral "#98C379FF";
        urgent = mkLiteral "#E06C75FF";
      };
    };
  }
