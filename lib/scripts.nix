{
  lib,
  pkgs,
  unstable,
  inputs,
  dotfiles,
  ...
}:
with lib;
with lib.my; let
  scripts =
    builtins.map
    (file: import file {inherit lib pkgs unstable inputs dotfiles;})
    (utils.recursiveReadDir ./../scripts {suffixes = ["nix"];});
in {
  shellExports =
    builtins.map
    (getAttr "package")
    (builtins.filter (script: attrByPath ["export"] false script) scripts);
  packages = builtins.listToAttrs (builtins.map (script: {
      name = script.package.name;
      value = script.package;
    })
    scripts);
}
