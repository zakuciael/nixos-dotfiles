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
  layout = findLayoutConfig config ({index, ...}: index == 0); # Left monitor
  workspace = findLayoutWorkspace layout ({default, ...}: default); # Default workspace
in {
  modules.desktop.wm.${desktop}.autostartPrograms = [
    "${vesktop}/bin/vesktop"
  ];

  home-manager.users.${username} = {
    home.packages = [vesktop];

    wayland.windowManager.hyprland.settings = mkIf (config.modules.desktop.wm.hyprland.enable) {
      windowrulev2 = [
        "workspace ${workspace.name}, class:^(vesktop)$"
        "noinitialfocus, class:^(vesktop)$"
      ];
    };
  };
}
