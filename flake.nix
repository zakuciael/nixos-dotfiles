{
  description = "A Super-Duper Invincible Shining Sparkly Magic NixOS Config"; # Credits: Genshin Impact

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";

    nixos-hardware.url = "github:zakuciael/nixos-hardware/master";
    flake-compat.url = "github:edolstra/flake-compat";
    systems.url = "github:nix-systems/default";
    nixpkgs-lib.follows = "nixpkgs";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.rust-analyzer-src.follows = "";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-colors = {
      url = "github:misterio77/nix-colors";
      inputs.nixpkgs-lib.follows = "nixpkgs-lib";
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs-lib";
    };
    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
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
      url = "github:zakuciael/rofi-jetbrains?ref=feat/direnv-support";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
        fenix.follows = "fenix";
      };
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
      inputs.rust-overlay.follows = "rust-overlay";
    };
    vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    deadnix = {
      url = "github:astro/deadnix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        utils.follows = "flake-utils";
      };
    };
    statix = {
      url = "github:oppiliappan/statix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    onex-explorer = {
      url = "github:zakuciael/OnexExplorer";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake/beta";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };
    _1pass-shell-plugins = {
      url = "github:1Password/shell-plugins";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
      };
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-search-tv = {
      url = "github:3timeslazy/nix-search-tv";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    steam-presence = {
      url = "github:JustTemmie/steam-presence";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    # zed-extensions = {
    #   url = "github:DuskSystems/nix-zed-extensions";
    #   inputs.nixpkgs.follows = "nixpkgs";
    #   inputs.nixpkgs-unstable.follows = "nixpkgs";
    #   inputs.rust-overlay.follows = "rust-overlay";
    # };
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
          allowUnsupportedSystem = true;
          permittedInsecurePackages = [ ];
        };

        overlays = lib.my.overlays.pkgs ++ [
          inputs.aagl.overlays.default
          # inputs.zed-extensions.overlays.default
        ];
      };

      inputs = flakeInputs // {
        distro-grub-themes = flakeInputs.distro-grub-themes.packages.${system};
        rofi-jetbrains = flakeInputs.rofi-jetbrains.packages.${system};
        nostale-dev-env = flakeInputs.nostale-dev-env // {
          packages = flakeInputs.nostale-dev-env.packages.${system};
        };
        catppuccin = flakeInputs.catppuccin // {
          homeManagerModule = flakeInputs.catppuccin.homeModules.catppuccin;
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
        disko = flakeInputs.disko // {
          packages = flakeInputs.disko.packages.${system};
        };
        onex-explorer = flakeInputs.onex-explorer // {
          packages = flakeInputs.onex-explorer.packages.${system};
        };
        nix-search-tv = flakeInputs.nix-search-tv // {
          packages = flakeInputs.nix-search-tv.packages.${system};
        };
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

      apps.${system} = {
        disko = {
          type = "app";
          program = "${inputs.disko.packages.disko}/bin/disko";
        };
      };

      inherit pkgs inputs lib;
    };
}
