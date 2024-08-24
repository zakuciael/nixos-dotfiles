{
  config,
  lib,
  pkgs,
  unstable,
  inputs,
  username,
  ...
}:
with lib;
with builtins; let
  cfg = config.modules.desktop.apps;
  mkAutostartModules = programs:
    builtins.listToAttrs (builtins.map (desktop: {
      name = desktop;
      value = {autostartPrograms = programs;};
    }) (builtins.attrNames config.modules.desktop.wm));
in {
  options.modules.desktop.apps = {
    enable = mkEnableOption "general desktop applications";
  };

  config = mkIf (cfg.enable) {
    programs.noisetorch.enable = true;

    home-manager.users.${username} = {
      programs.fish.shellAliases.open = "xdg-open";
      home.packages = with pkgs; [
        inputs.nil.default
        inputs.alejandra.default
        discord
        unstable.google-chrome
        warp-terminal
        wakatime
        spotify
        unstable.graphite-cli
        cinnamon.nemo
        libsForQt5.ark
        gnome-text-editor
        gnome.eog
        font-manager
      ];
    };
  };
}
