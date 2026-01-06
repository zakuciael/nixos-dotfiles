{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib;
with lib.my;
let
  cfg = config.modules.shell.television;
in
{
  options.modules.shell.television = {
    enable = mkEnableOption "television shell integrations";
  };

  config = mkIf cfg.enable {
    home-manager.users.${username} = {
      home.packages = [ pkgs.fd ];

      programs.television = {
        enable = true;
        enableFishIntegration = false;
        channels = {
          files = {
            metadata = {
              name = "files";
              description = "A channel to select files and directories";
              requirements = [
                "fd"
                "bat"
              ];
            };
            source.command = "fd -t f";
            preview.command = "bat -n --color=always '{}'";
          };
        };
      };
    };
  };
}
