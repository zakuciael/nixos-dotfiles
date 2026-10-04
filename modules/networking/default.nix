{
  config,
  lib,
  pkgs,
  hostname,
  ...
}:
let
  inherit (lib) mkDefault;
  inherit (pkgs) concatText;
in
{
  imports = [ ./dns.nix ];

  # Override /etc/hosts files to support secrets
  sops = {
    templates = {
      "etc/hosts" = {
        mode = "0444";
        owner = config.users.users."root".name;
        group = config.users.users."root".group;
        path = "/etc/hosts";
        file = concatText "hosts" config.networking.hostFiles;
      };
    };
  };
  environment.etc."hosts".enable = false;

  networking = {
    hostName = mkDefault hostname;
    networkmanager.enable = true;

    # FIXME: Remove when done testing Zitadel and NetBird
    hosts = {
      "127.0.0.1" = [
        "users.zakku.eu"
        "auth.zakku.eu"
        "sso.zakku.eu"
        "netbird.zakku.eu"
        "proxy.zakku.eu"
        # "ci.zakku.eu"
        # "cache.zakku.eu"
        # "niks3.zakku.eu"
      ];
    };

    firewall = {
      enable = true;
      allowPing = false;
      rejectPackets = true;

      # Open ports in the firewall.
      # allowedTCPPorts = [ ... ];
      # allowedUDPPorts = [ ... ];
    };
  };
}
