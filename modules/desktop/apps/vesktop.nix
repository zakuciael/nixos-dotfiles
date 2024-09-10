{
  config,
  lib,
  unstable,
  username,
  desktop,
  ...
}:
with lib;
with lib.my;
with lib.my.utils; let
  vesktop = unstable.vesktop;
  leftLayout = findLayoutConfig config ({name, ...}: name == "left"); # Try and find left monitor
  # Left monitor or main if not found
  layout =
    if leftLayout != null
    then leftLayout
    else findLayoutConfig config ({name, ...}: name == "main");
  # Default workspace or if left monitor was not found last workspace
  workspace =
    if leftLayout != null
    then findLayoutWorkspace layout ({default, ...}: default)
    else findLayoutWorkspace layout ({last, ...}: last);
  class = "^(vesktop)$";
in {
  modules.desktop.wm.${desktop}.autostartPrograms = [
    "${vesktop}/bin/vesktop"
  ];

  home-manager.users.${username} = {
    home.packages = [vesktop];

    wayland.windowManager.hyprland.settings = mkIf (config.modules.desktop.wm.hyprland.enable) {
      windowrulev2 = [
        "workspace ${workspace.name}, class:${class}"
        "noinitialfocus, class:${class}"
      ];
    };
  };
}
