{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) concatStringsSep listToAttrs;
  inherit (lib.my.utils) writeRofiScript sortAttrs;
  inherit (lib.hm.dag) entryAfter;
  mapListToString = values: concatStringsSep "," values;

  modes = {
    drun = "󰣆";
    ssh = entryAfter [ "drun" ] "";
    filebrowser = entryAfter [ "ssh" ] "";
    window = entryAfter [ "filebrowser" ] "";
  };
in
{
  export = true;
  package = writeRofiScript {
    inherit config;
    name = "rofi-launcher";
    text = ''
      args=()
      if [ -n "''${1+x}" ]; then
        args+=( '-show' "$1" )
      fi

      rofi -theme "$ROFI_CONFIG_FILE" "''${args[@]}"
    '';

    imports = [
      (import ../common/theme.nix { inherit lib pkgs; })
      (import ./theme.nix { inherit lib pkgs; })
      (import ./config.nix { inherit lib pkgs; })
    ];

    configuration = {
      modi = modes |> sortAttrs |> builtins.map ({ name, ... }: name) |> mapListToString;
    }
    // (
      modes
      |> sortAttrs
      |> builtins.map (
        { name, data }:
        {
          value = data;
          name = "display-${name}";
        }
      )
      |> listToAttrs
    );
  };
}
