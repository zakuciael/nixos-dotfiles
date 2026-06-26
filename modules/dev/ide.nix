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
  inherit (lib.my.mapper) toJavaProperties;

  cfg = config.modules.dev.ides;
  xdg = config.home-manager.users.${username}.xdg;

  mkPropertiesFile =
    ide:
    let
      caches_path = "${xdg.cacheHome}/JetBrains/${ide.pname}";
    in
    toJavaProperties ide.pname {
      "idea.config.path" = "${xdg.configHome}/JetBrains/${ide.pname}";
      "idea.system.path" = caches_path;
      "idea.plugins.path" = "${xdg.dataHome}/JetBrains/${ide.pname}";
      "idea.log.path" = "${caches_path}/logs";
    };

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
      value = (ide.override { forceWayland = true; }).overrideAttrs (
        finalAttrs:
        let
          propertiesFile = mkPropertiesFile ide;
        in
        {
          postInstall = (finalAttrs.postInstall or "") + ''
            # Add custom properties file to the install directory
            printf "$(cat ${propertiesFile})\n\n# Default config\n\n$(cat $(makeWritable "$out/${finalAttrs.pname}/bin/idea.properties"))" > "$out/${finalAttrs.pname}/bin/idea.properties"
          '';
        }
      );
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
      type = ides |> builtins.attrNames |> types.enum |> types.listOf;
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
