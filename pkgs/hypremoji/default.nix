{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  wrapGAppsHook4,
  makeWrapper,
  gtk4,
  glib,
  writeShellScript,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "hypremoji";
  version = "1.2.0";

  src = fetchFromGitHub {
    owner = "Musagy";
    repo = "hypremoji";
    rev = "8110ff216d3696a28f08fad3becaca5e83ae580d";
    hash = "sha256-om2kAYQ9KJQ+FVbLh7rLnBkr4B5H41e3T3y9IPlx6Nk=";
  };

  cargoLock = {
    lockFile = ./Cargo.lock;
  };

  nativeBuildInputs = [
    pkg-config
    wrapGAppsHook4
    makeWrapper
  ];

  buildInputs = [
    gtk4
    glib
  ];

  postInstall = ''
    install -dm755 $out/share/hypremoji/bin
    mv $out/bin/hypremoji $out/share/hypremoji/bin/hypremoji

    cp -r $src/assets $out/share/hypremoji/assets
    cp -r $src/config/* $out/share/hypremoji/

    # makeWrapper $out/share/hypremoji/bin/hypremoji $out/bin/hypremoji

    makeWrapper $out/share/hypremoji/bin/hypremoji $out/bin/hypremoji \
      --run '
        cfg="''${XDG_CONFIG_HOME:-$HOME/.config}/hypremoji"
        store_base="'"$out/share/hypremoji"'"

        # Seed the user config dir from store defaults on first run, or when
        # new default files appear after an upgrade.  chmod +w so the app can
        # overwrite them freely (store copies are read-only 444).
        mkdir -p "$cfg"
        for f in "$store_base"/*.json "$store_base"/*.css; do
          [ -e "$f" ] || continue
          dest="$cfg/$(basename "$f")"
          if [ ! -e "$dest" ]; then
            cp "$f" "$dest"
            chmod 644 "$dest"
          fi
        done
      '
  '';

  postPatch = ''
    ln -s ${./Cargo.lock} Cargo.lock
  '';

  meta = with lib; {
    description = "Lightweight and fast emoji picker for the Hyprland window manager, built with GTK4 and Rust";
    homepage = "https://github.com/Musagy/hypremoji";
    license = licenses.isc;
    maintainers = [ ];
    platforms = platforms.linux;
    mainProgram = "hypremoji";
  };
})
