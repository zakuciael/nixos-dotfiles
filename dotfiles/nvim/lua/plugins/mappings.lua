---@type LazySpec
return {
    "AstroNvim/astrocore",
    ---@type AstroCoreOpts
    opts = {
        mappings = {
            n = {
                -- Neotree: remember last source and make git the default
                ["<Leader>e"] = { "<Cmd>Neotree toggle source=last<CR>", desc = "Toggle Explorer" },
                ["<Leader>o"] = {
                    function()
                        if vim.bo.filetype == "neo-tree" then
                            vim.cmd.wincmd("p")
                        else
                            vim.cmd.Neotree({ "focus", "source=last" })
                        end
                    end,
                    desc = "Toggle Explorer Focus",
                },
                -- Switch between tabs
                ["<S-Tab>"] = { ":bprev<CR>" },
                ["<Tab>"] = { ":bnext<CR>" },

                -- Disable hover.nvim when moving mouse
                ["<MouseMove>"] = false,
            },
            t = {
                -- Easier escape from the toggleterm.nvim plugin
                ["<ESC><ESC>"] = { "<C-\\><C-n>" },
                ["<S-ESC>"] = { "<C-\\><C-n>" },
            },
            c = {
                -- Write file as sudo
                ["w!!"] = { "w !sudo tee > /dev/null %", desc = "Write as sudo" },
            },
        }
    },
}
