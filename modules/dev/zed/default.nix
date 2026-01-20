{
  config,
  lib,
  username,
  ...
}:
let
  inherit (lib.types) bool;
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    getExe
    ;
  cfg = config.modules.dev.zed;
in
{
  options.modules.dev.zed = {
    enable = mkEnableOption "Zed Editor";
    remote-server = mkOption {
      type = bool;
      description = "This allows remotely connecting to this system from a distant Zed client.";
      default = false;
    };
  };

  config = mkIf cfg.enable {
    home-manager.users.${username}.programs = {
      fish.shellAliases.zed = "${getExe
        config.home-manager.users.${username}.programs.zed-editor.package
      }";
      zed-editor = {
        enable = true;
        installRemoteServer = cfg.remote-server;

        mutableUserSettings = false;
        mutableUserKeymaps = false;
      };
    };
  };
}
