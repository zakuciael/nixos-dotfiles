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
  cfg = config.modules.hardware.peripherals;
in
{
  options.modules.hardware.peripherals = {
    enable = mkEnableOption "Keyboard configuration";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      qmk
      via
    ];

    # QMK tags hidraw with GROUP=plugdev; via's udev package opens hidraw for WebHID.
    users.users.${username}.extraGroups = [ "plugdev" ];

    services.udev.packages = [ pkgs.via ];

    hardware.keyboard.qmk = {
      enable = true;
      keychronSupport = true;
    };
  };
}
