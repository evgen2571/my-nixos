return {
	{
		"nvim-mini/mini.indentscope",
		version = false,
		event = { "BufReadPre", "BufNewFile" },

		init = function()
			vim.api.nvim_create_autocmd("FileType", {
				pattern = {
					"alpha",
					"dashboard",
					"fzf",
					"help",
					"lazy",
					"mason",
					"neo-tree",
					"notify",
					"snacks_dashboard",
					"snacks_notif",
					"snacks_terminal",
					"toggleterm",
					"Trouble",
					"trouble",
				},
				callback = function()
					vim.b.miniindentscope_disable = true
				end,
			})
		end,

		config = function()
			local indentscope = require("mini.indentscope")

			indentscope.setup({
				symbol = "│",

				draw = {
					delay = 80,

					animation = indentscope.gen_animation.quadratic({
						easing = "out",
						duration = 180,
						unit = "total",
					}),

					priority = 50,
				},

				options = {
					try_as_border = true,
					indent_at_cursor = false,
					n_lines = 500,
				},

				mappings = {
					object_scope = "ii",
					object_scope_with_border = "ai",
					goto_top = "[i",
					goto_bottom = "]i",
				},
			})

			vim.api.nvim_set_hl(0, "MiniIndentscopeSymbol", {
				link = "Comment",
				default = true,
			})
		end,
	},

	-- Disable indent-blankline static scope/indent visuals if installed.
	{
		"lukas-reineke/indent-blankline.nvim",
		optional = true,
		opts = {
			indent = {
				char = "",
			},
			scope = {
				enabled = false,
			},
		},
	},

	-- Disable Snacks indent guides if installed.
	{
		"folke/snacks.nvim",
		optional = true,
		opts = {
			indent = {
				enabled = false,
				scope = {
					enabled = false,
				},
			},
		},
	},
}
