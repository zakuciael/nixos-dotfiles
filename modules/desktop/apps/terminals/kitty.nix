{
  config,
  username,
  desktop,
  ...
}:
let
  hmConfig = config.home-manager.users.${username};
in
{
  modules.desktop.wm.${desktop}.terminalPackage = hmConfig.programs.kitty.package;

  home-manager.users.${username} = {
    programs = {
      fish.shellAliases = {
        ssh = "${hmConfig.programs.kitty.package}/bin/kitten ssh";
      };
      kitty = {
        enable = true;
        catppuccin.enable = true;
        font = {
          name = "JetBrains Mono";
          size = 11;
        };
        settings = {
          update_check_interval = 0;
          scrollback_lines = 100000;
          confirm_os_window_close = 0;
        };
      };
    };
  };
}
