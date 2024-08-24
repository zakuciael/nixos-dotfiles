{
  config,
  lib,
  unstable,
  username,
  ...
}:
with lib; let
  cfg = config.modules.dev.vscode;
in {
  options.modules.dev.vscode = {
    enable = mkEnableOption "Visual Studio Code";
    server = mkEnableOption "Visual Studio Code server";
  };

  config = mkIf (cfg.enable || cfg.server) {
    home-manager.users.${username} = {
      home.packages =
        if (cfg.enable)
        then [unstable.vscode]
        else [];
      services.vscode-server.enable = cfg.server;
    };
  };
}
