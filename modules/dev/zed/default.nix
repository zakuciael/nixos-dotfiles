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

  zedPackage = config.home-manager.users.${username}.programs.zed-editor.package;
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
    home-manager.users.${username} = {
      home = {
        shellAliases.zed = getExe zedPackage;
      };

      programs = {
        zed-editor = {
          enable = true;
          installRemoteServer = cfg.remote-server;

          mutableUserSettings = false;
          mutableUserKeymaps = false;
        };
      };
    };
  };
}
