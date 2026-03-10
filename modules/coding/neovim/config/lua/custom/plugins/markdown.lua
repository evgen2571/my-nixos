local completion = require("vim.lsp.completion")

return {
	"MeanderingProgrammer/render-markdown.nvim",
	dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-mini/mini.nvim", "opdavies/toggle-checkbox.nvim" },
	opts = {},
	config = function()
		require("render-markdown").setup({
			completion = { lsp = { enabled = true } },

			heading = {
				sign = true,
				width = "block",
				left_pad = 2,
				right_pad = 4,
			},
			checkbox = {
				unchecked = { icon = "✘ " },
				checked = { icon = "✔ " },
			},
		})
		vim.keymap.set("n", "<A-c>", ":lua require('toggle-checkbox').toggle()<CR>")
	end,
}
