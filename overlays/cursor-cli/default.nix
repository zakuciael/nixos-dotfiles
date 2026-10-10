{ lib, ... }:
# https://github.com/cursor/cookbook/issues/42
{
  overlays = lib.singleton (
    _: prev: {
      cursor-cli = prev.cursor-cli.overrideAttrs (old: {
        postInstall = (old.postInstall or "") + ''
          ln -s ../share/cursor-agent/cursorsandbox "$out/bin/cursorsandbox"
        '';
      });
    }
  );
}
