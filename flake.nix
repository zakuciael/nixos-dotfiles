{
  description = "A Super-Duper Invincible Shining Sparkly Magic NixOS Config"; # Credits: Genshin Impact

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    flake-compat.url = "github:edolstra/flake-compat";
    nix-colors.url = "github:misterio77/nix-colors";
    catppuccin.url = "github:catppuccin/nix";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    distro-grub-themes = {
      url = "github:AdisonCavani/distro-grub-themes";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    alejandra = {
      url = "github:kamadorueda/alejandra/3.0.0";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.fenix.follows = "fenix";
      inputs.flakeCompat.follows = "flake-compat";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "nixpkgs";
    };
    age-plugin-op = {
      url = "github:bromanko/age-plugin-op/v0.1.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rofi-jetbrains = {
      url = "github:zakuciael/rofi-jetbrains";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
      inputs.fenix.follows = "fenix";
    };
    nostale-dev-env = {
      url = "github:zakuciael/nostale-dev-env";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    nil = {
      url = "github:oxalica/nil/2023-08-09";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    ...
  } @ flakeInputs: let
    system = "x86_64-linux";
    username = "zakuciael";

    pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;

      overlays = lib.my.overlays.pkgs;
    };

    unstable = import inputs.nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;

      overlays = lib.my.overlays.unstable;
    };

    inputs =
      flakeInputs
      // {
        distro-grub-themes = flakeInputs.distro-grub-themes.packages.${system};
        nil = flakeInputs.nil.packages.${system};
        alejandra = flakeInputs.alejandra.packages.${system};
        rofi-jetbrains = flakeInputs.rofi-jetbrains.packages.${system};
        nostale-dev-env =
          flakeInputs.nostale-dev-env
          // {packages = flakeInputs.nostale-dev-env.packages.${system};};
        age-plugin-op =
          flakeInputs.age-plugin-op.packages.${system}
          // {default = flakeInputs.age-plugin-op.packages.${system}.age-plugin-op;};
        catppuccin =
          flakeInputs.catppuccin
          // {
            homeManagerModule = flakeInputs.catppuccin.homeManagerModules.catppuccin;
            nixosModules =
              flakeInputs.catppuccin.nixosModules
              // {
                default = flakeInputs.catppuccin.nixosModules.catppuccin;
              };
          };
      };

    lib = nixpkgs.lib.extend (self: super: {
      hm = home-manager.lib.hm;
      my = import ./lib {
        inherit lib pkgs unstable inputs username system;
      };
    });
  in {
    nixosConfigurations = let
      inherit (lib.my.hosts) mkHost;
      hosts = builtins.readDir ./hosts;
      mappedHosts = builtins.mapAttrs (n: v: mkHost {name = n;}) hosts;
    in
      mappedHosts;

    devShells.${system}.default = pkgs.callPackage ./shell.nix {};

    inherit pkgs unstable inputs lib;
  };
}
