{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib;
with lib.my; let
  cfg = config.modules.dev.tools;
in {
  options.modules.dev.tools = {
    enable = mkEnableOption "development tools";
  };

  config = mkIf (cfg.enable) {
    home-manager.users.${username} = {
      home.packages = with pkgs; [
        # GitHub
        gh

        # Reverse Engineering
        ghidra-bin
        imhex

        # MongoDB
        mongosh
        mongodb-tools
        mongodb-compass
      ];
    };
  };
}
