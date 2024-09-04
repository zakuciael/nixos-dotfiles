{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib;
with lib.my; let
  cfg = config.modules.services.syncthing;
  hmConfig = config.home-manager.users.${username};
  homeDirectory = hmConfig.home.homeDirectory;
  configDirectory = hmConfig.xdg.configHome;
in {
  options.modules.services.syncthing = {
    enable = mkEnableOption "syncthing synchronization service";
  };

  config = mkIf (cfg.enable) {
    # Syncthing ports: 8384 for remote access to GUI
    # 22000 TCP and/or UDP for sync traffic
    # 21027/UDP for discovery
    # source: https://docs.syncthing.net/users/firewall.html
    networking.firewall.allowedTCPPorts = [22000];
    networking.firewall.allowedUDPPorts = [22000 21027];

    # https://github.com/quic-go/quic-go/wiki/UDP-Buffer-Sizes
    boot.kernel.sysctl = {
      "net.core.rmem_max" = 7500000;
      "net.core.wmem_max" = 7500000;
    };

    # Don't create default ~/Sync folder
    systemd.services.syncthing.environment.STNODEFAULTFOLDER = "true";

    sops.secrets = {
      "syncthing/key" = {
        mode = "0644";
        owner = config.services.syncthing.user;
        group = config.services.syncthing.group;
      };
      "syncthing/cert" = {
        mode = "0644";
        owner = config.services.syncthing.user;
        group = config.services.syncthing.group;
      };
    };

    services.syncthing = {
      enable = true;
      systemService = true;
      user = username;
      key = config.sops.secrets."syncthing/key".path;
      cert = config.sops.secrets."syncthing/cert".path;
      configDir = "${configDirectory}/syncthing";
      overrideDevices = true;
      overrideFolders = true;
      settings = {
        options = {
          urAccepted = -1;
          globalAnnounceEnabled = false;
          localAnnounceEnabled = true;
          relaysEnabled = false;
          startBrowser = false;
        };

        devices = {
          nixos.id = "QUDUYTK-C7ES7PH-SLQZW47-FBBSXKP-KMI6V4N-3PFF2AU-AJFOX3W-JZ4USQ4";
          laptop.id = "ZYICIZR-XBL4Q2B-UJAC3P7-ATZE465-J6IVQIM-ZR24CBB-FWIAT27-BPU3HQM";
          "sync.zakku.eu" = {
            id = "6JPV4AX-4ALKGHX-YKKQYNR-IJPTK2O-S6TV2AM-GZ6KDA3-EZ6TNGF-ZZQIDAL";
            addresses = [
              "tcp://51.83.129.177:22000"
            ];
          };
        };

        folders = {
          "Development" = {
            id = "hVYpBP-yrTzAX-PxYRGw-UHvw";
            path = "${homeDirectory}/dev";
            devices = ["nixos" "laptop" "sync.zakku.eu"];
            syncOwnership = false;
          };
        };
      };
    };

    home-manager.users."${username}" = {
      services.syncthing.tray = {
        enable = true;
        command = "syncthingtray --wait";
        package = pkgs.syncthingtray;
      };
    };
  };
}
