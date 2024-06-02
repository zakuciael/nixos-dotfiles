{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.hm.dag; let
  inherit (lib.my.utils) mkLiteral writeRofiScript sortAttrs;

  mapAttrsToString = f: attrs: mapListToString (builtins.map f (sortAttrs attrs));
  mapListToString = values: concatStringsSep "," values;
  modes = {
    drun = "󰣆";
    jetbrains = entryAfter ["drun"] "󱃖";
    ssh = entryAfter ["jetbrains"] "";
    filebrowser = entryAfter ["ssh"] "";
    window = entryAfter ["filebrowser"] "";
  };
  modi = mapAttrsToString (getAttr "name") modes;
  displays = listToAttrs (builtins.map ({
    name,
    data,
  }: {
    value = data;
    name = "display-${name}";
  }) (sortAttrs modes));
in {
  package = writeRofiScript {
    inherit config;
    name = "rofi-launcher";
    text = ''rofi -theme "$ROFI_CONFIG_FILE" -show "$1"'';
    imports = [(import ./assets/theme.nix {inherit lib pkgs;})];
    configuration =
      {
        inherit modi;

        # Drun settings
        drun-show-actions = false;
        drun-use-desktop-cache = false;
        drun-reload-desktop-cache = false;
        drun-url-launcher = "xdg-open";
        drun-categories = "";
        drun-display-format = "{name}";
        drun-match-fields = mapListToString [
          "name"
          "generic"
          "exec"
          "categories"
          "keywords"
        ];
        drun = {
          parse-user = true;
          parse-system = true;
          fallback-icon = "application-x-addon";
        };

        # JetBrains plugin settings
        jetbrains-custom-aliases = ["rs:RR" "web:WS" "cpp:CL"];
        jetbrains-install-dir = "~/.local/share/JetBrains/apps/";

        # SSH settings
        ssh-client = "ssh";
        ssh-command = "{terminal} -e {ssh-client} {host} [-p {port}]";
        parse-hosts = true;
        parse-known-hosts = true;

        # File browser settings
        filebrowser = {
          directories-first = true;
          sorting-method = "name";
        };

        # Window switcher settings
        window-thumbnail = false;
        window-format = "{w} · {c} · {t}";
        window-command = "wmctrl -i -R {window}";
        window-match-fields = mapListToString [
          "title"
          "class"
          "role"
          "name"
          "desktop"
        ];
      }
      // displays;
    theme = {
      "*" = {
        border-colour = mkLiteral "var(selected)";
        handle-colour = mkLiteral "var(selected)";
        background-colour = mkLiteral "var(background)";
        foreground-colour = mkLiteral "var(foreground)";
        alternate-background = mkLiteral "var(background-alt)";
        normal-background = mkLiteral "var(background)";
        normal-foreground = mkLiteral "var(foreground)";
        urgent-background = mkLiteral "var(urgent)";
        urgent-foreground = mkLiteral "var(background)";
        active-background = mkLiteral "var(active)";
        active-foreground = mkLiteral "var(background)";
        selected-normal-background = mkLiteral "var(selected)";
        selected-normal-foreground = mkLiteral "var(background)";
        selected-urgent-background = mkLiteral "var(active)";
        selected-urgent-foreground = mkLiteral "var(background)";
        selected-active-background = mkLiteral "var(urgent)";
        selected-active-foreground = mkLiteral "var(background)";
        alternate-normal-background = mkLiteral "var(background)";
        alternate-normal-foreground = mkLiteral "var(foreground)";
        alternate-urgent-background = mkLiteral "var(urgent)";
        alternate-urgent-foreground = mkLiteral "var(background)";
        alternate-active-background = mkLiteral "var(active)";
        alternate-active-foreground = mkLiteral "var(background)";

        enabled = true;
        margin = mkLiteral "0px";
        padding = mkLiteral "0px";
        border = mkLiteral "0px solid";
        cursor = "default";
        border-color = mkLiteral "@border-colour";
        background-color = mkLiteral "@background-colour";
        text-color = mkLiteral "@foreground-colour";
      };

      window = {
        location = mkLiteral "center";
        anchor = mkLiteral "center";
        fullscreen = false;
        width = mkLiteral "600px";
        x-offset = mkLiteral "0px";
        y-offset = mkLiteral "0px";
      };

      mainbox = {
        spacing = mkLiteral "10px";
        children = ["inputbar" "message" "listview"];
        padding = mkLiteral "30px";
      };

      # Search Bar
      inputbar = {
        spacing = mkLiteral "10px";
        children = ["textbox-prompt-colon" "entry" "mode-switcher"];
      };

      # Search Bar Icon
      textbox-prompt-colon = {
        expand = false;
        str = "";
        vertical-align = mkLiteral "0.5";
        horizontal-align = mkLiteral "0.5";
      };

      # Search Bar Prompt
      entry = {
        cursor = mkLiteral "text";
        placeholder = "Search...";
        vertical-align = mkLiteral "0.5";
        horizontal-align = mkLiteral "0.0";
      };

      # Results View
      listview = {
        columns = 1;
        lines = 8; # Number of results per-page
        spacing = mkLiteral "5px";
        scrollbar = true;
      };

      scrollbar = {
        handle-width = mkLiteral "5px";
        border-radius = mkLiteral "10px";
        handle-color = mkLiteral "@handle-colour";
        background-color = mkLiteral "@alternate-background";
      };

      # Results item
      element = {
        spacing = mkLiteral "10px";
        padding = mkLiteral "5px 10px";
        border-radius = mkLiteral "10px";
        cursor = mkLiteral "pointer";
      };

      element-icon = {
        size = mkLiteral "28px";
        background-color = mkLiteral "transparent";
        cursor = mkLiteral "inherit";
      };

      element-text = {
        vertical-align = mkLiteral "0.5";
        horizontal-align = mkLiteral "0.0";

        background-color = mkLiteral "transparent";
        text-color = mkLiteral "inherit";
        highlight = mkLiteral "inherit";
        cursor = mkLiteral "inherit";
      };

      "element normal.normal" = {
        background-color = mkLiteral "var(normal-background)";
        text-color = mkLiteral "var(normal-foreground)";
      };

      "element normal.urgent" = {
        background-color = mkLiteral "var(urgent-background)";
        text-color = mkLiteral "var(urgent-foreground)";
      };

      "element normal.active" = {
        background-color = mkLiteral "var(active-background)";
        text-color = mkLiteral "var(active-foreground)";
      };

      "element selected.normal" = {
        background-color = mkLiteral "var(selected-normal-background)";
        text-color = mkLiteral "var(selected-normal-foreground)";
      };

      "element selected.urgent" = {
        background-color = mkLiteral "var(selected-urgent-background)";
        text-color = mkLiteral "var(selected-urgent-foreground)";
      };

      "element selected.active" = {
        background-color = mkLiteral "var(selected-active-background)";
        text-color = mkLiteral "var(selected-active-foreground)";
      };

      "element alternate.normal" = {
        background-color = mkLiteral "var(alternate-normal-background)";
        text-color = mkLiteral "var(alternate-normal-foreground)";
      };

      "element alternate.urgent" = {
        background-color = mkLiteral "var(alternate-urgent-background)";
        text-color = mkLiteral "var(alternate-urgent-foreground)";
      };

      "element alternate.active" = {
        background-color = mkLiteral "var(alternate-active-background)";
        text-color = mkLiteral "var(alternate-active-foreground)";
      };

      # Mode Switcher
      mode-switcher = {
        spacing = mkLiteral "7px";
      };

      button = {
        padding = mkLiteral "5px 10px 5px 10px";
        border-radius = mkLiteral "10px";

        background-color = mkLiteral "@alternate-background";
        text-color = mkLiteral "inherit";
        cursor = mkLiteral "pointer";
      };

      "button selected" = {
        background-color = mkLiteral "var(selected-normal-background)";
        text-color = mkLiteral "var(selected-normal-foreground)";
      };

      # Directory name
      textbox = {
        padding = mkLiteral "8px 10px";
        border-radius = mkLiteral "10px";
        vertical-align = mkLiteral "0.5";
        horizontal-align = mkLiteral "0.0";

        highlight = mkLiteral "none";
        blink = true;
        markup = true;
        background-color = mkLiteral "@alternate-background";
      };

      error-message = {
        padding = mkLiteral "10px";
        border = mkLiteral "2px solid";
        border-radius = mkLiteral "10px";
      };
    };
  };
  export = true;
}
