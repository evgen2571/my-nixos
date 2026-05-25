return {
	"nvim-treesitter/nvim-treesitter",
	dependencies = {
		"nvim-treesitter/nvim-treesitter-textobjects",
	},
	opts = function(_, opts)
		opts.textobjects = opts.textobjects or {}
		opts.textobjects.select = vim.tbl_deep_extend("force", opts.textobjects.select or {}, {
			enable = true,
			lookahead = true,
			keymaps = {
				["af"] = "@function.outer",
				["if"] = "@function.inner",
				["ac"] = "@class.outer",
				["ic"] = "@class.inner",
			},
		})
	end,
}
