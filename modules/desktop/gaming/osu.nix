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
  cfg = config.modules.desktop.gaming.osu;
in
{
  options.modules.desktop.gaming.osu = {
    enable = mkEnableOption "osu! rythm game";
  };

  config = mkIf cfg.enable {
    home-manager.users.${username} = {
      home.packages = with pkgs; [ osu-lazer-bin ];
    };
  };
}
