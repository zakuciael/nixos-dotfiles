{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib;
with lib.hm.dag;
let
  inherit (lib.my.utils)
    mkLiteral
    mkMultiEntry
    writeRofiScript
    writeRasiFile
    sortAttrs
    indentLines
    ;
  inherit (pkgs) writeShellApplication;

  # Utils
  toIconString =
    attrs:
    concatStringsSep "\n" (
      builtins.map (
        value:
        let
          inherit (value) data;
        in
        if isAttrs data then data.icon else data
      ) (sortAttrs attrs)
    );

  mkPowermenuSwitchStatement =
    {
      indent ? "",
    }:
    attrs:
    concatStringsSep "\n" (
      builtins.map ({ data, ... }: mkPowermenuSwitchCase { inherit indent; } data) (sortAttrs attrs)
    );

  mkPowermenuConfirmAction =
    {
      indent ? "",
    }:
    data:
    (indentLines indent (
      if data.confirm then
        ''
          if rofi-powermenu-confirm; then
          ${indentLines indent data.action}
          else
            exit 0
          fi''
      else
        data.action
    ));

  mkPowermenuSwitchCase =
    {
      indent ? "",
    }:
    data:
    indentLines indent ''
      "${data.icon}")
      ${mkPowermenuConfirmAction { inherit indent; } data}
        ;;'';

  # Confirm settings
  confirmIcons = {
    yes = entryAnywhere "";
    no = entryAfter [ "yes" ] "";
  };

  # Powermenu settings
  powermenuSettings = {
    lock = entryAnywhere {
      icon = "";
      runtimeInputs = [ ];
      action = "echo lock";
      confirm = false;
    };
    suspend = entryAfter [ "lock" ] {
      icon = "";
      runtimeInputs = with pkgs; [
        mpc
        alsa-utils
      ];
      action = ''
        mpc -q pause
        amixer set Master mute
        systemctl suspend'';
      confirm = true;
    };
    logout = entryAfter [ "suspend" ] {
      icon = "";
      action = "hyprctl dispatch exit";
      runtimeInputs = [ config.home-manager.users.${username}.wayland.windowManager.hyprland.package ];
      confirm = true;
    };
    reboot = entryAfter [ "logout" ] {
      icon = "";
      runtimeInputs = [ ];
      action = "systemctl reboot";
      confirm = true;
    };
    shutdown = entryAfter [ "reboot" ] {
      icon = "";
      runtimeInputs = [ ];
      action = "systemctl poweroff";
      confirm = true;
    };
  };

  commonTheme = writeRasiFile {
    name = "styles.rasi";
    attrs = {
      configuration = entryAnywhere {
        show-icons = false;
      };

      "@import" = entryAfter [ "configuration" ] (mkMultiEntry [
        (import ./common/theme.nix { inherit lib pkgs; })
      ]);

      "*" = entryAfter [ "@import" ] {
        enabled = true;
        margin = mkLiteral "0px";
        padding = mkLiteral "0px";
        border = mkLiteral "0px solid";
        border-radius = mkLiteral "0px";

        cursor = mkLiteral "default";
        border-color = mkLiteral "@selected";
        text-color = mkLiteral "@foreground";
        background-color = mkLiteral "transparent";
      };

      # Main window
      window = entryAfter [ "*" ] {
        transparency = "real";
        location = mkLiteral "center";
        anchor = mkLiteral "center";
        fullscreen = false;
        x-offset = mkLiteral "0px";
        y-offset = mkLiteral "0px";
      };

      # Mainbox
      mainbox = entryAfter [ "window" ] {
        spacing = mkLiteral "15px";
        children = [
          "message"
          "listview"
        ];
      };

      # Message
      message = entryAfter [ "mainbox" ] {
        margin = mkLiteral "0px 100px";
        padding = mkLiteral "15px";
        border-radius = mkLiteral "15px";

        background-color = mkLiteral "@background-alt";
      };
      textbox = entryAfter [ "message" ] {
        vertical-align = mkLiteral "0.5";
        horizontal-align = mkLiteral "0.5";

        background-color = mkLiteral "inherit";
        text-color = mkLiteral "inherit";
      };

      # Listview
      listview = entryAfter [ "textbox" ] {
        lines = 1;
        scrollbar = false;
        spacing = mkLiteral "15px";
      };
      element = entryAfter [ "listview" ] {
        padding = mkLiteral "45px 10px";
        border-radius = mkLiteral "20px";

        cursor = mkLiteral "pointer";
        background-color = mkLiteral "@background-alt";
      };
      "element selected.normal" = entryAfter [ "element" ] {
        background-color = mkLiteral "var(selected)";
        text-color = mkLiteral "var(background)";
      };
      element-text = entryAfter [ "element selected.normal" ] {
        font = "icomoon-feather bold 32";
        vertical-align = mkLiteral "0.5";
        horizontal-align = mkLiteral "0.5";

        cursor = mkLiteral "inherit";
        text-color = mkLiteral "inherit";
      };
    };
  };

  powermenuConfirmScript = writeRofiScript {
    inherit config;
    name = "rofi-powermenu-confirm";
    text = ''
      run() {
        echo -e "${toIconString confirmIcons}" | rofi \
          -theme "$ROFI_CONFIG_FILE" \
          -p "Confirmation" \
          -mesg "Are you Sure?" \
          -dmenu
      }

      if [[ "$(run)" == "${confirmIcons.yes.data}" ]]; then
        exit 0
      else
        exit 1
      fi
    '';
    imports = [ commonTheme ];
    theme = {
      window = entryAnywhere {
        width = mkLiteral "350px";
      };
      listview = entryAfter [ "window" ] {
        columns = 2;
      };
    };
  };
  powermenuChoiceScript = writeRofiScript {
    inherit config;
    name = "rofi-powermenu-choice";
    runtimeInputs = with pkgs; [ toybox ];
    text = ''
      UPTIME="$(uptime -p | sed -e 's/up //g' | sed -e 's/,  load average:.*//g')"

      echo -e "${toIconString powermenuSettings}" | rofi \
        -theme "$ROFI_CONFIG_FILE" \
        -p "Uptime: $UPTIME" \
        -mesg "Uptime: $UPTIME" \
        -dmenu
    '';
    imports = [ commonTheme ];
    theme = {
      window = entryAnywhere {
        width = mkLiteral "800px";
      };
      listview = entryAfter [ "window" ] {
        columns = 5;
      };
    };
  };
in
{
  package = writeShellApplication {
    name = "rofi-powermenu";
    runtimeInputs = [
      powermenuConfirmScript
      powermenuChoiceScript
    ]
    ++ (concatLists (mapAttrsToList (_: v: v.data.runtimeInputs) powermenuSettings));
    text = ''
      case "$(rofi-powermenu-choice)" in
      ${mkPowermenuSwitchStatement { indent = "  "; } powermenuSettings}
      esac
    '';
  };
  export = true;
}
