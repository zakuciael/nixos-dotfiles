{ lib, ... }:
lib.singleton (
  final: prev: {
    vimPlugins = prev.vimPlugins // {
      nvim-treesitter = prev.vimPlugins.nvim-treesitter.overrideAttrs {
        version = "master";
        src = final.fetchFromGitHub {
          owner = "nvim-treesitter";
          repo = "nvim-treesitter";
          rev = "42fc28ba918343ebfd5565147a42a26580579482";
          sha256 = "1ck1qslxwi18qxrga68blvk1dg9j4jn65xiw8snq5pk06waksnq9";
        };
      };
    };
  }
)
