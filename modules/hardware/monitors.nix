{
  pkgs,
  lib,
  config,
  home-manager,
  username,
  ...
}:
with lib;
with lib.my; let
  cfg = config.modules.hardware.monitors;
  hyprlandMonitorLayout = let
    transforms = {
      normal = "0";
      left = "1";
      right = "4";
    };
    mkTransform = rotate: ''transform,${
        if transforms ? "${rotate}"
        then transforms.${rotate}
        else transforms.normal
      }'';
  in
    forEach cfg.layout (config:
      lib.debug.traceVal ''
        ${config.output.wayland},${config.mode},${config.position},1${optionalString (config.rotate != "normal") ",${mkTransform config.rotate}"}
      '');
  xrandrHeads =
    imap1 (num: config: {
      name = "multihead${toString num}";
      inherit config;
    })
    cfg.layout;
  xrandrDeviceSection = let
    monitors = forEach xrandrHeads (h: ''
      Option "monitor-${h.config.output.xserver}" "${h.name}"
    '');
  in
    concatStrings monitors;
  xrandrMonitorSections = let
    mkMonitor = previous: current:
      singleton {
        inherit (current) name;
        value = ''
          Section "Monitor"
            Identifier "${current.name}"
            ${optionalString (current.config.primary) ''Option "Primary" "true"''}
            Option "Mode" "${current.config.mode}"
            Option "PreferredMode" "${current.config.mode}"
            Option "Position" "${builtins.replaceStrings ["x"] [" "] current.config.position}"
            ${optionalString (current.config.rotate != "normal") ''Option "Rotate" "${current.config.rotate}"''}
          EndSection
        '';
      }
      ++ previous;
    monitors = reverseList (foldl mkMonitor [] xrandrHeads);
  in
    concatMapStrings (getAttr "value") monitors;
  prefixStringLines = prefix: str:
    concatMapStringsSep "\n" (line: prefix + line) (splitString "\n" str);

  indent = prefixStringLines "  ";
in {
  options.modules.hardware.monitors = {
    enable = mkEnableOption "Enable X server monitor layout configuration";
    layout = mkOption {
      type = with types;
        listOf (submodule {
          options = {
            output = mkOption {
              type = submodule {
                options = {
                  xserver = mkOption {
                    type = str;
                  };

                  wayland = mkOption {
                    type = str;
                  };
                };
              };
            };

            primary = mkOption {
              type = bool;
              default = false;
            };

            mode = mkOption {
              type = str;
            };

            position = mkOption {
              type = str;
            };

            rotate = mkOption {
              type = enum [
                "normal"
                "left"
                "right"
              ];
              default = "normal";
            };
          };
        });
      apply = heads: let
        hasPrimary = any (x: x.primary) heads;
        firstPrimary = head heads // {primary = true;};
        newHeads = singleton firstPrimary ++ tail heads;
      in
        if heads != [] && !hasPrimary
        then newHeads
        else heads;
    };
  };

  config = mkIf (cfg.enable) {
    home-manager.users.${username} = {
      wayland.windowManager.hyprland.settings.monitor = mkIf (programs.hyprland.enable) hyprlandMonitorLayout;
    };

    services.xserver = mkIf (services.xserver.enable) {
      deviceSection = xrandrDeviceSection;
      extraConfig = xrandrMonitorSections;
      exportConfiguration = true;
    };
  };
}