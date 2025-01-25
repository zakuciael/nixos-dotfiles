{
  description = "A Super-Duper Invincible Shining Sparkly Magic NixOS Config"; # Credits: Genshin Impact

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:zakuciael/nixos-hardware/master";
    flake-utils.url = "github:numtide/flake-utils";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-compat.url = "github:edolstra/flake-compat";
    nix-colors.url = "github:misterio77/nix-colors";
    catppuccin.url = "github:catppuccin/nix";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    distro-grub-themes = {
      url = "github:AdisonCavani/distro-grub-themes";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix?rev=59d6988329626132eaf107761643f55eb979eef1";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "nixpkgs";
    };
    rofi-jetbrains = {
      url = "github:zakuciael/rofi-jetbrains/v2.1.0";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
    nostale-dev-env = {
      url = "github:zakuciael/nostale-dev-env";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
    aagl = {
      url = "github:ezKEa/aagl-gtk-on-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-compat.follows = "flake-compat";
    };
    vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    deadnix = {
      url = "github:zakuciael/deadnix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    statix = {
      url = "github:RobWalt/statix/";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      ...
    }@flakeInputs:
    let
      system = "x86_64-linux";
      username = "zakuciael";

      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          permittedInsecurePackages = [ ];
        };

        overlays = lib.my.overlays.pkgs ++ lib.singleton (inputs.aagl.overlays.default);
      };

      inputs = flakeInputs // {
        distro-grub-themes = flakeInputs.distro-grub-themes.packages.${system};
        rofi-jetbrains = flakeInputs.rofi-jetbrains.packages.${system};
        nostale-dev-env = flakeInputs.nostale-dev-env // {
          packages = flakeInputs.nostale-dev-env.packages.${system};
        };
        catppuccin = flakeInputs.catppuccin // {
          homeManagerModule = flakeInputs.catppuccin.homeManagerModules.catppuccin;
          nixosModules = flakeInputs.catppuccin.nixosModules // {
            default = flakeInputs.catppuccin.nixosModules.catppuccin;
          };
        };
        aagl = flakeInputs.aagl // {
          packages = flakeInputs.aagl.packages.${system};
        };
        vscode-server = flakeInputs.vscode-server // {
          homeManagerModule = flakeInputs.vscode-server.homeModules.default;
        };
        deadnix = flakeInputs.deadnix.packages.${system};
        statix = flakeInputs.statix.packages.${system};
      };

      lib = nixpkgs.lib.extend (
        _: _: {
          hm = home-manager.lib.hm;
          my = import ./lib {
            inherit
              lib
              pkgs
              inputs
              username
              system
              ;
          };
        }
      );
    in
    {
      nixosConfigurations =
        let
          inherit (lib.my.hosts) mkHost;
        in
        builtins.readDir ./hosts |> builtins.mapAttrs (name: _: mkHost { inherit name; });

      devShells.${system}.default = pkgs.callPackage ./shell.nix { };

      inherit pkgs inputs lib;
    };
}
