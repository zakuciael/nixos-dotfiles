{ pkgs, username, ... }:
{
  home-manager.users.${username} = {
    home.packages = with pkgs; [ nmgui ];

    wayland.windowManager.hyprland.settings.window_rule = [
      {
        name = "Network Manager GUI";
        match.title = "^(.*Network Manager.*)$";
        float = true;
      }
    ];
  };
}
