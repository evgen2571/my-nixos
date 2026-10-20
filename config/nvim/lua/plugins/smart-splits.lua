return {
	"mrjones2014/smart-splits.nvim",
	opts = {},

	keys = {
		{ "<leader>rh", function() require("smart-splits").resize_left() end, desc = "Resize split left" },
		{ "<leader>rj", function() require("smart-splits").resize_down() end, desc = "Resize split down" },
		{ "<leader>rk", function() require("smart-splits").resize_up() end, desc = "Resize split up" },
		{ "<leader>rl", function() require("smart-splits").resize_right() end, desc = "Resize split right" },
		{ "<C-h>", function() require("smart-splits").move_cursor_left() end, desc = "Focus left split" },
		{ "<C-j>", function() require("smart-splits").move_cursor_down() end, desc = "Focus lower split" },
		{ "<C-k>", function() require("smart-splits").move_cursor_up() end, desc = "Focus upper split" },
		{ "<C-l>", function() require("smart-splits").move_cursor_right() end, desc = "Focus right split" },
		{ "<C-\\>", function() require("smart-splits").move_cursor_previous() end, desc = "Focus previous split" },
		{ "<leader><leader>h", function() require("smart-splits").swap_buf_left() end, desc = "Swap buffer left" },
		{ "<leader><leader>j", function() require("smart-splits").swap_buf_down() end, desc = "Swap buffer down" },
		{ "<leader><leader>k", function() require("smart-splits").swap_buf_up() end, desc = "Swap buffer up" },
		{ "<leader><leader>l", function() require("smart-splits").swap_buf_right() end, desc = "Swap buffer right" },
	},
}
