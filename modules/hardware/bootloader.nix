{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    optionalString
    attrsToList
    concatStringsSep
    mkIf
    mkEnableOption
    mkOption
    types
    ;
  inherit (lib.my.utils) indentLines findLayoutConfig;

  cfg = config.modules.hardware.grub;
  layout = findLayoutConfig config ({ name, ... }: name == "main");

  resolution = builtins.elemAt (lib.splitString "@" (layout.mode or "1920x1080")) 0;
in
{
  options.modules.hardware.grub = {
    enable = mkEnableOption "GRUB2 as bootloader";
    extraEntries = mkOption {
      description = "Adds extra menu entries to GRUB";
      example = {
        "Windows" = {
          class = "windows";
          body = ''
            insmod part_gpt
            insmod fat
            insmod search_fs_uuid
            insmod chain
            search --fs-uuid --set=root $FS_UUID
            chainloader /EFI/Microsoft/Boot/bootmgfw.efi
          '';
        };
      };
      type =
        with types;
        attrsOf (submodule {
          options = {
            class = mkOption {
              description = "Entry class name";
              example = "windows";
              default = null;
              type = nullOr str;
            };
            body = mkOption {
              description = "Entry body";
              example = "";
              type = str;
            };
          };
        });
      default = { };
    };
    theme = mkOption {
      description = "Set GRUB theme";
      example = pkgs.nixos-grub2-theme;
      type = types.nullOr types.package;
    };
  };

  config = mkIf cfg.enable {
    boot.loader.grub = {
      inherit (cfg) theme;

      enable = true;
      efiSupport = true;
      device = "nodev";
      default = "saved";
      splashImage = "${cfg.theme}/splash_image.jpg";

      gfxmodeEfi = "${resolution}x32,auto";
      gfxpayloadEfi = "keep";

      gfxmodeBios = "${resolution}x32,auto";
      gfxpayloadBios = "keep";

      extraEntries =
        attrsToList cfg.extraEntries
        |> map (
          { name, value }:
          ''
            menuentry "${name}" ${optionalString (value.class != null) "--class ${value.class}"} {
            ${optionalString (config.boot.loader.grub.default == "saved") "  savedefault"}
            ${indentLines "  " value.body}
            }
          ''
        )
        |> concatStringsSep "\n";
    };
  };
}
