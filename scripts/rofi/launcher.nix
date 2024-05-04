{pkgs, ...}: {
  package = pkgs.writeShellApplication {
    name = "rofi-launcher";
    runtimeInputs = with pkgs; [rofi-wayland];
    text = ''
      rofi -theme "$HOME/.config/rofi/launchers/style.rasi" -show "$1"
    '';
  };
}
