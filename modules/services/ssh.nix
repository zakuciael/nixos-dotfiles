{
  config,
  lib,
  username,
  ...
}:
with lib;
with lib.my; let
  cfg = config.modules.services.ssh;
in {
  options.modules.services.ssh = {
    enable = mkEnableOption "my ssh configuration";
    remotes = mkOption {
      description = "List of remotes which configuration will be sourced from SOPS secrets";
      example = ["vps"];
      default = [];
      type = with types; listOf str;
    };
  };

  config = mkIf (cfg.enable) {
    sops.secrets = listToAttrs (
      builtins.map (remote: {
        name = "ssh_servers/${remote}";
        value = {
          owner = username;
        };
      })
      cfg.remotes
    );

    /*
       sops.secrets = {
      "ssh_servers/prod-1" = {
        owner = username;
      };
      "ssh_servers/raspberry-pi" = {
        owner = username;
      };
    };
    */

    home-manager.users.${username}.programs.ssh = {
      enable = true;
      includes =
        builtins.map (
          remote:
            config.sops.secrets."ssh_servers/${remote}".path
        )
        cfg.remotes;

      /*
         matchBlocks = {
        "prod-1" = {
          host = "prod-1";
          hostname = "51.83.129.177";
          user = "zakku";
        };
        "raspberry-pi" = {
          host = "raspberry-pi";
          hostname = "192.168.1.11";
          user = "zakku";
        };
      };
      */
    };
  };
}
