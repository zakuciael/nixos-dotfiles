{lib, ...}:
with lib; rec {
  recursiveReadDir = path: {
    ignoredDirs ? [],
    suffixes ? [],
  } @ settings:
    builtins.filter (file: file != null) (flatten (
      mapAttrsToList (name: value: let
        newPath = "${path}/${name}";
      in
        if value == "regular"
        then
          if suffixes == [] || builtins.any (ext: hasSuffix ext newPath) suffixes
          then newPath
          else null
        else recursiveReadDir newPath settings)
      (
        filterAttrs (name: _:
          builtins.all (dir: name != dir) ignoredDirs)
        (builtins.readDir path)
      )
    ));
}
