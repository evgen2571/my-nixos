return {
	"sphamba/smear-cursor.nvim",
	event = "VeryLazy",

	cond = function()
		return not vim.g.neovide
	end,

	opts = {
		cursor_color = "none",

		-- Avoid a second cursor behind the animation.
		hide_target_hack = true,
		never_draw_over_target = true,

		stiffness = 0.65,
		trailing_stiffness = 0.45,
		stiffness_insert_mode = 0.55,
		trailing_stiffness_insert_mode = 0.45,

		damping = 0.92,
		damping_insert_mode = 0.95,

		distance_stop_animating = 0.35,
		distance_stop_animating_vertical_bar = 0.25,

		-- Ignore tiny movements to reduce jitter.
		min_horizontal_distance_smear = 2,
		min_vertical_distance_smear = 2,

		smear_between_buffers = false,
		smear_between_neighbor_lines = true,
		scroll_buffer_space = true,

		smear_insert_mode = false,

		time_interval = 17,
		legacy_computing_symbols_support = false,

		particles_enabled = false,
	},
}
