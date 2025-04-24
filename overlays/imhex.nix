{lib, ...}:
lib.singleton (final: prev: {
  imhex = prev.imhex.overrideAttrs (prevAttrs: {
    nativeBuildInputs = prevAttrs.nativeBuildInputs ++ [final.makeWrapper];

    postInstall =
      prevAttrs.postInstall
      + ''
        wrapProgram $out/bin/imhex \
          --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [final.libGL]}"
      '';
  });
})
