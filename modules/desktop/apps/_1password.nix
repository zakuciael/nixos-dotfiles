{
  config,
  lib,
  pkgs,
  inputs,
  username,
  desktop,
  ...
}:
with lib;
with lib.my;
with lib.my.utils; let
  layout = findLayoutConfig config ({index, ...}: index == 1); # Main monitor
  monitor = getLayoutMonitor layout "wayland";
  class = "1Password";
in {
  programs = {
    _1password.enable = true;
    _1password-gui = {
      enable = true;
      polkitPolicyOwners = [username];
    };

    fish.interactiveShellInit = ''
      source $HOME/.config/op/plugins.sh
    '';
  };

  environment.systemPackages = [inputs.age-plugin-op.default];

  modules.desktop.wm.${desktop}.autostartPrograms = [
    "${pkgs._1password-gui}/bin/1password"
  ];

  sops.secrets = {
    "1password/ssh_agent" = {
      mode = "0440";
      group = config.users.groups.keys.name;
    };
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
          gpg.ssh.program = "${pkgs._1password-gui}/bin/op-ssh-sign";
        };
      };

      ssh = {
        enable = true;
        extraConfig = "IdentityAgent ~/.1password/agent.sock";
      };
    };

    xdg.configFile."1Password/ssh/agent.toml" = {
      source =
        config.home-manager.users.${username}.lib.file.mkOutOfStoreSymlink
        config.sops.secrets."1password/ssh_agent".path;
    };

    wayland.windowManager.hyprland = mkIf (config.modules.desktop.wm.hyprland.enable) {
      settings = {
        bind = [
          "Ctrl Shift, O, exec, 1password --toggle"
          "Ctrl Shift, L, exec, 1password --lock"
        ];

        windowrulev2 = [
          "float, class:(${class})"
          "center, class:(${class})"
          "monitor ${monitor}, class:(${class})"
          # "stayfocused,class:^(${class})$"
          "forceinput,class:^(${class})$"
          "windowdance,class:^(${class})$"
          "noblur,class:^(${class})$"
          "noinitialfocus,class:^(${class})$"
          "dimaround,class:^(${class})$"
        ];
      };

      extraConfig = ''
        bind = Ctrl Shift, P, exec, 1password --quick-access
        bind = Ctrl Shift, P, submap, 1pass

        submap = 1pass
        bind = Ctrl Shift, P, closewindow, class:^(${class})$
        bind = Ctrl Shift, P, submap, reset

        submap = reset
      '';
    };
  };
}
