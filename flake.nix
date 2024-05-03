{
  description = "A Super-Duper Invincible Shining Sparkly Magic NixOS Config"; # Credits: Genshin Impact

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    distro-grub-themes = {
      url = "github:AdisonCavani/distro-grub-themes";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    alejandra = {
      url = "github:kamadorueda/alejandra/3.0.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprpaper = {
      url = "github:hyprwm/hyprpaper";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    waybar = {
      url = "github:Alexays/Waybar";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    hyprland.url = "github:hyprwm/Hyprland";
    nixd.url = "github:nix-community/nixd";
    nil.url = "github:oxalica/nil";
    nix-colors.url = "github:misterio77/nix-colors";
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

      # TODO: Replace this dirty trick when nixos 24.05 releases
      overlays = [
        (final: prev: {
          nh = unstable.nh;
        })
      ];
    };

    unstable = import inputs.nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;

      overlays = [
        flakeInputs.waybar.overlays.default
      ];
    };

    inputs =
      flakeInputs
      // {
        distro-grub-themes = flakeInputs.distro-grub-themes.packages.${system};
        nil = flakeInputs.nil.packages.${system};
        nixd = flakeInputs.nixd.packages.${system};
        alejandra = flakeInputs.alejandra.packages.${system};
        hyprland-contrib = flakeInputs.hyprland-contrib.packages.${system};
        hyprpaper = flakeInputs.hyprpaper.packages.${system};
        hyprland =
          flakeInputs.hyprland
          // {
            packages = flakeInputs.hyprland.packages.${system};
          };
      };

    private-pkgs = lib.my.pkgs.importPkgs ./pkgs;

    lib = nixpkgs.lib.extend (self: super: {
      hm = home-manager.lib.hm;
      my = import ./lib {
        inherit lib pkgs unstable private-pkgs inputs username;
      };
    });
  in {
    nixosConfigurations = let
      inherit (lib.my.hosts) mkHost;
      hosts = builtins.readDir ./hosts;
      mappedHosts = builtins.mapAttrs (n: v: mkHost {name = n;}) hosts;
    in
      mappedHosts;
  };
}
