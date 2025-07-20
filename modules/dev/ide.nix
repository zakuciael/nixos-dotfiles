{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  inherit (lib)
    optionalString
    optionalAttrs
    concatStringsSep
    mkOption
    mkIf
    types
    ;

  cfg = config.modules.dev.ides;
  xdg = config.home-manager.users.${username}.xdg;

  defaultPlugins = [
    "extra-toolwindow-colorful-icons"
    "extra-icons"
    "direnv-integration"
    "-env-files"
    "-ignore"
    "nixidea"
    "ideolog"
    "just"
    "wakatime"
    "gittoolbox"
    "conventional-commit"
    "github-actions-manager"
    "discord-rich-presence"
    "grazie-pro"
  ];

  mkIDE =
    pkg:
    {
      plugins ? [ ],
      ignorePlugins ? [ ],
      enableNativeWayland ? true,
      extraVmopts ? null,
      extraProperties ? null,
    }:
    let
      filteredPlugins = builtins.filter (plugin: !builtins.elem plugin ignorePlugins) (
        defaultPlugins ++ plugins
      );
    in
    pkgs.jetbrains.plugins.addPlugins (pkg.override (
      rec {
        inherit extraProperties;
        config_path = "${xdg.configHome}/JetBrains/${pkg.pname}";
        caches_path = "${xdg.cacheHome}/JetBrains/${pkg.pname}";
        plugins_path = "${xdg.dataHome}/JetBrains/${pkg.pname}";
        logs_path = "${caches_path}/logs";
      }
      // optionalAttrs (enableNativeWayland || extraVmopts != null) {
        vmopts =
          (optionalString enableNativeWayland "-Dawt.toolkit.name=WLToolkit ")
          + (optionalString (extraVmopts != null) (concatStringsSep " " extraVmopts));
      }
    )) filteredPlugins;

  availableIdes = builtins.listToAttrs (
    builtins.map
      (value: {
        name = value.baseName or value.pname;
        inherit value;
      })
      (
        with pkgs.jetbrains;
        [
          (mkIDE clion {
            extraVmopts = [ "-Didea.suppressed.plugins.set.selector=radler" ];
          })
          datagrip
          dataspell
          gateway
          (mkIDE goland {
            enableNativeWayland = false;
            plugins = [
              "protocol-buffers"
              "ini"
              "toml"
            ];
          })
          (mkIDE idea-ultimate {
            plugins = [
              "makefile-language"
              "terraform-and-hcl"
              "kubernetes"
              "ini"
              "toml"
              "python"
              "python-community-edition"
              "php"
              "go-template"
              "go"
            ];
          })
          mps
          (mkIDE phpstorm { })
          (mkIDE pycharm-professional { })
          (mkIDE rider {
            ignorePlugins = [
              "ideolog"
            ];
          })
          (mkIDE ruby-mine { })
          (mkIDE rust-rover {
            plugins = [
              "protocol-buffers"
              "toml"
            ];
            ignorePlugins = [
              "ideolog"
            ];
          })
          (mkIDE webstorm { })
        ]
      )
  );
  installedIDEs = builtins.map (name: availableIdes.${name}) cfg;
in
{
  options.modules.dev.ides = mkOption {
    description = "A list of JetBrains IDEs names to install";
    example = [
      "rust-rover"
      "webstorm"
    ];
    default = [ ];
    type = with types; listOf (enum (builtins.attrNames availableIdes));
  };

  config = mkIf (cfg != [ ]) {
    home-manager.users.${username} = {
      home = {
        packages = installedIDEs;

        file = builtins.listToAttrs (
          builtins.map (ide: {
            name = ".local/share/JetBrains/apps/${ide.pname}";
            value = {
              source = "${ide}/${ide.meta.mainProgram}";
            };
          }) installedIDEs
        );
      };
    };
  };
}
