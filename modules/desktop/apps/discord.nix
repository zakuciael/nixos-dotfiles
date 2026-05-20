{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  inherit (lib) getExe mkIf;
  inherit (lib.my.utils) findLayoutConfig findLayoutWorkspace;
  pkg = pkgs.discord.override {
    # TODO: Re-enable when this issue is resolved: https://github.com/NixOS/nixpkgs/issues/515106
    # withOpenASAR = true;
    withKrisp = true;
  };
  leftLayout = findLayoutConfig config ({ name, ... }: name == "left"); # Try and find left monitor
  # Left monitor or main if not found
  layout =
    if leftLayout != null then leftLayout else findLayoutConfig config ({ name, ... }: name == "main");
  # Default workspace or if left monitor was not found last workspace
  workspace =
    if leftLayout != null then
      findLayoutWorkspace layout ({ default, ... }: default)
    else
      findLayoutWorkspace layout ({ last, ... }: last);
in
{
  # Autostart service
  systemd.user.services."discord-autostart" = {
    description = "Launch Discord at startup";
    script = "${getExe pkg}";

    after = [
      "graphical-session.target"
      "tray.target"
    ];
    requires = [ "graphical-session.target" ];
    wants = [ "tray.target" ];
    wantedBy = [ "graphical-session.target" ];

    unitConfig.ConditionEnvironment = "WAYLAND_DISPLAY";

    serviceConfig = {
      Restart = "on-failure";
      RestartSec = 5;
      PassEnvironment = [
        "DISPLAY"
        "WAYLAND_DISPLAY"
        "XAUTHORITY"
      ];
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 3"; # Make sure tray is visible
    };
  };

  home-manager.users.${username} = {
    home.packages = [ pkg ];

    wayland.windowManager.hyprland.settings = mkIf config.modules.desktop.wm.hyprland.enable {
      windowrule = [
        {
          name = "Discord";
          workspace = "${workspace.name} silent";
          no_initial_focus = true;
          suppress_event = "activate activatefocus";
          "match:class" = "^(discord)$";
        }
      ];
    };
  };
}
