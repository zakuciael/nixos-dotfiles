{ lib, ... }:
lib.singleton (
  final: prev: {
    vlc-wayland = final.symlinkJoin {
      name = "vlc";
      paths = [ prev.vlc ];
      buildInputs = [ final.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/vlc \
          --unset DISPLAY
        mv $out/share/applications/vlc.desktop{,.orig}
        substitute $out/share/applications/vlc.desktop{.orig,} \
          --replace-fail Exec=${prev.vlc}/bin/vlc Exec=$out/bin/vlc
      '';
    };
  }
)
