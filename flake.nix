{
  description = "A Super-Duper Invincible Shining Sparkly Magic NixOS Config"; # Credits: Genshin Impact
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixos-hardware.url = "github:zakuciael/nixos-hardware/master";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
  };

  outputs =
    { flake-parts, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      debug = true;
      systems = [ "x86_64-linux" ];
      imports = [
        ./modules/internal/hosts.nix # Exports all NixOS hosts located under `hosts/` directory.
        ./modules/internal/pkgs.nix # Exports all custom pkgs located under `pkgs/` directory.
        ./modules/internal/overlays.nix # Exports all overlays located under `overlays/` directory.
        ./modules/internal/modules.nix # Exports all modules located under `modules/` directory (Except internal ones).
      ];
    };
}
