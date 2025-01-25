final: prev:
let
  inherit (final.lib) makeLibraryPath;
  inherit (final) makeWrapper libGL;
in
{
  imhex = prev.imhex.overrideAttrs (attrs: {
    nativeBuildInputs = attrs.nativeBuildInputs ++ [ makeWrapper ];

    postInstall =
      attrs.postInstall
      + ''
        wrapProgram $out/bin/imhex \
          --prefix LD_LIBRARY_PATH : "${makeLibraryPath [ libGL ]}"
      '';
  });
}
