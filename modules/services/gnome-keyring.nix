{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib;
with lib.my; let
  cfg = config.modules.services.gnome-keyring;
  displayManagers = ["sddm" "gdm" "lightdm"];
in {
  options.modules.services.gnome-keyring = {
    enable = mkEnableOption "Enable GNOME keyring";
  };

  config = mkIf (cfg.enable) {
    security.pam.services = builtins.listToAttrs (builtins.map (name: {
        inherit name;
        value = {enableGnomeKeyring = config.services.xserver.displayManager.${name}.enable;};
      })
      displayManagers);
    services.gnome.gnome-keyring.enable = true;

    home-manager.users.${username}.systemd.user = {
      services."gnome-keyring-daemon" = {
        Unit = {
          Description = "GNOME Keyring daemon";
          Requires = ["gnome-keyring-daemon.socket"];
        };
        Service = {
          Type = "simple";
          StandardError = "journal";
          ExecStart = "${pkgs.gnome.gnome-keyring}/bin/gnome-keyring-daemon --foreground --components=\"pkcs11,secrets\" --control-directory=%t/keyring";
          Restart = "on-failure";
        };
        Install = {
          Also = ["gnome-keyring-daemon.socket"];
          WantedBy = ["default.target"];
        };
      };
      sockets."gnome-keyring-daemon" = {
        Unit = {
          Description = "GNOME Keyring daemon";
        };
        Socket = {
          Priority = 6;
          Backlog = 5;
          ListenStream = "%t/keyring/control";
          DirectoryMode = 0700;
        };
        Install = {
          WantedBy = ["sockets.target"];
        };
      };
    };
  };
}
