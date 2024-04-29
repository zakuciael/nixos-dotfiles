{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib;
with lib.my; let
  cfg = config.modules.services.polkit;
in {
  options.modules.services.polkit = {
    enable = mkEnableOption "Enable polkit authentication manager";
  };

  config = mkIf (cfg.enable) {
    security.polkit.enable = true;

    home-manager.users.${username}.home.packages = with pkgs; [polkit_gnome];

    systemd.user.services."polkit-gnome-authentication-agent-1" = {
      description = "Polkit authentication manager";
      wantedBy = ["graphical-session.target"];
      wants = ["graphical-session.target"];
      after = ["graphical-session.target"];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };
  };
}
