{
  config,
  pkgs,
  username,
  ...
}: {
  package = pkgs.writeShellApplication {
    name = "rofi-launcher";
    runtimeInputs = [config.home-manager.users.${username}.programs.rofi.finalPackage];
    text = ''
      rofi -theme "$HOME/.config/rofi/launchers/style.rasi" -show "$1"
    '';
  };
}
