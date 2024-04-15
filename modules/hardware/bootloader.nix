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
    theme = mkOption {
      type = types.nullOr types.package;
      example = pkgs.nixos-grub2-theme;
      description = "Set GRUB theme";
    };
  };

  config = mkIf (cfg.enable) {
    boot.loader.grub = {
      enable = true;
      efiSupport = true;
      device = "nodev";
      useOSProber = true;
      splashImage = "${cfg.theme}/splash_image.jpg";
      theme = cfg.theme;
    };
  };
}
