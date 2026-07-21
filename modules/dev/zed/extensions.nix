{
  config,
  lib,
  pkgs,
  inputs,
  username,
  ...
}:
let
  inherit (lib) mkIf removePrefix listToAttrs;
  cfg = config.modules.dev.zed;
in
{
  config = mkIf cfg.enable {
    home-manager.users.${username} = {
      # Add custom Nix LSP servers to PATH
      home.packages = with inputs.zed-nix-extension.packages; [
        statix-ls
        deadnix-ls
      ];

      programs = rec {
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
            # Themes
            catppuccin
            catppuccin-blur-plus
            colored-zed-icons-theme

            # Tracking
            wakatime
            discord-presence

            # Git
            git-firefly

            # GitHub
            github-actions

            # Web
            html
            scss
            emmet
            tsgo

            # Nix
            inputs.zed-nix-extension.packages.zed-nix-extension

            # Rust
            toml
            tombi
            cargo-tom
            rust-workflow-snippets

            # Command runners
            make
            just

            # Qt
            qml

            # Protobuf
            proto

            # Lua
            lua

            # Docker
            dockerfile
            docker-compose

            # Infrastructure as Code
            terraform
            ansible

            # Secrets / Envs
            pkgs.zed-sops
            env

            # Spell checking
            harper

            # Config files
            ini
            caddyfile
            ssh-config

            # Shells
            fish

            # Other
            log
            comment
          ];
        };
      };
    };
  };
}
