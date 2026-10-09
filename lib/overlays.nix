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
        packages = null;
      }
    else if isList raw then
      {
        overlays = raw;
        updateScript = null;
        packages = null;
      }
    else if isAttrs raw && raw ? overlays then
      {
        inherit (raw) overlays;
        updateScript = raw.updateScript or null;
        packages = raw.packages or null;
      }
    else
      throw "overlay module must return null, a list of overlays, or { overlays, updateScript?, packages? }";

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

  # Top-level derivation attrs from an overlay; nested sets (jetbrains, vimPlugins) are skipped.
  overlayAttrNames =
    overlay:
    let
      result = overlay pkgs pkgs;
    in
    filter (name: isDerivation result.${name}) (attrNames result);

  modulePkgNames =
    mod:
    if mod.packages != null then
      mod.packages
    else
      unique (concatMap overlayAttrNames mod.overlays);

  # Attr paths of packages defined by overlays/, for flake checks
  overlayPkgNames = unique (flatten (mapAttrsToList (_: mod: modulePkgNames mod) modules));

  updaters = filterAttrs (_: script: script != null) (
    mapAttrs (_name: mod: mod.updateScript) modules
  );
in
{
  # Each module's `overlays` is already a list (possibly empty).
  pkgs = privatePkgsOverlays ++ flatten (mapAttrsToList (_: mod: mod.overlays) modules);

  # Attr names of packages under pkgs/, for flake checks
  inherit privatePkgNames;

  # Attr paths of packages from overlays/, for flake checks
  inherit overlayPkgNames;

  # name → repo-relative update script path (string), for nixbot effects / just
  inherit updaters;
}
