return {
	"esmuellert/codediff.nvim",
	cmd = "CodeDiff",

	keys = {
		{ "<leader>gd", "<cmd>CodeDiff<CR>", desc = "Git diff" },
	},

	opts = {
		diff = {
			layout = "side-by-side",
			disable_inlay_hints = true,
			max_computation_time_ms = 5000,
			original_position = "left",
			jump_to_first_change = true,
		},

		explorer = {
			position = "left",
			width = 40,
			initial_focus = "explorer",
			view_mode = "list",
			flatten_dirs = true,
			file_filter = { ignore = { ".git/**", ".jj/**" } },

			visible_groups = {
				staged = true,
				unstaged = true,
				conflicts = true,
			},
		},

		history = {
			position = "bottom",
			height = 15,
			initial_focus = "history",
			view_mode = "list",
		},

		keymaps = {
			view = {
				quit = "q",
				toggle_explorer = "<leader>gdb",
				focus_explorer = "<leader>gde",
				next_hunk = "]c",
				prev_hunk = "[c",
				next_file = "]f",
				prev_file = "[f",
				diff_get = "do",
				diff_put = "dp",
				open_in_prev_tab = "gf",
				toggle_stage = "-",
				stage_hunk = "<leader>hs",
				unstage_hunk = "<leader>hu",
				discard_hunk = "<leader>hr",
				hunk_textobject = "ih",
				show_help = "g?",
				toggle_layout = "t",
			},

			explorer = {
				select = "<CR>",
				hover = "K",
				refresh = "R",
				toggle_view_mode = "i",
				stage_all = "S",
				unstage_all = "U",
				restore = "X",
				toggle_changes = "gu",
				toggle_staged = "gs",
			},

			history = {
				select = "<CR>",
				toggle_view_mode = "i",
				refresh = "R",
			},

			conflict = {
				accept_incoming = "<leader>gct",
				accept_current = "<leader>gco",
				accept_both = "<leader>gca",
				discard = "<leader>gcx",
				accept_all_incoming = "<leader>gcT",
				accept_all_current = "<leader>gcO",
				accept_all_both = "<leader>gcB",
				discard_all = "<leader>gcX",
				next_conflict = "]x",
				prev_conflict = "[x",
				diffget_incoming = "2do",
				diffget_current = "3do",
			},
		},
	},
}
