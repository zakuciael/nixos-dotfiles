{
  config,
  lib,
  inputs,
  username,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    ;
  inherit (inputs.nostale-dev-env.packages)
    DevTaleGUI
    proton
    nos-downloader
    nostale-dev
    ;
  inherit (inputs.onex-explorer.packages) onex-explorer;
  cfg = config.modules.dev.nostale;
in
{
  options.modules.dev.nostale = {
    enable = mkEnableOption "NosTale Dev Env";
    installPath = mkOption {
      description = "A path to where NosTale is installed.";
      example = "$HOME/.steam/steam/steamapps/common/NosTale";
      type = types.str;
    };
  };

  config = mkIf cfg.enable {
    home-manager.users.${username} = {
      home.packages = [
        DevTaleGUI
        proton
        nos-downloader
        onex-explorer
        (nostale-dev.override {
          nostale-path = cfg.installPath;
        })
      ];
    };
  };
}
