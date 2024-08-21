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
  leftLayout = findLayoutConfig config ({name, ...}: name == "left"); # Left monitor
  layout =
    if leftLayout != null
    then leftLayout
    else findLayoutConfig config ({name, ...}: name == "main"); # Left monitor or main if not found
  workspace = findLayoutWorkspace layout ({default, ...}: default); # Default workspace
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
