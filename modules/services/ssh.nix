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

    home-manager.users.${username}.programs.ssh = {
      enable = true;
      includes =
        builtins.map (
          remote:
            config.sops.secrets."ssh_servers/${remote}".path
        )
        cfg.remotes;
    };
  };
}
