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
    extraEntries = mkOption {
      description = "Adds extra menu entries to GRUB";
      example = ''
        menuentry "Windows" {
          insmod part_gpt
          insmod fat
          insmod search_fs_uuid
          insmod chain
          search --fs-uuid --set=root $FS_UUID
          chainloader /EFI/Microsoft/Boot/bootmgfw.efi
        }
      '';
      type = types.string;
    };
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
      inherit (cfg) extraEntries;

      enable = true;
      efiSupport = true;
      device = "nodev";
      splashImage = "${cfg.theme}/splash_image.jpg";
      gfxmodeEfi = cfg.resolution;
      gfxmodeBios = cfg.resolution;
      theme = cfg.theme;
    };
  };
}
