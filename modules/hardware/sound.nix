{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib;
with lib.my;
let
  cfg = config.modules.hardware.sound;
in
{
  options.modules.hardware.sound = {
    enable = mkEnableOption "Pipewire sound driver";
  };

  config = mkIf (cfg.enable) {
    home-manager.users.${username}.home.packages = with pkgs; [ pavucontrol ];

    security.rtkit.enable = true;

    services.pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
    };
  };
}
