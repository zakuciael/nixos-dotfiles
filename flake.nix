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
      url = "github:zakuciael/distro-grub-themes";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    alejandra = {
      url = "github:kamadorueda/alejandra/3.0.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    username = "zakuciael";
    mkPkgs = p:
      import p {
        inherit system;

        config.allowUnfree = true;
      };

    pkgs = mkPkgs inputs.nixpkgs;
    unstable = mkPkgs inputs.nixpkgs-unstable;

    lib = nixpkgs.lib.extend (self: super: {
      hm = home-manager.lib.hm;
      my = import ./lib {
        inherit lib system inputs pkgs unstable username;
      };
    });
  in {
    nixosConfigurations = let
      inherit (lib.my.hosts) mkHost;
      hosts = builtins.readDir ./hosts;
      mappedHosts = builtins.mapAttrs (n: v: mkHost {name = n;}) hosts;
    in
      mappedHosts;

    devShells.${system}.default = import ./shell.nix {inherit pkgs system inputs;};
  };
}
