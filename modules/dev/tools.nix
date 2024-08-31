{
  config,
  lib,
  pkgs,
  unstable,
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
        # Git
        unstable.graphite-cli
        gh

        # Reverse Engineering
        ghidra-bin
        unstable.imhex

        # MongoDB
        mongosh
        mongodb-tools
        mongodb-compass

        # HTTPie
        httpie
        httpie-desktop

        # Benchmarking
        hyperfine

        # FTP
        filezilla

        # Tracking
        wakatime
      ];
    };
  };
}
