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

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # modules = {
  #   services.ssh.enable = true;
  #   desktop.hyprland.enable = true;
  # };
}
