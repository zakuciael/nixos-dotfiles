{ lib, ... }:
{
  updateScript = "overlays/motrix/update.sh";

  overlays = lib.singleton (
    final: _prev: {
      motrix = final.callPackage ./package.nix { };
    }
  );
}
