{lib, ...}:
with lib; {
  networking = {
    hostName = mkDefault "nixos";
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
