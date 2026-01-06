{
  config,
  lib,
  username,
  ...
}:
let
  inherit (lib.types) bool;
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkOption;
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
    mutable = mkOption {
      type = bool;
      description = "Whether the configuration files can be updated by Zed.";
      default = false;
    };
  };

  config = mkIf cfg.enable {
    home-manager.users.${username}.programs.zed-editor = {
      enable = true;
      installRemoteServer = cfg.remote-server;

      mutableUserDebug = cfg.mutable;
      mutableUserKeymaps = cfg.mutable;
      mutableUserSettings = cfg.mutable;
      mutableUserTasks = cfg.mutable;
    };
  };
}
