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

		end,
		keys = {
			{
				"<leader>a",
				function()
					require("harpoon.mark").add_file()
				end,
				desc = "Harpoon: add file",
			},
			{
				"<leader>e",
				function()
					require("harpoon.ui").toggle_quick_menu()
				end,
				desc = "Harpoon: menu",
			},
			{
				"<M-a>",
				function()
					require("harpoon.ui").nav_file(1)
				end,
				desc = "Harpoon: file 1",
			},
			{
				"<M-s>",
				function()
					require("harpoon.ui").nav_file(2)
				end,
				desc = "Harpoon: file 2",
			},
			{
				"<M-d>",
				function()
					require("harpoon.ui").nav_file(3)
				end,
				desc = "Harpoon: file 3",
			},
			{
				"<M-f>",
				function()
					require("harpoon.ui").nav_file(4)
				end,
				desc = "Harpoon: file 4",
			},
		},
	},
}

