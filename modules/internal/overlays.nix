# Generates "overlays" flake output using configuration found in the overlays/ directory.
{ lib, ... }:
let
  inherit (lib) fold filterAttrs;
in
rec {
  flake.overlays = {
    swaynotificationcenter = import ./../../overlays/swaync.nix;
    _1password-cli-beta = import ./../../overlays/_1password.nix;
    httpie-desktop = import ./../../overlays/httpie-desktop.nix;

    default =
      final: prev:
      (
        flake.overlays
        |> filterAttrs (name: _: name != "default")
        |> builtins.attrValues
        |> fold (overlay: acc: acc // (overlay final prev)) { }
      );
  };
}
