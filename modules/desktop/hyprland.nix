{
  pkgs,
  lib,
  config,
  inputs,
  system,
  username,
  scripts,
  ...
}:
with lib;
with lib.my; let
  cfg = config.modules.desktop.hyprland;
  desktopApps = apps.desktopApps config cfg;
  launcherScript = import scripts."rofi-launcher.nix".source {inherit pkgs inputs;};
  powermenuScript = import scripts."rofi-powermenu.nix".source {inherit pkgs inputs;};
in {
  options.modules.desktop.hyprland = {
    enable = mkEnableOption "Enable hyprland desktop";
    autostart.programs = mkOption {
      type = with types;
        listOf (coercedTo str (cmd: {inherit cmd;}) (submodule {
          options = {
            cmd = mkOption {
              type = str;
              description = "A command to execute to start the program";
            };
            once = mkOption {
              type = bool;
              default = true;
              description = "If the program should only be executed on launch";
            };
          };
        }));
      description = "A list of programs to autostart when Hyprland loads";
      default = [];
      example = [
        "${pkgs.discord}/bin/discord"
        {
          cmd = "${pkgs.nitrogen}/bin/nitrogen --restore";
          once = false;
        }
      ];
    };
  };

  config = mkIf (cfg.enable) (mkMerge (with desktopApps; [
    alacritty
    _1password
    rofi
    nh
    {
      programs.hyprland = {
        enable = true;
        package = inputs.hyprland.packages.${system}.hyprland;
        xwayland.enable = true;
      };

      home-manager.users.${username} = {
        imports = [inputs.hyprland.homeManagerModules.default];

        wayland.windowManager.hyprland = {
          enable = true;

          settings = {
            "$mod" = "SUPER";
            "exec-once" = builtins.map (program: program.cmd) (builtins.filter (program: program.once) cfg.autostart.programs);
            exec = builtins.map (program: program.cmd) (builtins.filter (program: !program.once) cfg.autostart.programs);

            bind = [
              "$mod, return, exec, alacritty"
              "$mod, W, killactive"
              "SHIFT CTRL, space, exec, ${launcherScript}/bin/rofi-launcher drun"
              "SHIFT CTRL, Q, exec, ${powermenuScript}/bin/rofi-powermenu"
            ];
            bindm = [
              "$mod, mouse:272, movewindow"
              "$mod, mouse:273, resizewindow"
            ];
          };
        };
      };
    }
  ]));
}
