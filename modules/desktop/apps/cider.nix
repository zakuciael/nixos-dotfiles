{
  username,
  pkgs,
  ...
}:
{
  home-manager.users.${username}.home.packages = [
    pkgs.cider-2
  ];

  # Allows Cider Remote to connect to the Cider app.
  networking.firewall.allowedTCPPorts = [ 10767 ];
}
