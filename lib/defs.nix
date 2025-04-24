{lib, ...}:
with lib;
with lib.types; {
  monitor = mkOption {
    description = "Monitor definition for different window servers.";
    example = {};
    type = submodule {
      options = {
        xorg = mkOption {
          description = "Name of the monitor on the Xorg window server.";
          example = "DisplayPort-0";
          type = str;
        };
        wayland = mkOption {
          description = "Name of the monitor on the Wayland window server.";
          example = "DP-1";
          type = str;
        };
      };
    };
  };
}
