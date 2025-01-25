# Generates "overlays" flake output using configuration found in the overlays/ directory.
{ lib, ... }:
let
  toOverlayPath = path: ./../../overlays + builtins.toPath "/${path}.nix";
  overlays = {
    swaynotificationcenter = import (toOverlayPath "swaync");
    _1password-cli-beta = import (toOverlayPath "_1password");
    httpie-desktop = import (toOverlayPath "httpie-desktop");
  };
in
{
  flake.overlays = {
    default =
      final: prev: lib.fold (overlay: acc: acc // (overlay final prev)) { } (lib.attrValues overlays);
  } // overlays;
}
