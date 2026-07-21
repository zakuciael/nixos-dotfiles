{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  inherit (lib)
    mkOption
    mkIf
    types
    ;

  cfg = config.modules.dev.ides;

  ides =
    with pkgs.jetbrains;
    [
      clion
      datagrip
      dataspell
      gateway
      goland
      idea
      mps
      phpstorm
      pycharm
      rider
      ruby-mine
      rust-rover
      webstorm
    ]
    |> map (ide: {
      name = ide.pname;
      value = ide.override { forceWayland = true; };
    })
    |> lib.listToAttrs;

  installed_ides = cfg |> map (name: ides."${name}");
in
{
  options.modules = {
    test = mkOption {
      type = types.listOf types.package;
      default = installed_ides;
    };
    dev.ides = mkOption {
      description = "A list of JetBrains IDEs names to install";
      example = [
        "rust-rover"
        "webstorm"
      ];
      default = [ ];
      type =
        ides
        |> builtins.attrNames
        |> types.enum
        |> types.listOf;
    };
  };

  config = mkIf (cfg != [ ]) {
    home-manager.users.${username} = {
      home.packages = installed_ides;

      # Make symlinks for rofi-jetbrains plugin
      xdg.dataFile =
        installed_ides
        |> map (ide: {
          name = "JetBrains/apps/${ide.pname}";
          value.source = "${ide}/${ide.pname}";
        })
        |> lib.listToAttrs;
    };
  };
}
