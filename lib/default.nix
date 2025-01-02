{
  lib,
  pkgs,
  inputs,
  username,
  system,
  ...
}:
let
  utils = import ./utils.nix { inherit lib pkgs username; };
  mapper = import ./mapper.nix { inherit lib pkgs; };
  defs = import ./defs.nix { inherit lib; };

  dotfiles = mapper.mapDirToAttrs ./../dotfiles;
  scripts = import ./scripts.nix {
    inherit
      lib
      pkgs
      inputs
      username
      dotfiles
      ;
  };
in
{
  inherit
    utils
    mapper
    defs
    dotfiles
    ;

  hosts = import ./hosts.nix {
    inherit
      lib
      pkgs
      inputs
      username
      dotfiles
      scripts
      ;
  };
  desktop = import ./desktop.nix {
    inherit
      lib
      pkgs
      inputs
      username
      dotfiles
      scripts
      ;
  };
  overlays = import ./overlays.nix {
    inherit
      lib
      pkgs
      inputs
      system
      ;
  };
}
