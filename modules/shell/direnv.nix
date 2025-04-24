{
  config,
  lib,
  username,
  ...
}:
with lib;
with lib.my; let
  cfg = config.modules.shell.direnv;
in {
  options.modules.shell.direnv = {
    enable = mkEnableOption "direnv shell integration";
  };

  config = mkIf (cfg.enable) {
    environment.variables = {
      DIRENV_LOG_FORMAT = "";
    };

    home-manager.users.${username} = {
      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
        config = {
          global = {
            load_dotenv = true;
            disable_stdin = true;
          };
          whitelist.prefix = ["$HOME/dev"];
        };
      };
    };
  };
}
