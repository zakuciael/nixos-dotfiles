_: prev: {
  mongodb-compass = prev.mongodb-compass.overrideAttrs (attrs: {
    buildCommand =
      ''
        gappsWrapperArgs+=(
          --prefix XDG_CURRENT_DESKTOP : "GNOME"
        )
      ''
      + attrs.buildCommand;
  });
}
