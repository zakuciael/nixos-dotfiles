{ ... }:
{
  imports = [
    ./hardware.nix
  ];

  # User settings
  users.users."zakuciael" = {
    uid = 1000;
    description = "Krzysztof Saczuk";
    isNormalUser = true;
    # TODO: Add hashedPasswordFile from secrets
    extraGroups = [
      "wheel" # Allow usage of `sudo` cmd
    ];
  };

  # Import Home-Manager configuration
  home-manager.users."zakuciael" = import ./home.nix;
}
