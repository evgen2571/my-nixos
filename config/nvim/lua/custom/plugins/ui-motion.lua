return {
	{
		"nvim-mini/mini.animate",
		event = "VeryLazy",
		config = function()
			local animate = require("mini.animate")

			animate.setup({
				-- neoscroll.nvim owns scrolling; keep mini.animate for the parts
				-- neoscroll does not cover.
				scroll = { enable = false },

				cursor = {
					enable = true,
					timing = animate.gen_timing.linear({ duration = 90, unit = "total" }),
					path = animate.gen_path.line({
						predicate = function(destination)
							local line_distance = math.abs(destination[1])
							return line_distance > 1 and line_distance < 80
						end,
					}),
				},

				resize = {
					timing = animate.gen_timing.linear({ duration = 120, unit = "total" }),
				},

				open = {
					timing = animate.gen_timing.linear({ duration = 120, unit = "total" }),
					winconfig = animate.gen_winconfig.wipe({ direction = "from_edge" }),
					winblend = animate.gen_winblend.linear({ from = 70, to = 100 }),
				},

				close = {
					timing = animate.gen_timing.linear({ duration = 100, unit = "total" }),
					winconfig = animate.gen_winconfig.wipe({ direction = "to_edge" }),
					winblend = animate.gen_winblend.linear({ from = 70, to = 100 }),
				},
			})
		end,
	},

	{
		"karb94/neoscroll.nvim",
		event = "VeryLazy",
		opts = {
			mappings = { "<C-u>", "<C-d>", "<C-b>", "<C-f>", "<C-y>", "<C-e>", "zt", "zz", "zb" },
			hide_cursor = true,
			stop_eof = true,
			respect_scrolloff = true,
			cursor_scrolls_alone = false,
			duration_multiplier = 0.85,
			easing = "quadratic",
			performance_mode = false,
		},
	},
}
