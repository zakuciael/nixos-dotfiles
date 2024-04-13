{lib, ...}: rec {
  inherit (lib.attrsets) mapAttrsToList filterAttrs;
  inherit (lib.lists) flatten all;
  inherit (lib.strings) hasSuffix hasPrefix;

  importModulesPath = path: let
    ignoredDir = ["apps" "utils" "plugins"];
  in
    builtins.filter (e: e != null)
    (flatten (mapAttrsToList
      (n: v: let
        newPath = "${path}/${n}";
      in
        if v == "regular"
        then
          if hasSuffix "nix" newPath
          then newPath
          else null
        else importModulesPath newPath)
      (filterAttrs (n: _: all (x: x != n) ignoredDir) (builtins.readDir path))));
}
