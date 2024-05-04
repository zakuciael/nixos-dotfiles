{
  lib,
  pkgs,
  unstable,
  private-pkgs,
  inputs,
  ...
}:
with lib;
with lib.my; let
  overlays =
    builtins.map
    (file: import file {inherit lib pkgs unstable private-pkgs inputs;})
    (utils.recursiveReadDir ./../overlays {fileExts = ["nix"];});
  getOverlaysFromAttr = attr:
    flatten (
      builtins.filter
      (overlay: overlay != null)
      (builtins.map (config: attrByPath [attr] null config) overlays)
    );
in {
  pkgs = getOverlaysFromAttr "pkgs";
  unstable = getOverlaysFromAttr "unstable";
}
