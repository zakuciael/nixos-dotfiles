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
