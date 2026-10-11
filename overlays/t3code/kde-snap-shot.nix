{
  lib,
  rustPlatform,
  src,
  version,
  cargoHash,
}:

rustPlatform.buildRustPackage {
  pname = "t3-kde-snap-shot";
  inherit
    version
    src
    cargoHash
    ;

  sourceRoot = "${src.name}/native/kde-snap-shot";

  # Integration tests spawn dbus-daemon against a private bus; the Nix
  # sandbox does not provide that tooling by default.
  doCheck = false;

  meta = {
    description = "KDE Plasma window capture helper for T3 Code SnapShots";
    homepage = "https://t3.codes";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "t3-kde-snap-shot";
  };
}
