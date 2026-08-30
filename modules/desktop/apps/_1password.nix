{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  inherit (lib)
    mkIf
    getExe
    listToAttrs
    nameValuePair
    attrByPath
    ;
  inherit (lib.my.utils)
    recursiveReadSecretNames
    readSecrets
    mkSecretPlaceholder
    ;
  inherit (lib.my.mapper) toTOML;

  hmConfig = config.home-manager.users.${username};
  configDirectory = hmConfig.xdg.configHome;
  pkgs' = {
    gui = config.programs._1password-gui.package;
    cli = config.programs._1password.package;
  };

  base = "1password/ssh_agent";
  secretNames = recursiveReadSecretNames { inherit config base; };
  secrets = readSecrets { inherit config base; };
in
{
  sops = {
    templates = {
      "1password/agent.toml" = {
        mode = "0644";
        owner = username;
        path = "${configDirectory}/1Password/ssh/agent.toml";
        file = toTOML "agent.toml" {
          ssh-keys = map (
            entry:
            builtins.mapAttrs (
              slot: _:
              mkSecretPlaceholder config [
                base
                entry
                slot
              ]
            ) (attrByPath [ entry ] { } secrets)
          ) (builtins.attrNames secrets);
        };
      };
    };
    secrets = listToAttrs (map (v: nameValuePair v { }) secretNames);
  };

  programs = {
    _1password = {
      enable = true;
      package = pkgs._1password-cli;
    };
    _1password-gui = {
      enable = true;
      polkitPolicyOwners = [ username ];
      package = pkgs._1password-gui-beta;
    };
  };

  # Autostart service
  systemd.user.services."1password" = {
    description = "Launch 1Password";
    script = "${getExe pkgs'.gui} --silent";

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
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 3"; # Make sure tray is visible
    };
  };

  home-manager.users.${username} = {
    programs = {
      git = mkIf config.modules.dev.git.enable {
        signing = {
          signByDefault = true;
          key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEcrcFZPwdfoZb0ZP3SUr/ZgN6Hycpk57Ky1UMmPbAg8";
        };

        settings.gpg = {
          format = "ssh";
          ssh.program = "${pkgs'.gui}/bin/op-ssh-sign";
        };
      };

      ssh = {
        enable = true;
        extraConfig = "IdentityAgent ~/.1password/agent.sock";
      };

      _1password-shell-plugins = {
        enable = true;
        package = pkgs'.cli;
        plugins = with pkgs; [
          gh
        ];
      };
    };

    wayland.windowManager.hyprland.settings =
      let
        inherit (lib.my.utils.hypr) mkBind dsp;
      in
      mkIf config.modules.desktop.wm.hyprland.enable {
        bind = [
          (mkBind "CTRL + SHIFT + O" (dsp.exec "${getExe pkgs'.gui} --toggle"))
          (mkBind "CTRL + SHIFT + L" (dsp.exec "${getExe pkgs'.gui} --lock"))
          (mkBind "CTRL + SHIFT + Backslash" (dsp.exec "${getExe pkgs'.gui} --fill"))
        ];

        window_rule = [
          {
            name = "1Password";
            center = true;
            allows_input = true;
            # inherit monitor;
            match.class = "1Password";
          }
        ];
      };
  };
}
