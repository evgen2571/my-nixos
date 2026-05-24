return {
	"MeanderingProgrammer/render-markdown.nvim",
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"nvim-mini/mini.nvim",
		"opdavies/toggle-checkbox.nvim",
	},
	ft = { "markdown" },
	keys = {
		{
			"<A-c>",
			function()
				require("toggle-checkbox").toggle()
			end,
			desc = "Markdown: toggle checkbox",
		},
	},
	opts = {
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
	},
}
