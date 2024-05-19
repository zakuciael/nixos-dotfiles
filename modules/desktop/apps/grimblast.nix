{
  pkgs,
  username,
  ...
}: {
  # Add keybinds to Hyprland
  home-manager.users.${username} = {
    home.packages = with pkgs; [grimblast];

    wayland.windowManager.hyprland.settings.bind = let
      grimblastExec = "${pkgs.grimblast}/bin/grimblast --notify";
    in [
      # Screenshot entire monitor
      ", Print, exec, ${grimblastExec} copy output" # Copy to clipboard
      "$mod, Print, exec, ${grimblastExec} save output" # Save to file
      # Screenshot active window
      "ALT, Print, exec, ${grimblastExec} copy active" # Copy to clipboard
      "$mod ALT, Print, exec, ${grimblastExec} save active" # Save to file
      # Screenshot selected region
      "CTRL, Print, exec, ${grimblastExec} --freeze copy area" # Copy to clipboard
      "$mod CTRL, Print, exec, ${grimblastExec} --freeze save area" # Save to file
    ];
  };
}
