return {
	"MeanderingProgrammer/render-markdown.nvim",
	ft = "markdown",
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"nvim-mini/mini.nvim",
		"opdavies/toggle-checkbox.nvim",
	},
	keys = {
		{
			"<leader>vr",
			"<cmd>RenderMarkdown toggle<CR>",
			desc = "Markdown: toggle rendering",
		},
		{
			"<leader>vp",
			"<cmd>RenderMarkdown preview<CR>",
			desc = "Markdown: side-by-side preview",
		},
		{
			"<A-c>",
			function()
				require("toggle-checkbox").toggle()
			end,
			desc = "Markdown: toggle checkbox",
		},
	},
	opts = {
		completions = { lsp = { enabled = true } },
		heading = {
			sign = false,
			width = "block",
			left_pad = 1,
			right_pad = 2,
			icons = { "▌ ", "▎ ", "▪ ", "• ", "◦ ", "· " },
		},
		code = {
			width = "block",
			border = "thin",
			left_pad = 2,
			right_pad = 2,
		},
		checkbox = {
			unchecked = { icon = "☐ " },
			checked = { icon = "☑ " },
		},
	},
}
