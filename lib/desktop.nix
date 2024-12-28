{
  lib,
  pkgs,
  inputs,
  username,
  dotfiles,
  scripts,
  ...
}:
with lib;
with lib.my;
let
  mkDesktopApp =
    config: name: desktop:
    let
      basePath = ./../modules/desktop/apps;
      path =
        if builtins.pathExists (basePath + "/${name}.nix") then
          basePath + "/${name}.nix"
        else if builtins.pathExists (basePath + "/terminals/${name}.nix") then
          basePath + "/terminals/${name}.nix"
        else
          throw "${name} app was not found!";
    in
    import path {
      inherit
        config
        lib
        pkgs
        inputs
        username
        dotfiles
        scripts
        desktop
        ;
      colorScheme =
        assert assertMsg (
          config.home-manager.users.${username}.colorScheme.author != ""
        ) "You need to select a nix-colors theme to use this ${name} config";
        config.home-manager.users.${username}.colorScheme;
    };

  mkAutostartScript =
    desktop: cmds:
    assert builtins.all (x: builtins.typeOf x == "string") cmds;
    let
      programs = builtins.concatStringsSep "\n" (builtins.map (x: ''"${x}"'') cmds);
    in
    pkgs.writeShellScript "autostart.sh" ''
      LOG_DIR=$HOME/.local/share/${desktop}

      exec_app() {
        EXEC_PATH=$(echo "$1" | awk '{ print $1 }')
        APP_NAME=$(basename "$EXEC_PATH")
        TIMESTAMP=$(date +"%D %T")

        echo "[autostart] $time: Launching $APP_NAME"
        ${pkgs.bash}/bin/bash -c "$1" &>"$LOG_DIR/$APP_NAME.log" || echo "[warning] There was a problem launching $APP_NAME" &
      }

      declare -a APPS

      APPS=(${programs})

      IFS=""

      mkdir -p "$LOG_DIR"

      for APP in ''${APPS[*]}; do
        exec_app "$APP"
      done
    '';
in
{
  mkDesktopModule =
    {
      name,
      config,
      autostartPath ? ".config/${name}/autostart.sh",
      autostart ? [ ],
      desktopApps ? [ ],
      extraConfig ? { },
      extraOptions ? { },
    }:
    let
      cfg = config.modules.desktop.wm.${name};
      self = modules.desktop.wm.${name};
      desktopName = name;

      includedApps = builtins.map (appName: mkDesktopApp config appName desktopName) desktopApps;

      extraConfigModule =
        if builtins.typeOf extraConfig == "lambda" then
          extraConfig {
            inherit self cfg;
            autostartScript = autostartPath;
            colorScheme =
              assert assertMsg (
                config.home-manager.users.${username}.colorScheme.author != ""
              ) "You need to select a nix-colors theme to use this ${desktopName} config";
              config.home-manager.users.${username}.colorScheme;
          }
        else
          extraConfig;

      moduleOptions = with lib; {
        enable = mkEnableOption "${name} desktop";
        terminalPackage = mkOption {
          description = "Current preffered terminal application";
          example = pkgs.alacritty;
          default = pkgs.kitty;
          type = types.package;
        };
        # TODO: Add priority system
        autostartPrograms = mkOption {
          description = "A list of programs to autostart when the desktop loads";
          example = [ "${pkgs.hello}/bin/hello --special-args" ];
          default = [ ];
          type = with types; listOf str;
        };
      };

      extraOptionsModule =
        assert assertMsg (builtins.all (opt: !(moduleOptions ? "${opt}")) (
          builtins.attrNames extraOptions
        )) "extraOptions cannot override default options";
        extraOptions;

      moduleChecker = {
        assertions = [
          {
            assertion = builtins.typeOf extraConfigModule == "set";
            message = "extraConfigFunc must return set of configuration";
          }
        ];
      };

      autostartScriptMountModule =
        let
          autostartMerge = cfg.autostartPrograms ++ autostart;
        in
        {
          home-manager.users.${username}.home.file.${autostartPath} = {
            enable = true;
            executable = true;
            source = mkAutostartScript desktopName autostartMerge;
          };
        };
    in
    {
      options.modules.desktop.wm.${name} = moduleOptions // extraOptionsModule;

      config = mkIf (cfg.enable) (
        mkMerge (
          [
            autostartScriptMountModule
            moduleChecker
            extraConfigModule
          ]
          ++ includedApps
        )
      );
    };
}
