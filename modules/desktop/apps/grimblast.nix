{
  lib,
  pkgs,
  username,
  ...
}:
{
  home-manager.users.${username} = {
    home.packages = with pkgs; [ grimblast ];

    # Add keybinds to Hyprland
    wayland.windowManager.hyprland.settings.bind =
      let
        inherit (lib.my.utils.hypr) mkBind withMod dsp;

        grimblastExec = "${pkgs.grimblast}/bin/grimblast --notify";
      in
      [
        # Screenshot entire monitor
        (mkBind "Print" (dsp.exec "${grimblastExec} copy output")) # Copy to clipboard
        (mkBind (withMod "Print") (dsp.exec "${grimblastExec} save output")) # Save to file

        # Screenshot active window
        (mkBind "ALT + Print" (dsp.exec "${grimblastExec} copy active")) # Copy to clipboard
        (mkBind (withMod "ALT + Print") (dsp.exec "${grimblastExec} save active")) # Save to file

        # Screenshot selected region
        (mkBind "CTRL + Print" (dsp.exec "${grimblastExec} --freeze copy area")) # Copy to clipboard
        (mkBind (withMod "CTRL + Print") (dsp.exec "${grimblastExec} --freeze save area")) # Save to file
      ];
  };
}
