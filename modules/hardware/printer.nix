{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib;
with lib.my; let
  cfg = config.modules.hardware.printer;
in {
  options.modules.hardware.printer = {
    enable = mkEnableOption "printer drivers";
  };

  config = mkIf (cfg.enable) {
    home-manager.users.${username}.home.packages = with pkgs; [system-config-printer];

    services.printing = {
      enable = true;
      drivers = with pkgs; [hplip];
    };

    hardware.printers = {
      ensurePrinters = [
        {
          name = "HP-LaserJet-Pro-M304-M305";
          location = "Home";
          deviceUri = "hp:/usb/HP_LaserJet_Pro_M304-M305?serial=PHCY505550";
          model = "HP/hp-laserjet_pro_m304-m305-ps.ppd.gz";
          ppdOptions = {
            PageSize = "A4";
            pdftops-renderer = "gs";
          };
        }
      ];
      ensureDefaultPrinter = "HP-LaserJet-Pro-M304-M305";
    };
  };
}
