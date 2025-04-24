-- customize mason plugins
local suggested_packages = {}

--- Clear "ensure_installed" option but add pkgs to a "suggested-pkgs.json" file
--- so that missing pkgs can be installed via Nix dotfiles
local disable_auto_install = function(_, opts)
    require("astrocore").list_insert_unique(suggested_packages, opts.ensure_installed or {})

    local file = io.open(vim.fn.stdpath("data") .. "/suggested-pkgs.json", "w")
    file:write(vim.fn.json_encode(suggested_packages))
    file:close()

    opts.ensure_installed = {}
end

return {
    {
        "williamboman/mason-lspconfig.nvim",
        opts = disable_auto_install,
    },
    {
        "jay-babu/mason-null-ls.nvim",
        opts = disable_auto_install,
    },
    {
        "jay-babu/mason-nvim-dap.nvim",
        opts = disable_auto_install,
    },
}
