{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  inherit (lib) mkIf removePrefix listToAttrs;
  cfg = config.modules.dev.zed;
in
{
  config = mkIf cfg.enable {
    home-manager.users.${username}.programs = rec {
      zed-editor.userSettings = {
        auto_update_extensions =
          zed-editor-extensions.packages
          |> map (drv: {
            name = removePrefix "zed-extension-" drv.pname;
            value = false;
          })
          |> listToAttrs;
      };
      zed-editor-extensions = {
        enable = true;

        packages = with pkgs.zed-extensions; [
          pkgs.zed-sops

          nix
          wakatime
          discord-presence
          catppuccin
          catppuccin-blur-plus
          colored-zed-icons-theme
          material-icon-theme
          codebook
          comment
          git-firefly
        ];
      };
    };
  };
}
