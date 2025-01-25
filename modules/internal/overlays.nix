# Generates "overlays" flake output using configuration found in the overlays/ directory.
{ lib, inputs, ... }:
let
  inherit (lib) fold filterAttrs;
in
rec {
  flake.overlays = {
    swaync-choose-output = import ./../../overlays/swaync-choose-output.nix;
    mongodb-compass-keyring-fix = import ./../../overlays/mongodb-compass-keyring-fix.nix;
    imhex-wayland-fix = import ./../../overlays/imhex-wayland-fix.nix;
    _1password-cli-beta = import ./../../overlays/1password-cli-beta.nix;
    discord-krisp-patch = import ./../../overlays/discord-krisp-patch;

    default =
      final: prev:
      (
        flake.overlays
        |> filterAttrs (name: _: name != "default")
        |> builtins.attrValues
        |> fold (overlay: acc: acc // (overlay final prev)) { }
      );
  };

  perSystem =
    { system, ... }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
        };
        overlays = [ flake.overlays.default ];
      };
    };
}
