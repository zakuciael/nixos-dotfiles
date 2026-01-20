{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  inherit (lib) mkIf nameValuePair genAttrs';
  cfg = config.modules.dev.zed;
in
{
  config = mkIf cfg.enable {
    home-manager.users.${username}.programs = rec {
      zed-editor.userSettings = {
        auto_update_extensions = genAttrs' zed-editor-extensions.packages (
          { name, ... }: nameValuePair name false
        );
      };
      zed-editor-extensions = {
        enable = true;

        packages = with pkgs.zed-extensions; [
          (nix.overrideAttrs {
            src = pkgs.fetchFromGitHub {
              owner = "zakuciael";
              repo = "zed-nix-extension";
              rev = "main";
              hash = "sha256-wbZ9b6zPGyG9ZVhkcLf7PQgsg5SQ9ZUVCm+8WiDSnUw=";
            };
          })
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
