{
  config,
  lib,
  username,
  ...
}:
with lib;
with lib.my; let
  cfg = config.modules.hardware.layout;

  monitorRotations = {
    normal = "0";
    left = "1";
    right = "4";
  };
in {
  options.modules.hardware.layout = {
    enable = mkEnableOption "monitor layout";
    layout = mkOption {
      description = "Monitor layout that should be set in the supported WMs.";
      example = [
        {
          name = "main";
          monitor = {
            xorg = "DisplayPort-0";
            wayland = "DP-1";
          };
          primary = true;
          mode = "1920x1080";
          pos = {
            x = 0;
            y = 0;
          };
          rotate = "normal";
          wallpaper = "$HOME/Pictures/Wallpapers/unixporn.png";
          workspaces = {
            "1" = {
              keybinds = ["1" "KP_End"];
              extraConfig = {
                persistent = true;
              };
            };
            "2".keybinds = ["2" "KP_Down"];
          };
        }
      ];
      default = [];
      type = with types;
        listOf (submodule {
          options = {
            monitor = defs.monitor;
            name = mkOption {
              description = "Monitor common name used to identify it in layout";
              example = "main";
              type = str;
            };
            primary = mkOption {
              description = "Whether to mark this monitor as primary.";
              example = true;
              default = false;
              type = bool;
            };
            mode = mkOption {
              description = "Monitor preferred resolution.";
              example = "1920x1080";
              default = null;
              type = nullOr str;
            };
            pos = mkOption {
              description = "Monitor position.";
              example = {
                x = 0;
                y = 0;
              };
              default = null;
              type = nullOr (submodule {
                options = {
                  x = mkOption {
                    description = "The X coordinate";
                    example = 0;
                    type = int;
                  };
                  y = mkOption {
                    description = "The Y coordinate";
                    example = 0;
                    type = int;
                  };
                };
              });
            };
            rotate = mkOption {
              description = "Monitor rotation.";
              example = "normal";
              default = null;
              type = nullOr (enum (mapAttrsToList (name: _: name) monitorRotations));
            };
            wallpaper = mkOption {
              description = "Monitor wallpaper.";
              example = "$HOME/Pictures/Wallpapers/the_storm_is_approaching.png";
              default = null;
              type = nullOr path;
            };
            workspaces = mkOption {
              description = "Monitor workspace definitions.";
              example = {
                "1" = {
                  keybinds = ["1" "KP_End"];
                  default = true;
                  extraConfig = {
                    persistent = true;
                  };
                };
                "2".keybinds = ["2" "KP_Down"];
              };
              default = {};
              type = attrsOf (submodule {
                options = {
                  keybinds = mkOption {
                    description = "List of keybinds assigned to the workspace.";
                    example = ["1" "KP_End"];
                    type = listOf str;
                  };
                  default = mkOption {
                    description = "Whether to mark this workspace as default for the monitor.";
                    example = true;
                    default = false;
                    type = bool;
                  };
                  extraConfig = mkOption {
                    description = "Extra workspace configuration.";
                    example = {
                      persistent = true;
                    };
                    default = {};
                    type = attrs;
                  };
                };
              });
              apply = workspaces: let
                hasDefault = builtins.any (builtins.getAttr "default") (builtins.attrValues workspaces);
                firstName = builtins.head (builtins.attrNames workspaces);
                newWorkspaces = recursiveUpdate workspaces {${firstName}.default = true;};
              in
                if workspaces != {} && !hasDefault
                then newWorkspaces
                else workspaces;
            };
          };
        });
      apply = layouts: let
        hasPrimary = builtins.any (x: x.primary) layouts;
        firstPrimary = builtins.head layouts // {primary = true;};
        newLayouts = singleton firstPrimary ++ builtins.tail layouts;
      in
        if layouts != [] && !hasPrimary
        then newLayouts
        else layouts;
    };
  };

  config = mkIf (cfg.enable) {
    home-manager.users.${username} = {
      # Hyprland monitor, workspace and binds configuration
      wayland.windowManager.hyprland.settings = mkIf (config.programs.hyprland.enable) {
        monitor =
          if cfg.layout == []
          then [",preferred,auto,1"]
          else
            builtins.map (
              layout: let
                monitor = layout.monitor.wayland;
                mode =
                  if (layout.mode != null)
                  then layout.mode
                  else "preferred";
                pos =
                  if (layout.pos != null)
                  then "${toString layout.pos.x}x${toString layout.pos.y}"
                  else "auto"; # TODO: Check if `auto-right` can be used
                scale = "1";
                transform = optionalString (layout.rotate != null) ",transform,${monitorRotations.${layout.rotate}}";
              in ''${monitor},${mode},${pos},${scale}${transform}''
            )
            cfg.layout;
        workspace = let
          disallowedExtraConfigs = ["default" "monitor"];
          workspaceDefs = flatten (builtins.map (layout: (mapAttrsToList (name: value: {
              inherit name;
              rules = lib.attrsets.mergeAttrsList [
                {monitor = layout.monitor.wayland;}
                (
                  if (value.default)
                  then {inherit (value) default;}
                  else {}
                )
                (
                  let
                    hasDisallowedExtraArgs = builtins.all (key: !(value.extraConfig ? "${key}")) disallowedExtraConfigs;
                    usedDisallowedExtraArgs = builtins.map (x: ''"${x}"'') (builtins.filter (key: value.extraConfig ? "${key}") disallowedExtraConfigs);
                  in
                    assert assertMsg
                    hasDisallowedExtraArgs
                    ''workspaces."${name}".extraConfig cannot override the following rules: [${concatStringsSep ", " usedDisallowedExtraArgs}]'';
                      value.extraConfig
                )
              ];
            })
            layout.workspaces))
          cfg.layout);
          mkRules = rules: concatStringsSep "," (mapAttrsToList (name: value: "${name}:${mapper.toString value}") rules);
        in
          builtins.map (config: ''${config.name},${mkRules config.rules}'') workspaceDefs;

        bind = let
          keybindDefs = lib.flatten (builtins.map (layout:
            lib.mapAttrsToList (workspace: value: {
              inherit workspace;
              inherit (value) keybinds;
            })
            layout.workspaces)
          cfg.layout);
        in
          lib.flatten (builtins.map (config:
            builtins.map (key: [
              ''$mod, ${key}, workspace, ${config.workspace}''
              ''$mod SHIFT, ${key}, movetoworkspace, ${config.workspace}''
            ])
            config.keybinds)
          keybindDefs);
      };
    };

    # Configure per-monitor wallpapers
    modules.services.wallpaper.settings = builtins.map (layout: {
      inherit (layout) monitor wallpaper;
    }) (builtins.filter (layout: layout.wallpaper != null) cfg.layout);

    # Xorg monitor layout
    services.xserver = mkIf (config.services.xserver.enable && cfg.layout != []) (let
      heads =
        builtins.map (layout: {
          inherit (layout) name;
          inherit layout;
        })
        cfg.layout;
    in {
      deviceSection = concatLines (
        (builtins.map (x: ''Option "monitor-${x.layout.monitor.xorg}" "${x.name}"'') heads)
        ++ [''Option "DRI" "3"'']
      );
      extraConfig = with lib; let
        mkMonitorSection = prev: curr:
          (singleton {
            inherit (curr) name;
            value = let
              primary = optionalString (curr.layout.primary) ''Option "Primary" "true"'';
              mode = optionalString (curr.layout.mode != null) ''
                Option "Mode" "${curr.layout.mode}"
                  Option "PreferredMode" "${curr.layout.mode}"
              '';
              pos =
                if (curr.layout.pos != null)
                then ''Option "Position" "${toString curr.layout.pos.x} ${toString curr.layout.pos.y}"''
                else (optionalString (prev != []) ''Option "RightOf" "${(builtins.head prev).name}"'');
              rotate = optionalString (curr.layout.rotate != null) ''Option "Rotate" "${curr.layout.rotate}"'';
            in ''
              Section "Monitor"
              Identifier "${curr.name}"
                ${primary}
                ${mode}
                ${pos}
                ${rotate}
              EndSection
            '';
          })
          ++ prev;
      in
        concatMapStrings (getAttr "value") (reverseList (foldl mkMonitorSection [] heads));
      exportConfiguration = true;
    });
  };
}
