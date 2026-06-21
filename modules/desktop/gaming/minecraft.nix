{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib;
with lib.my;
with lib.my.utils;
let
  cfg = config.modules.desktop.gaming.minecraft;
in
{
  options.modules.desktop.gaming.minecraft = {
    enable = mkEnableOption "minecraft";
  };

  config = mkIf cfg.enable {
    home-manager.users.${username} = {
      home.packages = with pkgs; [ prismlauncher ];

      wayland.windowManager.hyprland.settings = {
        windowrule = [
          {
            name = "Minecraft";
            float = true;
            center = true;
            maximize = true;
            "match:class" = "(Minecraft)";
            content = "game";
          }
        ];
      };
    };
  };
}
