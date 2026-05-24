return {
	{
		"ThePrimeagen/harpoon",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			require("harpoon").setup({
				tabline = {
					enabled = true,
					show_icons = true,
				},
			})

			vim.cmd("highlight! HarpoonInactive guibg=NONE guifg=#63698c")
			vim.cmd("highlight! HarpoonActive guibg=NONE guifg=white")
			vim.cmd("highlight! HarpoonNumberActive guibg=NONE guifg=#7aa2f7")
			vim.cmd("highlight! HarpoonNumberInactive guibg=NONE guifg=#7aa2f7")
			vim.cmd("highlight! TabLineFill guibg=NONE guifg=white")
		end,
		keys = {
			{ "<leader>ma", function() require("harpoon.mark").add_file() end, desc = "Harpoon: add file" },
			{ "<leader>mm", function() require("harpoon.ui").toggle_quick_menu() end, desc = "Harpoon: menu" },
			{ "<M-h>", function() require("harpoon.ui").nav_file(1) end, desc = "Harpoon: file 1" },
			{ "<M-t>", function() require("harpoon.ui").nav_file(2) end, desc = "Harpoon: file 2" },
			{ "<M-n>", function() require("harpoon.ui").nav_file(3) end, desc = "Harpoon: file 3" },
			{ "<M-s>", function() require("harpoon.ui").nav_file(4) end, desc = "Harpoon: file 4" },
		},
	},
}
