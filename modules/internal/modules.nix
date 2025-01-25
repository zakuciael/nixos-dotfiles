{
  flake = {
    nixosModules = {
      docker = ./../nixos/docker.nix;
    };
    homeManagerModules = { };
  };
}
