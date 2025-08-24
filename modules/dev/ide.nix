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
    optional
    optionals
    ;
  inherit (lib.asserts) assertMsg;
  cfg = config.modules.dev.ides;
  xdg = config.home-manager.users.${username}.xdg;

  mkIdeConfig =
    ide:
    {
      wayland ? true,
      vmopts ? null,
      extra_properties ? null,
    }:
    assert assertMsg (builtins.isBool wayland) "wayland is not of type 'boo'";
    assert assertMsg (
      vmopts == null || (builtins.isList vmopts) && (vmopts |> builtins.all (val: builtins.isString val))
    ) "vmopts is not of type 'list of strings'";
    assert assertMsg (
      extra_properties == null || builtins.isAttrs extra_properties
    ) "extra_properties is not of type 'attrs'";
    let
      fixed_vmopts =
        (optional wayland "-Dawt.toolkit.name=WLToolkit") ++ (optionals (vmopts != null) vmopts);
    in
    ide.override rec {
      inherit extra_properties;
      vmopts = if fixed_vmopts != [ ] then fixed_vmopts else null;
      config_path = "${xdg.configHome}/JetBrains/${ide.pname}";
      caches_path = "${xdg.cacheHome}/JetBrains/${ide.pname}";
      plugins_path = "${xdg.dataHome}/JetBrains/${ide.pname}";
      logs_path = "${caches_path}/logs";
    };

  ides =
    with pkgs.jetbrains;
    [
      (mkIdeConfig clion { })
      (mkIdeConfig datagrip { })
      (mkIdeConfig dataspell { })
      (mkIdeConfig gateway { })
      (mkIdeConfig goland { })
      (mkIdeConfig idea-ultimate { })
      (mkIdeConfig mps { })
      (mkIdeConfig phpstorm { })
      (mkIdeConfig pycharm-professional { })
      (mkIdeConfig rider { })
      (mkIdeConfig ruby-mine { })
      (mkIdeConfig rust-rover { })
      (mkIdeConfig webstorm { })
    ]
    |> builtins.map (ide: {
      name = ide.baseName or ide.pname;
      value = ide;
    })
    |> builtins.listToAttrs;
  installed_ides = cfg |> builtins.map (name: ides."${name}");
in
{
  options.modules.dev.ides = mkOption {
    description = "A list of JetBrains IDEs names to install";
    example = [
      "rust-rover"
      "webstorm"
    ];
    default = [ ];
    type = ides |> builtins.attrNames |> types.enum |> types.listOf;
  };

  config = mkIf (cfg != [ ]) {
    home-manager.users.${username} = {
      home = {
        packages = installed_ides;

        # Make symlinks for rofi-jetbrains plugin
        file =
          installed_ides
          |> builtins.map (ide: {
            name = ".local/share/JetBrains/apps/${ide.pname}";
            value.source = "${ide}/${ide.meta.mainProgram}";
          })
          |> builtins.listToAttrs;
      };
    };
  };
}
