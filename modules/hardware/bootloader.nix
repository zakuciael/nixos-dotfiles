{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.my; let
  cfg = config.modules.hardware.grub;
in {
  options.modules.hardware.grub = {
    enable = mkEnableOption "GRUB2 as bootloader";
    resolution = mkOption {
      description = "Set the resolution to use in the GRUB menu";
      example = "1920x1080";
      type = types.str;
      default = "auto";
    };
    theme = mkOption {
      description = "Set GRUB theme";
      example = pkgs.nixos-grub2-theme;
      type = types.nullOr types.package;
    };
  };

  config = mkIf (cfg.enable) {
    # TODO: Replace OS Prober with manual boot entries generated from options

    boot.loader.grub = {
      enable = true;
      efiSupport = true;
      device = "nodev";
      useOSProber = true;
      splashImage = "${cfg.theme}/splash_image.jpg";
      gfxmodeEfi = cfg.resolution;
      gfxmodeBios = cfg.resolution;
      theme = cfg.theme;
    };
  };
}
