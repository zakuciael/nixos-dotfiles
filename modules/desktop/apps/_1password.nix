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
  systemd.user.services."_1password-autostart" = {
    description = "Launch 1Password at startup";
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
      PassEnvironment = [
        "DISPLAY"
        "WAYLAND_DISPLAY"
        "XAUTHORITY"
      ];
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

    wayland.windowManager.hyprland = mkIf config.modules.desktop.wm.hyprland.enable {
      settings = {
        bind = [
          "Ctrl Shift, O, exec, ${getExe pkgs'.gui} --toggle"
          "Ctrl Shift, L, exec, ${getExe pkgs'.gui} --lock"
          "Ctrl Shift, \, exec, ${getExe pkgs'.gui} --fill"
        ];

        windowrule = [
          {
            name = "1Password";
            center = true;
            allows_input = true;
            # inherit monitor;
            "match:class" = "1Password";
          }
        ];
      };

      # Uncomment if needing quick-access
      /*
        extraConfig = ''
          bind = Ctrl Shift, P, exec, ${getExe pkgs'.gui} --quick-access
          bind = Ctrl Shift, P, submap, 1pass

          submap = 1pass
          bind = Ctrl Shift, P, closewindow, class:^(${class})$
          bind = Ctrl Shift, P, submap, reset

          submap = reset
        '';
      */
    };
  };
}
