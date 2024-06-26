{
  config,
  lib,
  ...
}:
with lib;
with lib.my; let
  cfg = config.modules.services.twingate;
in {
  options.modules.services.twingate = {
    enable = mkEnableOption "Twingate client";
  };

  config = mkIf (cfg.enable) {
    services.twingate.enable = true;
  };
}
