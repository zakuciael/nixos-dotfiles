{
  lib,
  pkgs,
  ...
}: rec {
  inherit (lib.attrsets) filterAttrs nameValuePair mapAttrs' mapAttrsToList;
  inherit (lib.lists) flatten last;

  importPkgs = path:
    builtins.listToAttrs (
      builtins.map
      (path: {
        name = last (flatten (builtins.split "/" path));
        value = pkgs.callPackage (builtins.toPath path) {};
      })
      (findPkgDirectory path)
    );

  findPkgDirectory = path: let
    dirs = filterAttrs (n: v: v == "directory") (builtins.readDir path);
  in
    if dirs != {}
    then
      flatten
      (mapAttrsToList
        (n: v: let
          dirPath = "${path}/${n}";
        in
          if builtins.pathExists "${dirPath}/default.nix"
          then dirPath
          else findPkgDirectory dirPath)
        dirs)
    else [];
}
