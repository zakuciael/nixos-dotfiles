{ lib, pkgs, ... }:
let
  inherit (lib) concatStringsSep;
  inherit (lib.my.mapper) toRasi;

  mapListToString = values: concatStringsSep "," values;
in
pkgs.writeTextFile {
  name = "launcher-config.rasi";
  text = toRasi { } {
    configuration = {
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
    };
  };
}
