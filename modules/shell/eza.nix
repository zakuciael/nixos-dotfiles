{
  config,
  lib,
  username,
  ...
}:
with lib;
with lib.my; let
  cfg = config.modules.shell.eza;
in {
  options.modules.shell.eza = {
    enable = mkEnableOption "eza shell integration";
  };

  config = mkIf (cfg.enable) {
    home-manager.users.${username} = {
      programs.eza = {
        enable = true;
        git = config.modules.dev.git.enable;
        icons = "auto";
      };
    };
  };
}
