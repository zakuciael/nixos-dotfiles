{ pkgs, username, ... }:
{
  home-manager.users.${username} = {
    home.packages = with pkgs; [ nmgui ];

    wayland.windowManager.hyprland.settings = {
      windowrule = [
        {
          name = "Network Manager GUI";
          "match:title" = "^(.*Network Manager.*)$";
          float = true;
        }
      ];
    };

  };
}
