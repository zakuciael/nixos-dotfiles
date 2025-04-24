local data_dir = vim.fn.stdpath("data")
local build_cmd = "ln -sf " .. data_dir .. "/site/parser/*.so " .. data_dir .. "/lazy/nvim-treesitter/parser"

---@type LazySpec
return {
	"nvim-treesitter/nvim-treesitter",
	build = build_cmd,
	opts = function(_, opts)
		vim.fn.system(build_cmd)
        opts.auto_install = false;
	end,
}