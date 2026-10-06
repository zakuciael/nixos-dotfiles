{
  lib,
  pkgs,
  inputs,
  system,
  ...
}:
with lib;
with lib.my;
let
  mkOverlayName =
    path:
    let
      # Paths under overlays/ carry store context once imported; attr names must not.
      base = builtins.unsafeDiscardStringContext (baseNameOf path);
    in
    if hasSuffix ".nix" base then removeSuffix ".nix" base else base;

  normalizeModule =
    raw:
    if raw == null then
      {
        overlays = [ ];
        updateScript = null;
      }
    else if isList raw then
      {
        overlays = raw;
        updateScript = null;
      }
    else if isAttrs raw && raw ? overlays then
      {
        inherit (raw) overlays;
        updateScript = raw.updateScript or null;
      }
    else
      throw "overlay module must return null, a list of overlays, or { overlays, updateScript? }";

  overlayFiles = utils.recursiveImportDir ./../overlays { };

  modules = listToAttrs (
    map (file: {
      name = mkOverlayName file;
      value = normalizeModule (
        import file {
          inherit
            lib
            pkgs
            inputs
            system
            ;
        }
      );
    }) overlayFiles
  );

  privatePkgsOverlays =
    let
      suffix = "default.nix";
    in
    map (
      file:
      (
        final: _:
        let
          pkg = final.callPackage file { };
          name = lib.last (builtins.filter (x: x != suffix) (lib.flatten (builtins.split "/" file)));
        in
        {
          "${name}" = pkg;
        }
      )
    ) (utils.recursiveReadDir ./../pkgs { suffixes = [ suffix ]; });

  updaters = filterAttrs (_: script: script != null) (
    mapAttrs (_name: mod: mod.updateScript) modules
  );
in
{
  # Each module's `overlays` is already a list (possibly empty).
  pkgs = privatePkgsOverlays ++ flatten (mapAttrsToList (_: mod: mod.overlays) modules);

  # name → repo-relative update script path (string), for nixbot effects / just
  inherit updaters;
}
