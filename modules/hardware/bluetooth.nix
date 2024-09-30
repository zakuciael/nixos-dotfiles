{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib;
with lib.my; let
  cfg = config.modules.hardware.bluetooth;
in {
  options.modules.hardware.bluetooth = {
    enable = mkEnableOption "support for Bluetooth";
  };

  config = mkIf (cfg.enable) {
    home-manager.users.${username}.home.packages = with pkgs; [overskride];

    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
  };
}
