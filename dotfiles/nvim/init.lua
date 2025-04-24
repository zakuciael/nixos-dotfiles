local lazy_path = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not (vim.uv or vim.loop).fs_stat(lazy_path) then
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable",
    lazy_path })
end

vim.opt.rtp:prepend(lazy_path)

if not pcall(require, "lazy") then
  vim.api.nvim_echo(
    { { ("Unable to load lazy from: %s\n"):format(lazy_path), "ErrorMsg" }, { "Press any key to exit...", "MoreMsg" } },
    true, {})
  vim.fn.getchar()
  vim.cmd.quit()
end

require("lazy").setup({
  {
    "AstroNvim/AstroNvim",
    version = "^4",
    import = "astronvim.plugins",
    opts = {
      icons_enabled = true,
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    commit = vim.fn.readfile(vim.fn.stdpath("config") .. "/treesitter-rev", "", 1)[1],
  },
  { import = "community" },
  { import = "plugins" },
  { import = "lsp" },
})
