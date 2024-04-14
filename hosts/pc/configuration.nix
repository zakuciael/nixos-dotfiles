{
  config,
  pkgs,
  ...
}: {
  imports = [./hardware.nix];

  # Setup home-manager
  home-manager.users.zakuciael = ./home.nix;

  # Networking
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];

  modules = {
    desktop.apps.enable = true;
    desktop.gnome.enable = true;
  };
}
