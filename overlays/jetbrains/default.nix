{ lib, ... }:
{
  updateScript = "overlays/jetbrains/updater/main.py";

  overlays = lib.singleton (
    final: prev:
    let
      ideNames = [
        "clion"
        "datagrip"
        "dataspell"
        "goland"
        "intellij-idea"
        "jetbrains-gateway"
        "jetbrains-mps"
        "phpstorm"
        "pycharm"
        "rider"
        "ruby-mine"
        "rust-rover"
        "webstorm"
      ];

      # jetbrains.* alias names that differ from the by-name package attr.
      jetbrainsAliases = {
        gateway = "jetbrains-gateway";
        idea = "intellij-idea";
        mps = "jetbrains-mps";
      };

      packages = lib.genAttrs ideNames (
        name: final.callPackage (./packages + "/${name}/package.nix") { }
      );
    in
    packages
    // {
      jetbrains =
        prev.jetbrains
        // packages
        // lib.mapAttrs (_alias: pkgName: packages.${pkgName}) jetbrainsAliases;
    }
  );
}
