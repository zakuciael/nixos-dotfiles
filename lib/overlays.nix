{
  lib,
  pkgs,
  unstable,
  inputs,
  system,
  ...
}:
with lib;
with lib.my; let
  overlays =
    builtins.map
    (file: import file {inherit lib pkgs unstable inputs system;})
    (utils.recursiveReadDir ./../overlays {suffixes = ["nix"];});
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
  getOverlaysFromAttr = attr:
    flatten (
      builtins.filter
      (overlay: overlay != null)
      (builtins.map (config: attrByPath [attr] null config) overlays)
    );
in {
  pkgs = privatePkgsOverlays ++ (getOverlaysFromAttr "pkgs");
  unstable = getOverlaysFromAttr "unstable";
}
