{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lib.my.utils) writeRofiScript;
in
{
  export = true;
  package = writeRofiScript {
    inherit config;
    name = "rofi-launcher-jetbrains";
    text = ''
      rofi -theme "$ROFI_CONFIG_FILE" -show jetbrains
    '';

    plugins = [ inputs.rofi-jetbrains.rofi-jetbrains-next ];

    imports = [
      (import ../common/theme.nix { inherit lib pkgs; })
      (import ./theme.nix { inherit lib pkgs; })
      (import ./config.nix { inherit lib pkgs; })
    ];

    configuration = {
      modi = "jetbrains";
      display-jetbrains = "󱃖";

      jetbrains-custom-aliases = [
        "rs:RR"
        "web:WS"
        "cpp:CL"
      ];
      jetbrains-install-dir = "~/.local/share/JetBrains/apps/";
    };
  };
}
