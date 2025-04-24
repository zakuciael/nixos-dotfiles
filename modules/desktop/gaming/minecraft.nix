{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib;
with lib.my;
with lib.my.utils; let
  cfg = config.modules.desktop.gaming.minecraft;
  layout = findLayoutConfig config ({name, ...}: name == "main"); # Main monitor
  monitor = getLayoutMonitor layout "wayland";
  minecraftClass = "(Minecraft)";
in {
  options.modules.desktop.gaming.minecraft = {
    enable = mkEnableOption "minecraft";
  };

  config = mkIf (cfg.enable) {
    home-manager.users.${username} = {
      home.packages = with pkgs; [prismlauncher];

      wayland.windowManager.hyprland.settings = {
        windowrulev2 = [
          "float, class:${minecraftClass}"
          "monitor ${monitor}, class:${minecraftClass}"
          "center, class:${minecraftClass}"
          "maximize, class:${minecraftClass}"
        ];
      };
    };
  };
}
