{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.modules.shell.zoxide;
in
{
  options.modules.shell.zoxide = {
    enable = mkEnableOption "zoxide shell integration";
  };

  config = mkIf (cfg.enable) {
    home-manager.users.${username} = {
      programs = {
        fish = {
          plugins = [
            {
              name = "zoxide";
              src = pkgs.fetchFromGitHub {
                owner = "icezyclon";
                repo = "zoxide.fish";
                rev = "4aa74bea2b6052eb1a301d8bffca862564a7d28a";
                hash = "sha256-kSKFz594riTu0FmRJsbSVNdMs89br1Vl1p74cnwhnV0=";
              };
            }
          ];
        };
        zoxide = {
          enable = true;
          enableFishIntegration = false;
          options = [ "--cmd cd" ];
        };
      };
    };
  };
}
