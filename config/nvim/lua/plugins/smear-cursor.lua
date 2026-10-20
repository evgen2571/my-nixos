return {
	"sphamba/smear-cursor.nvim",
	event = "VeryLazy",

	cond = function()
		return not vim.g.neovide
	end,

	opts = {
		-- Keep it subtle and readable
		cursor_color = "none",

		-- Avoid duplicate/ghost cursor artifacts
		hide_target_hack = true,
		never_draw_over_target = true,

		-- Smooth, controlled movement
		stiffness = 0.65,
		trailing_stiffness = 0.45,
		stiffness_insert_mode = 0.55,
		trailing_stiffness_insert_mode = 0.45,

		-- Higher damping = less bounce/glitchiness
		damping = 0.92,
		damping_insert_mode = 0.95,

		-- Stop animation sooner to avoid micro-jitter
		distance_stop_animating = 0.35,
		distance_stop_animating_vertical_bar = 0.25,

		-- Do not overdo tiny movements
		min_horizontal_distance_smear = 2,
		min_vertical_distance_smear = 2,

		-- Cursor movement behavior
		smear_between_buffers = false,
		smear_between_neighbor_lines = true,
		scroll_buffer_space = true,

		-- Insert mode tends to look cleaner with less smear
		smear_insert_mode = false,

		-- More stable and less noisy
		time_interval = 17,
		legacy_computing_symbols_support = false,

		-- No particles: beautiful config, not gamer config
		particles_enabled = false,
	},
}
