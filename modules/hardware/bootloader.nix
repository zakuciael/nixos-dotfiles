{
  pkgs,
  lib,
  config,
  ...
}:
with lib;
with lib.my; let
  cfg = config.modules.hardware.grub;
in {
  options.modules.hardware.grub = {
    enable = mkEnableOption "Enable GRUB2 as bootloader";
  };

  config = mkIf (cfg.enable) {
    boot.loader.grub = {
      enable = true;
      efiSupport = true;
      device = "nodev";
      useOSProber = true;
    };
  };
}
