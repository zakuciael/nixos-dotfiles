{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib;
with lib.my; let
  cfg = config.modules.shell.bat;
in {
  options.modules.shell.bat = {
    enable = mkEnableOption "bat shell integration";
  };

  config = mkIf (cfg.enable) {
    home-manager.users.${username} = {
      programs = {
        fish = {
          interactiveShellInit = ''
            # Configure batpipe
            set -x LESSOPEN "|${pkgs.bat-extras.batpipe}/bin/.batpipe-wrapped %s";
            set -e LESSCLOSE;

            # The following will enable colors when using batpipe with less:
            set -x LESS "$LESS -R";
            set -x BATPIPE "color";
          '';
          shellAliases = {
            cat = "bat";
            watch = "batwatch";
            rcat = "command cat";
            man = "batman";
          };
        };
        bat = {
          enable = true;
          catppuccin.enable = true;
          extraPackages = with pkgs.bat-extras; [batdiff batman batpipe batwatch prettybat];
        };
      };
    };
  };
}
