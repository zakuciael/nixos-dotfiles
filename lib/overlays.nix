{
  lib,
  pkgs,
  inputs,
  system,
  ...
}:
with lib;
with lib.my; let
  overlays = builtins.map (file: import file {inherit lib pkgs inputs system;}) (utils.recursiveImportDir ./../overlays {});
  privatePkgsOverlays = let
    suffix = "default.nix";
  in
    builtins.map
    (file: (
      final: prev: let
        pkg = final.callPackage file {};
        name = lib.last (builtins.filter (x: x != suffix) (lib.flatten (builtins.split "/" file)));
      in {
        "${name}" = pkg;
      }
    ))
    (utils.recursiveReadDir ./../pkgs {suffixes = [suffix];});
in {
  pkgs = privatePkgsOverlays ++ flatten (builtins.filter (overlay: overlay != null) overlays);
}
