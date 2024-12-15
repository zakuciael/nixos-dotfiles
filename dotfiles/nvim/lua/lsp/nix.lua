---@type LazySpec
return {
    {
        "nvim-treesitter/nvim-treesitter",
        opts = {
            ensure_installed = { "nix" },
        },
    },
    {
        "nvimtools/none-ls.nvim",
        opts = function(_, opts)
            local builtins = require("null-ls").builtins

            opts.sources = require("astrocore").list_insert_unique(opts.sources, {
                builtins.code_actions.statix,
                builtins.diagnostics.deadnix,
                builtins.formatting.nixfmt,
            })
        end,
    },
    {
        "AstroNvim/astrolsp",
        ---@type AstroLSPOpts
        opts = {
            servers = { "nixd" },
            config = {
                nixd = {
                    nixpkgs = {
                        expr = "import (builtins.getFlake (builtins.toString ./.)).inputs.nixpkgs { }"
                    },
                    formatting = {
                        command = { "nixfmt" },
                    },
                },
            },
        },
    },
}
