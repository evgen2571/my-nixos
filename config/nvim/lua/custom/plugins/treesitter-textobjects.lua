return {
	"nvim-treesitter/nvim-treesitter-textobjects",
	branch = "main",
	event = { "BufReadPost", "BufNewFile" },
	config = function()
		require("nvim-treesitter-textobjects").setup({ select = { lookahead = true } })
		for key, query in pairs({
			af = "@function.outer",
			["if"] = "@function.inner",
			ac = "@class.outer",
			ic = "@class.inner",
		}) do
			vim.keymap.set({ "x", "o" }, key, function()
				require("nvim-treesitter-textobjects.select").select_textobject(query, "textobjects")
			end, { desc = "Select " .. query })
		end
	end,
}
