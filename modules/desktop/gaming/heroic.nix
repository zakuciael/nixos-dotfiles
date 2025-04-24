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
  cfg = config.modules.desktop.gaming.heroic;
in {
  options.modules.desktop.gaming.heroic = {
    enable = mkEnableOption "Heroic Game Launcher";
  };

  config = mkIf (cfg.enable) {
    home-manager.users.${username} = {
      home.packages = with pkgs; [heroic];
    };
  };
}
