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

  # Top-level by-name package attrs (not jetbrains.* aliases).
  ideNames = [
    "clion"
    "datagrip"
    "dataspell"
    "goland"
    "intellij-idea"
    "jetbrains-gateway"
    "jetbrains-mps"
    "phpstorm"
    "pycharm"
    "rider"
    "ruby-mine"
    "rust-rover"
    "webstorm"
  ];

  ides = lib.genAttrs ideNames (name: pkgs.${name});

  installedIdes = map (name: ides.${name}) cfg;

  # Install layout is $out/$pname/… — pname can differ from the by-name attr
  # (jetbrains-gateway → gateway, jetbrains-mps → mps).
  ideHome = package: "${package}/${package.pname}";

  linuxLaunch =
    productInfo:
    lib.findFirst (
      launch: launch.os or null == "Linux"
    ) (builtins.head productInfo.launch) productInfo.launch;
in
{
  options.modules = {
    dev.ides = mkOption {
      description = "JetBrains IDEs to install (nixpkgs by-name package attrs)";
      example = [
        "rust-rover"
        "intellij-idea"
        "webstorm"
      ];
      default = [ ];
      type = types.listOf (types.enum ideNames);
    };
  };

  config = mkIf (cfg != [ ]) {
    home-manager.users.${username} = {
      home.packages = installedIdes;

      xdg.dataFile =
        installedIdes
        |> map (
          package:
          let
            home = ideHome package;
            productInfo = lib.importJSON "${home}/product-info.json";
            inherit (productInfo) svgIconPath;
            launch = linuxLaunch productInfo;
            inherit (launch) launcherPath startupWmClass;
            scriptName = lib.removePrefix "bin/" launcherPath;
            # App dir must match $out/$pname so Toolbox/rofi resolve product-info.
            appName = package.pname;
          in
          {
            "JetBrains/Toolbox/scripts/${scriptName}".source = lib.getExe package;
            "JetBrains/Toolbox/apps/${appName}".source = home;
            "JetBrains/Toolbox/dotDesktopIcons/${startupWmClass}-dummy.desktop.icon.svg".source =
              "${home}/${svgIconPath}";

            # rofi-jetbrains scans ~/.local/share/JetBrains/apps/
            "JetBrains/apps/${appName}".source = home;
          }
        )
        |> lib.foldl' (acc: curr: lib.recursiveUpdate acc curr) { };
    };
  };
}
