{
  lib,
  hostname,
  ...
}:
with lib; {
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
