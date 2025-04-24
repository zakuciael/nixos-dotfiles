---@type LazySpec
return {
  "jay-babu/mason-null-ls.nvim",
  opts = function(_, opts)
    opts.ensure_installed = require("astrocore").list_insert_unique(opts.ensure_installed, { "actionlint" })
  end
}
