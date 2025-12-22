{
  config,
  lib,
  pkgs,
  inputs,
  username,
  ...
}:
with lib;
with lib.my;
let
  cfg = config.modules.shell.nix;
  ns = pkgs.writeShellScriptBin "ns" (builtins.readFile "${inputs.nix-search-tv}/nixpkgs.sh");
in
{
  options.modules.shell.nix = {
    enable = mkEnableOption "nix shell integrations";
  };

  config = mkIf cfg.enable {
    programs = {
      command-not-found.enable = false;
      nix-index.enable = true;
    };

    home-manager.users.${username} = {
      home.packages = [ ns ];

      programs.nix-search-tv = {
        enable = true;
        package = inputs.nix-search-tv.packages.default;
        enableTelevisionIntegration = config.modules.shell.television.enable;
        settings = {
          indexes = [
            "nixpkgs"
            "home-manager"
            "nixos"
          ];
        };
      };
    };
  };
}
