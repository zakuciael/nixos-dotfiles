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

  home-manager.users.${username} = {
    programs = {
      git = mkIf (config.modules.dev.git.enable) {
        extraConfig = {
          commit.gpgsign = true;
          gpg.format = "ssh";
          gpg.ssh.program = "${pkgs._1password-gui}/bin/op-ssh-sign";
          user.signingkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEcrcFZPwdfoZb0ZP3SUr/ZgN6Hycpk57Ky1UMmPbAg8";
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
          "Ctrl Shift, O, exec, 1password --toggle"
          "Ctrl Shift, L, exec, 1password --lock"
        ];

        windowrulev2 = [
          "float, class:(1Password)"
          "center, class:(1Password)"
          "monitor ${monitor}, class:(1Password)"
          # "stayfocused,class:^(1Password)$"
          "forceinput,class:^(1Password)$"
          "windowdance,class:^(1Password)$"
          "noblur,class:^(1Password)$"
          "noinitialfocus,class:^(1Password)$"
          "dimaround,class:^(1Password)$"
        ];
      };

      extraConfig = ''
        bind = Ctrl Shift, P, exec, 1password --quick-access
        bind = Ctrl Shift, P, submap, 1pass

        submap = 1pass
        bind = Ctrl Shift, P, closewindow, class:^(1Password)$
        bind = Ctrl Shift, P, submap, reset

        submap = reset
      '';
    };
  };
}
