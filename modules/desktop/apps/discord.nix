{
  config,
  lib,
  pkgs,
  username,
  desktop,
  ...
}: let
  inherit (lib) getExe mkIf;
  inherit (lib.my.utils) findLayoutConfig findLayoutWorkspace;
  pkg = pkgs.discord-canary.override {
    withOpenASAR = true;
  };
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
  class = "^(discord)$";
in {
  modules.desktop.wm.${desktop}.autostartPrograms = [
    "${getExe pkg}"
  ];

  home-manager.users.${username} = {
    home.packages = [pkg];

    wayland.windowManager.hyprland.settings = mkIf (config.modules.desktop.wm.hyprland.enable) {
      windowrulev2 = [
        "workspace ${workspace.name} silent, class:${class}"
        "noinitialfocus, class:${class}"
      ];
    };
  };
}
