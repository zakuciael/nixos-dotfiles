{
  lib,
  rustPlatform,
  src,
  version,
  cargoHash,
}:

rustPlatform.buildRustPackage {
  pname = "t3-hyprland-snap-shot";
  inherit
    version
    src
    cargoHash
    ;

  sourceRoot = "${src.name}/native/hyprland-snap-shot";

  meta = {
    description = "Hyprland window capture helper for T3 Code SnapShots";
    homepage = "https://t3.codes";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "t3-hyprland-snap-shot";
  };
}
