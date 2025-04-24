{lib, ...}:
lib.singleton (final: prev: {
  mongodb-compass = prev.mongodb-compass.overrideAttrs (prevAttrs: {
    buildCommand =
      ''
        gappsWrapperArgs+=(
          --prefix XDG_CURRENT_DESKTOP : "GNOME"
        )
      ''
      + prevAttrs.buildCommand;
  });
})
