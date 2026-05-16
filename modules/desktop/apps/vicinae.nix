{
  config,
  pkgs,
  lib,
  inputs,
  username,
  ...
}:
let
  inherit (lib) getExe;

  chromeExtensionId = "kcmipingpfbohfjckomimmahknoddnke";

  mkExtension =
    name: cfg:
    inputs.vicinae.packages.mkVicinaeExtension (
      {
        pname = "vicinae-extension-${name}";
        version = "0";

        src = inputs.vicinae-extensions + "/extensions/${name}";
        postPatch = ''
          substituteInPlace tsconfig.json --replace "../../" "${inputs.vicinae-extensions}/"
        '';
      }
      // cfg
    );

  cfg = config.home-manager.users.${username}.services.vicinae;
in
{
  home-manager.users.${username} = {
    home.packages = with pkgs; [
      playerctl # Needed for `player-pilot` extension
      sqlite # Needed for `zed-recents` extension
    ];

    wayland.windowManager.hyprland.settings = {
      # Focus an application window after vicinae triggers an action related to it
      misc.focus_on_activate = true;

      bind = [
        "SHIFT CTRL, space, exec, ${getExe cfg.package} toggle"
      ];

      layerrule = [
        {
          name = "vicinae-blur";
          blur = "on";
          ignore_alpha = 0;
          "match:namespace" = "vicinae";
        }
        {
          name = "vicinae-no-animation";
          no_anim = "on";
          "match:namespace" = "vicinae";
        }
      ];
    };

    xdg.configFile."google-chrome/NativeMessagingHosts/com.vicinae.vicinae.json".text = lib.toJSON {
      name = "com.vicinae.vicinae";
      description = "IPC Native Messaging Host";
      path = "${inputs.vicinae.packages.default}/libexec/vicinae/vicinae-browser-link";
      type = "stdio";
      allowed_origins = [
        "chrome-extension://${chromeExtensionId}/"
      ];
    };

    # TODO: Use settingOverrides to import those settings
    sops.templates."vicinae/settings.json".content = builtins.toJSON {
      providers = { };
    };

    services.vicinae = {
      enable = true;

      systemd = {
        enable = true;
        autoStart = true;
        environment = {
          USE_LAYER_SHELL = 1;
        };
      };

      settings = {
        close_on_focus_loss = true;
        pop_to_root_on_close = true;
        favicon_service = "twenty";

        font = {
          normal = {
            size = 11;
            family = "JetBrains Mono";
          };
        };

        theme.dark = {
          name = "vicinae-dark";
          icon_theme = "WhiteSur-dark";
        };

        launcher_window = {
          opacity = 0.98;
        };

        # Extensions settings
        providers = { };
      };

      extensions = with inputs.vicinae-extensions.packages; [
        bluetooth
        hypr-keybinds
        wifi-commander
        nix
        pulseaudio
        ssh
        github
        jetbrains-recent-projects
        zed-recents
        nerdfont-search
        protondb-search
        player-pilot
      ];
    };
  };
}
