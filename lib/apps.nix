{
  lib,
  pkgs,
  unstable,
  inputs,
  dotfiles,
  username,
  scripts,
  mapper,
  ...
}: {
  desktopApps = config: cfg: let
    sourceDir = ./../modules/desktop/apps;
    appFiles =
      lib.attrsets.filterAttrs
      (n: v: ((lib.strings.hasSuffix ".nix" n) && v == "regular"))
      (builtins.readDir sourceDir);
  in
    lib.attrsets.mapAttrs' (n: _: {
      name = builtins.replaceStrings [".nix"] [""] n;
      value = import "${sourceDir}/${n}" {
        inherit cfg pkgs unstable dotfiles scripts config lib username inputs mapper;
      };
    })
    appFiles;
}
