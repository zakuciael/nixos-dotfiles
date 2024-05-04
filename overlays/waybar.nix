{
  lib,
  inputs,
  ...
}:
with lib; {
  unstable = singleton inputs.waybar.overlays.default;
}
