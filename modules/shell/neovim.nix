{
  config,
  lib,
  pkgs,
  username,
  dotfiles,
  ...
}:
with lib;
with lib.my;
let
  cfg = config.modules.shell.neovim;
  xdg = config.home-manager.users.${username}.xdg;
  neovimPkg = config.home-manager.users.${username}.programs.neovim.finalPackage;

  normalizedGrammars = (
    lib.mapAttrs'
      (name: value: {
        name = lib.removePrefix "tree-sitter-" name;
        inherit value;
      })
      (
        lib.filterAttrs (
          name: _: lib.hasPrefix "tree-sitter-" name
        ) pkgs.vimPlugins.nvim-treesitter.builtGrammars
      )
  );
in
{
  options.modules.shell.neovim = {
    enable = mkEnableOption "neovim configuration";
    lspPackages = mkOption {
      description = "LSP packages available to nvim.";
      type = types.listOf types.package;
      default = [
        pkgs.lua-language-server
        pkgs.stylua
      ];
      example = literalExpression "[ pkgs.nixd ]";
    };
    treesitterGrammars = mkOption {
      description = "Treesitter grammars available to nvim.";
      type =
        with types;
        coercedTo (listOf (enum (builtins.attrNames normalizedGrammars))) (
          grammars:
          let
            symlinks = lib.mapAttrsToList (name: grammar: ''ln -s ${grammar}/parser $out/${name}.so'') (
              filterAttrs (name: _: builtins.elem name grammars) normalizedGrammars
            );
          in
          (pkgs.runCommand "treesitter-grammars" { } ''
            mkdir -p $out
            ${concatStringsSep "\n" symlinks}
          '').overrideAttrs
            {
              passthru.rev = pkgs.vimPlugins.nvim-treesitter.src.rev;
            }
        ) package;
      default = [ ];
      example = literalExpression "[ \"lua\" ]";
    };
  };

  config = mkIf (cfg.enable) {
    home-manager.users.${username} = {
      xdg = {
        dataFile = {
          "nvim/site/parser".source = cfg.treesitterGrammars;
          "nvim/lib/libfzf.so".source = "${pkgs.vimPlugins.telescope-fzf-native-nvim}/build/libfzf.so";
        };
        configFile."nvim/lua".source = dotfiles.nvim.lua.source;
      };

      home.activation.nvim = hm.dag.entryAfter ["writeBoundary"] (
        let
          treesitterRev = cfg.treesitterGrammars.rev;
          nvimConfig = "${xdg.configHome}/nvim";
        in
        ''
          run echo "${treesitterRev}" > "${nvimConfig}/treesitter-rev"

          if [[ -f "${nvimConfig}/lazy-lock.json" ]]; then
          if ! grep -q "${treesitterRev}" "${nvimConfig}/lazy-lock.json"; then
              echo "lazy-lock.json file has outdated version of nvim-treesitter... updating it."
              run ${getExe neovimPkg} --headless "+Lazy! update" +qa
            fi
          else
            echo "lazy-lock.json file doesn't exist... creating it."
            run ${getExe neovimPkg} --headless "+Lazy! update" +qa
          fi
        '');

      programs.neovim = {
        enable = true;
        defaultEditor = true;

        withNodeJs = true;
        withPython3 = true;

        vimAlias = true;
        viAlias = true;

        extraPackages = cfg.lspPackages ++ (with pkgs; [git gcc]);
        extraLuaConfig = lib.fileContents dotfiles.nvim."init.lua".source;
      };
    };
  };
}
