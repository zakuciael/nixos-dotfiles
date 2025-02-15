{
  lib,
  pkgs,
  inputs,
  username,
  dotfiles,
  ...
}:
with lib;
with lib.my; let
  mkScripts = config:
    builtins.filter (value: hasAttrByPath ["package"] value) (
      builtins.map
      (file: import file {inherit config lib pkgs inputs username dotfiles;})
      (utils.recursiveReadDir ./../scripts {suffixes = ["nix"];})
    );
in {
  mkShellExports = config:
    builtins.map
    (getAttr "package")
    (builtins.filter (script: attrByPath ["export"] false script) (mkScripts config));
  mkScriptPackages = config:
    builtins.listToAttrs (builtins.map (script: {
        name = script.package.name;
        value = script.package;
      })
      (mkScripts config));
}
