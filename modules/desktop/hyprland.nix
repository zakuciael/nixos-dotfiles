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
  workspaceOptions = with types; {
    selector = mkOption {
      type = str;
      description = "Workspace selector";
    };
    monitor = mkOption {
      type = nullOr str;
      description = "Binds the workspace to the specific monitor";
      default = null;
    };
    default = mkOption {
      type = nullOr bool;
      description = "Makes the workspace default";
      default = null;
    };
    rules = mkOption {
      type = listOf str;
      description = "Additional rules added to the workspace";
      default = [];
    };
    binds = mkOption {
      type = listOf (submodule {
        options = {
          mods = mkOption {
            type = nullOr str;
            description = "A modifier key used for the binding";
            default = null;
          };
          key = mkOption {
            type = str;
            description = "A key name used for the binding";
          };
        };
      });
      description = "A list of keybinds used to access this workspace";
      default = [];
    };
  };
  workspaces = let
    mkWorkspace = workspace:
      concatStrings [
        workspace.selector
        (optionalString (!builtins.isNull workspace.monitor) ",monitor:${workspace.monitor}")
        (optionalString (!builtins.isNull workspace.default) ",default:${
          if workspace.default
          then "true"
          else "false"
        }")
        (optionalString (workspace.rules != []) (concatStrings (builtins.map (val: ",${val}") workspace.rules)))
      ];
  in
    builtins.map mkWorkspace cfg.settings.workspaces;
  workspaceBinds = let
    mkWorkspaceBinds = workspace:
      builtins.map (bind: "${optionalString (!builtins.isNull bind.mods) bind.mods},${bind.key},workspace,${workspace.selector}")
      workspace.binds;
  in
    flatten (builtins.map mkWorkspaceBinds cfg.settings.workspaces);
in {
  options.modules.desktop.hyprland = {
    enable = mkEnableOption "Enable hyprland desktop";
    settings = mkOption {
      type = with types;
        submodule {
          options = {
            workspaces = mkOption {
              type = listOf (submodule {options = workspaceOptions;});
              description = "A list of workspaces to automatically setup";
              default = [];
              example = [
                {
                  selector = "1";
                  monitor = "DP-1";
                  default = true;
                }
                {
                  selector = "r[2-4]";
                  monitor = "DP-1";
                }
              ];
            };
          };
        };
    };
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
            # Input settings
            input = {
              kb_layout = config.services.xserver.layout;
            };

            # Workspaces
            workspace = workspaces;

            # Autostart programs
            "exec-once" = builtins.map (program: program.cmd) (builtins.filter (program: program.once) cfg.autostart.programs);
            exec = builtins.map (program: program.cmd) (builtins.filter (program: !program.once) cfg.autostart.programs);

            # Keybinds
            "$mod" = "SUPER";
            bind =
              [
                "$mod, return, exec, alacritty"
                "$mod, W, killactive"
                "SHIFT CTRL, space, exec, ${launcherScript}/bin/rofi-launcher drun"
                "SHIFT CTRL, Q, exec, ${powermenuScript}/bin/rofi-powermenu"
              ]
              ++ workspaceBinds;
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
