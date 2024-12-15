local data_dir = vim.fn.stdpath("data")
local telescope_dir = data_dir .. "/lazy/telescope-fzf-native.nvim"

---@type LazySpec
-- override make command build since we provide the shared library with home-manager already
return {
    "nvim-telescope/telescope-fzf-native.nvim",
    build = "mkdir -p "
        .. telescope_dir
        .. "/build && ln -sf "
        .. data_dir
        .. "/lib/libfzf.so "
        .. telescope_dir
        .. "/build/libfzf.so",
}
