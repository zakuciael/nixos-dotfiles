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

  privatePkgSuffix = "default.nix";

  privatePkgFiles = utils.recursiveReadDir ./../pkgs {
    suffixes = [ privatePkgSuffix ];
  };

  mkPrivatePkgName =
    file:
    lib.last (
      builtins.filter (x: x != privatePkgSuffix) (lib.flatten (builtins.split "/" file))
    );

  privatePkgNames = map mkPrivatePkgName privatePkgFiles;

  privatePkgsOverlays = map (
    file:
    (
      final: _:
      {
        ${mkPrivatePkgName file} = final.callPackage file { };
      }
    )
  ) privatePkgFiles;

  updaters = filterAttrs (_: script: script != null) (
    mapAttrs (_name: mod: mod.updateScript) modules
  );
in
{
  # Each module's `overlays` is already a list (possibly empty).
  pkgs = privatePkgsOverlays ++ flatten (mapAttrsToList (_: mod: mod.overlays) modules);

  # Attr names of packages under pkgs/, for flake checks
  inherit privatePkgNames;

  # name → repo-relative update script path (string), for nixbot effects / just
  inherit updaters;
}
