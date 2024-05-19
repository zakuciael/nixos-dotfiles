{
  config,
  lib,
  inputs,
  username,
  ...
}:
with lib;
with lib.my; let
  cfg = config.modules.dev.nostale;
in {
  options.modules.dev.nostale = {
    enable = mkEnableOption "NosTale Dev Env";
    installPath = mkOption {
      description = "A path to where NosTale is installed.";
      example = "$HOME/.steam/steam/steamapps/common/NosTale";
      type = types.str;
    };
  };

  config = mkIf (cfg.enable) {
    home-manager.users.${username} = {
      home.packages = with inputs.nostale-dev-env.packages; [
        DevTaleGUI
        proton
        (nostale-dev.override {
          nostale-path = cfg.installPath;
        })
      ];
    };
  };
}
