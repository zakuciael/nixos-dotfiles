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
    enable = mkEnableOption "GNOME keyring";
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
        };
        Service = {
          Type = "simple";
          StandardError = "journal";
          ExecStart = ''${pkgs.gnome.gnome-keyring}/bin/gnome-keyring-daemon --start --components="pkcs11,secrets"'';
          Restart = "on-failure";
        };
        Install = {
          WantedBy = ["graphical-session.target"];
        };
      };
    };
  };
}
