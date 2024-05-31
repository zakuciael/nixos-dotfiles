{
  config,
  lib,
  username,
  ...
}:
with lib;
with lib.my; let
  cfg = config.modules.shell.zoxide;
in {
  options.modules.shell.zoxide = {
    enable = mkEnableOption "zoxide shell integration";
  };

  config = mkIf (cfg.enable) {
    home-manager.users.${username} = {
      programs.zoxide = {
        enable = true;
        options = ["--cmd cd"];
      };
    };
  };
}
