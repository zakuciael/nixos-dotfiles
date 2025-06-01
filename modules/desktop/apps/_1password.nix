{
  config,
  lib,
  pkgs,
  username,
  desktop,
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

  class = "1Password";

  base = "1password/ssh_agent";
  secretNames = recursiveReadSecretNames { inherit config base; };
  secrets = readSecrets { inherit config base; };
in
{
  programs = {
    _1password = {
      enable = true;
      package = pkgs._1password-cli-beta;
    };
    _1password-gui = {
      enable = true;
      polkitPolicyOwners = [ username ];
      package = pkgs._1password-gui.override {
        channel = "beta";
      };
    };

    fish.interactiveShellInit = ''
      source ${configDirectory}/op/plugins.sh
    '';
  };

  modules.desktop.wm.${desktop}.autostartPrograms = [
    "${getExe pkgs'.gui}"
  ];

  sops = {
    templates = {
      "1password/agent.toml" = {
        mode = "0644";
        owner = username;
        path = "${configDirectory}/1Password/ssh/agent.toml";
        file = toTOML "agent.toml" {
          ssh-keys = builtins.map (
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
    secrets = listToAttrs (builtins.map (v: nameValuePair v { }) secretNames);
  };

  home-manager.users.${username} = {
    programs = {
      git = mkIf (config.modules.dev.git.enable) {
        signing = {
          signByDefault = true;
          key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEcrcFZPwdfoZb0ZP3SUr/ZgN6Hycpk57Ky1UMmPbAg8";
        };

        extraConfig = {
          gpg.format = "ssh";
          gpg.ssh.program = "${pkgs'.gui}/bin/op-ssh-sign";
        };
      };

      ssh = {
        enable = true;
        extraConfig = "IdentityAgent ~/.1password/agent.sock";
      };
    };

    wayland.windowManager.hyprland = mkIf (config.modules.desktop.wm.hyprland.enable) {
      settings = {
        bind = [
          "Ctrl Shift, O, exec, ${getExe pkgs'.gui} --toggle"
          "Ctrl Shift, L, exec, ${getExe pkgs'.gui} --lock"
          "Ctrl Shift, \, exec, ${getExe pkgs'.gui} --fill"
        ];

        windowrulev2 = [
          "center, class:(${class})"
          # "monitor ${monitor}, class:(${class})"
          "allowsinput on,class:^(${class})$"
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
