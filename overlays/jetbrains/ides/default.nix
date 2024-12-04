{lib, ...}: let
in [
  (final: prev: let
    inherit (lib) optionalString;
  in {
    jetbrains =
      prev.jetbrains
      // {
        goland = prev.jetbrains.goland.overrideAttrs (attrs: {
          postFixup =
            (attrs.postFixup or "")
            + optionalString final.stdenv.isLinux ''
              if [ -f $out/goland/plugins/go-plugin/lib/dlv/linux/dlv ]; then
                rm $out/goland/plugins/go-plugin/lib/dlv/linux/dlv
              fi

              ln -s ${final.delve}/bin/dlv $out/goland/plugins/go-plugin/lib/dlv/linux/dlv
            '';
        });
      };
  })
  (final: prev: {
    jetbrains =
      prev.jetbrains // {};
  })
]
