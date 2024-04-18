{lib, ...}:
with lib; {
  networking = {
    hostName = "nixos";
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
