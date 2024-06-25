{
  config,
  lib,
  username,
  ...
}:
with lib;
with lib.my; let
  cfg = config.modules.services.ssh;
  all_remotes = builtins.attrNames (mapper.fromYAML config.sops.defaultSopsFile).ssh_servers;
  remotes =
    if cfg.remotes != null
    then cfg.remotes
    else all_remotes;
in {
  options.modules.services.ssh = {
    enable = mkEnableOption "my ssh configuration";
    remotes = mkOption {
      type = with types; nullOr (listOf str);
      description = ''
        List of remotes which configuration will be sourced from SOPS secrets

        If left empty will source all remotes from the SOPS secrets
      '';
      example = ["vps"];
      default = null;
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
      remotes
    );

    home-manager.users.${username}.programs.ssh = {
      enable = true;
      includes =
        builtins.map (
          remote:
            config.sops.secrets."ssh_servers/${remote}".path
        )
        remotes;
    };
  };
}
