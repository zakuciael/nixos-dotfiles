{
  config,
  lib,
  pkgs,
  username,
  colorScheme,
  ...
}:
with lib;
with lib.my;
with lib.my.utils; let
  layout = findLayoutConfig config ({name, ...}: name == "main"); # Main monitor
  monitor = getLayoutMonitor layout "wayland";
in {
  home-manager.users.${username} = {
    home.packages = with pkgs; [swaynotificationcenter];

    xdg.configFile = {
      "swaync/config.json".source = mapper.toJSON "config.json" {
        "$schema" = "${pkgs.swaynotificationcenter}/etc/xdg/swaync/configSchema.json";
        positionX = "right";
        positionY = "top";
        cssPriority = "user";
        output = monitor;

        timeout = 4;
        timeout-low = 2;
        timeout-critical = 6;

        fit-to-screen = false;
        keyboard-shortcuts = true;
        image-visibility = "when-available";
        transition-time = 200;
        hide-on-clear = false;
        hide-on-action = false;
        script-fail-notify = true;

        notification-window-width = 400;
        notification-body-image-height = 160;
        notification-body-image-width = 200;
        notification-icon-size = 48;
      };

      # TODO: Make styles for Control Center
      "swaync/style.css".text = let
        colorDefs = concatLines (builtins.map
          (attr: ''@define-color ${attr.name} #${attr.value};'')
          (lib.attrsToList colorScheme.palette));
      in ''
        ${colorDefs}

        .floating-notifications.background * {
          color: @base05;

          all: unset;
          font-size: 14px;
          font-family: "JetBrains Mono Nerd Font 10";
          transition: 200ms;
        }

        .floating-notifications.background .notification-row {
          outline: none;
          margin: 8px 8px 0 0px;
          padding: 0px;
        }

        .floating-notifications.background .notification-row .notification-background {
          background: alpha(@base01, .55);
          box-shadow: 0 0 8px 0 rgba(0,0,0,.6);
          border: 1px solid @base03;
          border-radius: 12px;
          margin-bottom: 10px;
        }

        .floating-notifications.background .notification-row .notification-background .notification {
          /* margin: 5px; */
          padding: 10px;
          border-radius: 12px;
        }

        .floating-notifications.background .notification-row .notification-background .notification.critical {
          border: 1px solid @base08;
        }

        .floating-notifications.background .notification-row .notification-background .notification > *:last-child > * {
          min-height: 3.4em;
        }

        .floating-notifications.background .notification-row .notification-background .notification > *:last-child > * .notification-action {
          border-radius: 8px;
          background-color: @base03;
          margin: 6px;
          border: 1px solid transparent;
          border-radius: 12px;
        }

        .floating-notifications.background .notification-row .notification-background .notification > *:last-child > * .notification-action:hover {
          background-color: @base02;
          border: 1px solid @base01;
        }

        .floating-notifications.background .notification-row .notification-background .close-button {
          margin: 6px;
          padding: 2px;
          border-radius: 6px;
          background-color: transparent;
          border: 1px solid transparent;
        }

        .floating-notifications.background .notification-row .notification-background .close-button:hover {
          background-color: @base02;
        }

        .floating-notifications.background .notification-row .notification-background .image {
          margin-right: 15px;
        }

        .floating-notifications.background .notification-row .notification-background .app-icon {
          margin-right: 15px;
        }

        .floating-notifications.background .notification-row .notification-background .text-box {
          margin-right: 20px;
        }

        .floating-notifications.background .notification-row .notification-background .summary {
          font-weight: 800;
          font-size: 1rem;
        }

        .floating-notifications.background .notification-row .notification-background .body {
          font-size: 0.9rem;
        }
      '';
    };
  };
}
