{
  pkgs,
  lib,
  config,
  username,
  ...
}:
with lib;
with lib.my; let
  cfg = config.modules.hardware.docker;
in {
  options.modules.hardware.docker = {
    enable = mkEnableOption "Enable docker service";
  };

  config = mkIf (cfg.enable) {
    virtualisation.docker = {
      enable = true;
      autoPrune = {
        enable = true;
        dates = "daily";
      };
    };

    users.users.${username}.extraGroups = ["docker"];
  };
}
