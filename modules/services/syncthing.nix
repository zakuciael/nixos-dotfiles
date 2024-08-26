{
  config,
  lib,
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

    services.syncthing = {
      enable = true;
      systemService = true;
      user = username;
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
          nixos.id = "3EL5IKS-DVGUYLS-3JYXXGI-IEK2VEQ-C2ZUZ5X-PC3CAWN-GAV4OYI-PN6B2AH";
          laptop.id = "5LUIWNJ-U6567EN-LDFDEZX-65F5MA5-DIBJZDA-LH5N2E5-VVD5CLE-UTWFSAT";
        };

        folders = {
          "Development" = {
            id = "hVYpBP-yrTzAX-PxYRGw-UHvw";
            path = "${homeDirectory}/dev";
            devices = ["nixos" "laptop"];
          };
        };
      };
    };
  };
}
